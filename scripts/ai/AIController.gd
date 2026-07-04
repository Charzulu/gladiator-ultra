# scripts/ai/AIController.gd
# Tactical AI opponent for MMA combat.
# Reads fighter state and outputs decisions to the FighterStateMachine.
# Range-aware, style-influenced, stamina-modulated behavior selection.
extends RefCounted

# ── Behavior weights (adjusted per style) ──
var _strike_weight: float = 1.0
var _defense_weight: float = 1.0
var _grapple_weight: float = 1.0
var _aggression: float = 0.5       # 0=passive, 1=aggressive
var _range_preference: float = 1.5  # ideal combat range in meters

# ── Internal state ──
var _decision_cooldown: float = 0.0
var _current_decision: String = "idle"
var _last_strike_time: float = 0.0
var _combo_count: int = 0
var _pattern_index: int = 0
var _retreat_timer: float = 0.0

# ── References ──
var fighter_fsm = null   # FighterStateMachine
var opponent_fsm = null  # FighterStateMachine (opponent)
var fighter_data = null  # FighterData

# ── Strike selection tables per range ──
# Format: { strike_id: weight, ... }
var _far_strikes: Dictionary = {
	"jab": 0.4, "front_kick": 0.3, "leg_kick": 0.2, "roundhouse": 0.1,
}
var _medium_strikes: Dictionary = {
	"jab": 0.3, "cross": 0.25, "hook": 0.15, "roundhouse": 0.15, "leg_kick": 0.1, "uppercut": 0.05,
}
var _close_strikes: Dictionary = {
	"hook": 0.3, "uppercut": 0.2, "knee": 0.15, "cross": 0.2, "elbow": 0.15,
}

# ── Defense weights ──
var _defense_options = ["block", "slip_left", "slip_right", "duck", "retreat"]

# ── Style modifiers ──
var _style_profiles = {
	"boxing": { "strike_weight": 1.3, "grapple_weight": 0.4, "range": 1.2 },
	"muay_thai": { "strike_weight": 1.2, "grapple_weight": 0.7, "range": 1.5 },
	"kickboxing": { "strike_weight": 1.3, "grapple_weight": 0.3, "range": 1.8 },
	"karate": { "strike_weight": 1.2, "grapple_weight": 0.3, "range": 2.0 },
	"wrestling": { "strike_weight": 0.5, "grapple_weight": 1.5, "range": 0.8 },
	"bjj": { "strike_weight": 0.3, "grapple_weight": 1.6, "range": 0.6 },
	"generic_mma": { "strike_weight": 1.0, "grapple_weight": 1.0, "range": 1.3 },
}

# ──────────────────────────────────────────────────────
# INIT
# ──────────────────────────────────────────────────────

func _init(fsm, opp_fsm, fd) -> void:
	fighter_fsm = fsm
	opponent_fsm = opp_fsm
	fighter_data = fd
	_load_style_profile()

func _load_style_profile() -> void:
	"""Load behavior weights from the fighter's primary style."""
	if not fighter_data:
		return
	var style = fighter_data.primary_style
	var profile = _style_profiles.get(style, _style_profiles["generic_mma"])
	_strike_weight = profile.strike_weight
	_grapple_weight = profile.grapple_weight
	_range_preference = profile.range
	_aggression = 0.3 + (fighter_data.get_d("aggression", 50.0) / 100.0)

# ──────────────────────────────────────────────────────
# MAIN TICK
# ──────────────────────────────────────────────────────

func tick(delta: float, range_to_opponent: float) -> Dictionary:
	"""Called every tick. Returns an action dict for the FSM.
	
	Return format: { action: String, params: Dictionary }
	Possible actions: "strike", "block", "slip", "duck", "lunge", 
	                 "retreat", "clinch", "takedown", "idle"
	"""
	# If stunned/KO'd, no action
	if fighter_fsm.is_knocked_out or fighter_fsm.is_stunned:
		return { "action": "idle", "params": {} }
	
	# Cooldown
	if _decision_cooldown > 0.0:
		_decision_cooldown -= delta
		if _current_decision == "block":
			return { "action": "block", "params": {} }
		return { "action": "idle", "params": {} }
	
	# Check if opponent is attacking (simplified: just check their state)
	var opponent_is_attacking = _detect_opponent_attack()
	
	# ── DEFENSE FIRST: React to incoming attacks ──
	if opponent_is_attacking and _should_defend():
		_decision_cooldown = 0.15
		var defense = _choose_defense(range_to_opponent)
		_current_decision = defense
		return { "action": defense, "params": {} }
	
	# ── RETREAT when hurt or gassed ──
	if _should_retreat():
		_retreat_timer = 0.5
		_current_decision = "retreat"
		return { "action": "retreat", "params": { "distance": 0.3 } }
	
	if _retreat_timer > 0.0:
		_retreat_timer -= delta
		return { "action": "retreat", "params": { "distance": 0.2 } }
	
	# ── CLINCH/TAKEDOWN when at close range and grapple-skilled ──
	if range_to_opponent < 0.8 and _grapple_weight > 1.0 and randf() < 0.3:
		_decision_cooldown = 0.5
		if randf() < 0.5:
			_current_decision = "clinch"
			return { "action": "clinch", "params": {} }
		else:
			_current_decision = "takedown"
			return { "action": "takedown", "params": { "type": "double_leg" } }
	
	# ── MOVEMENT: manage range ──
	if range_to_opponent > _range_preference * 1.5:
		# Too far — advance
		return { "action": "lunge", "params": { "direction": "forward" } }
	elif range_to_opponent < _range_preference * 0.5 and _strike_weight > _grapple_weight:
		# Too close for a striker — create space
		return { "action": "retreat", "params": { "distance": 0.3 } }
	
	# ── STRIKE SELECTION ──
	_decision_cooldown = _get_strike_cooldown(range_to_opponent)
	var strike = _choose_strike(range_to_opponent)
	_current_decision = "strike"
	
	return {
		"action": "strike",
		"params": {
			"strike_id": strike,
			"target": _choose_target_zone(strike),
			"perfect": randf() < 0.05,  # 5% chance of perfect timing
		}
	}

# ──────────────────────────────────────────────────────
# STRIKE SELECTION
# ──────────────────────────────────────────────────────

func _choose_strike(range_to_opponent: float) -> String:
	"""Pick a strike based on range and style weights."""
	var table: Dictionary
	
	if range_to_opponent > 1.8:
		table = _far_strikes
	elif range_to_opponent > 1.0:
		table = _medium_strikes
	else:
		table = _close_strikes
	
	# Adjust weights by the fighter's skill
	var adjusted = {}
	for strike_id in table:
		var weight = table[strike_id]
		# Boost strikes the fighter is skilled in
		var skill = _get_skill_for_strike(strike_id)
		var skill_mod = 0.5 + (skill / 200.0)
		adjusted[strike_id] = weight * skill_mod
	
	return _weighted_random(adjusted)

func _get_skill_for_strike(strike_id: String) -> float:
	"""Get the relevant skill for a strike type."""
	if not fighter_data:
		return 50.0
	match strike_id:
		"jab", "cross", "hook", "uppercut":
			return fighter_data.boxing
		"roundhouse", "front_kick", "leg_kick":
			return fighter_data.kickboxing
		"knee", "elbow":
			return fighter_data.muay_thai
	return 50.0

func _choose_target_zone(strike_id: String) -> String:
	"""Pick head or body target."""
	# Kicks more likely to target body/legs
	if strike_id in ["leg_kick"]:
		return "left_leg"
	if strike_id in ["roundhouse", "front_kick"]:
		return "body" if randf() < 0.5 else "head"
	if strike_id in ["knee"]:
		return "body"
	# Head strikes
	if randf() < 0.6:
		return "head"
	return "body"

func _get_strike_cooldown(range_to_opponent: float) -> float:
	"""How long before AI picks another action (simulates recovery frames)."""
	# Faster at close range, slower at far range (jabs vs roundhouses)
	if range_to_opponent > 1.8:
		return 0.4 + randf_range(-0.1, 0.1)
	elif range_to_opponent > 1.0:
		return 0.3 + randf_range(-0.1, 0.1)
	return 0.2 + randf_range(-0.1, 0.1)

# ──────────────────────────────────────────────────────
# DEFENSE
# ──────────────────────────────────────────────────────

func _should_defend() -> bool:
	"""Determine if AI should defend based on opponent state."""
	if not opponent_fsm:
		return false
	# Defend when:
	# 1. Opponent is not stunned (can attack)
	# 2. AI's guard is up
	# 3. Random chance (defense awareness)
	var base_chance = 0.3 + (fighter_data.get_skill("head_movement") / 200.0)
	return randf() < base_chance and not opponent_fsm.is_stunned

func _choose_defense(range_to_opponent: float) -> String:
	"""Choose a defensive action."""
	# Block at range, slip/duck at close range
	if range_to_opponent > 1.5 or fighter_data.is_gassed():
		return "block"
	
	# Head movement against head strikes
	var roll = randf()
	if roll < 0.4:
		return "slip_left"
	elif roll < 0.7:
		return "slip_right"
	elif roll < 0.9:
		return "duck"
	return "block"

# ──────────────────────────────────────────────────────
# TACTICAL EVALUATION
# ──────────────────────────────────────────────────────

func _should_retreat() -> bool:
	"""Retreat when in danger."""
	if not fighter_data:
		return false
	# Retreat when health is low or stamina is very low
	var health_pct = 1.0
	if fighter_data.health_pools:
		var total_max = 0.0; var total_current = 0.0
		for zone in fighter_data.health_pools:
			total_max += fighter_data.derived.get("max_%s_health" % zone, 100.0)
			total_current += fighter_data.get_health(zone)
		health_pct = total_current / max(total_max, 1.0)
	
	return health_pct < 0.3 or (fighter_data.is_gassed() and fighter_data.stamina_state.current < 20.0)

func _detect_opponent_attack() -> bool:
	"""Detect if opponent is in an attacking state."""
	if not opponent_fsm:
		return false
	return opponent_fsm._attack_cooldown > 0.1

# ──────────────────────────────────────────────────────
# UTILITY
# ──────────────────────────────────────────────────────

func _weighted_random(weights: Dictionary) -> String:
	"""Pick a key from a dictionary of string->float weights."""
	var total = 0.0
	for k in weights:
		total += weights[k]
	if total <= 0.0:
		return ""
	var roll = randf() * total
	var accum = 0.0
	for k in weights:
		accum += weights[k]
		if roll < accum:
			return k
	return ""

func get_aggression_level() -> float:
	"""Return current aggression (0-1), modulated by stamina."""
	if not fighter_data:
		return _aggression
	var stam_mod = 1.0
	if fighter_data.is_gassed():
		stam_mod = 0.4
	return _aggression * stam_mod

func set_aggression(level: float) -> void:
	_aggression = clampf(level, 0.0, 1.0)
