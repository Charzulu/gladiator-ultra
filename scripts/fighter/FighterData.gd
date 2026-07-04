# scripts/fighter/FighterData.gd
# Data-driven fighter definition. Extends Resource for serialization (.tres).
# Contains ALL attributes: core stats, combat skills, health, stamina, style,
# plus progression: strike_xp, prestige, variants, challenges.
extends Resource

const _VarDB = preload("res://scripts/progression/MoveVariantDatabase.gd")
const _ChallengeDB = preload("res://scripts/progression/MoveChallengeDatabase.gd")

# ──────────────────────────────────
# 1. IDENTITY
# ──────────────────────────────────
@export var fighter_name: String = "Unnamed"
@export var nickname: String = ""
@export var weight_class: int = 0
@export var nationality: String = "USA"
@export var age: int = 25
@export var reach_inches: float = 72.0
@export var height_ft: int = 5
@export var height_in: int = 10
@export var stance: int = 0

@export var record_wins: int = 0
@export var record_losses: int = 0
@export var record_draws: int = 0
@export var record_kos: int = 0
@export var record_subs: int = 0
@export var record_decisions: int = 0

# ──────────────────────────────────
# 2. CORE STATS
# ──────────────────────────────────
@export_range(0.0, 100.0) var strength: float = 50.0
@export_range(0.0, 100.0) var speed: float = 50.0
@export_range(0.0, 100.0) var endurance: float = 50.0
@export_range(0.0, 100.0) var toughness: float = 50.0

# ──────────────────────────────────
# 3. COMBAT SKILLS
# ──────────────────────────────────
@export_range(0.0, 100.0) var boxing: float = 50.0
@export_range(0.0, 100.0) var kickboxing: float = 50.0
@export_range(0.0, 100.0) var muay_thai: float = 50.0
@export_range(0.0, 100.0) var head_movement: float = 50.0
@export_range(0.0, 100.0) var footwork: float = 50.0
@export_range(0.0, 100.0) var clinch_offense: float = 50.0
@export_range(0.0, 100.0) var clinch_defense: float = 50.0
@export_range(0.0, 100.0) var clinch_takedown: float = 50.0
@export_range(0.0, 100.0) var td_offense: float = 50.0
@export_range(0.0, 100.0) var td_defense: float = 50.0
@export_range(0.0, 100.0) var counter_td: float = 50.0
@export_range(0.0, 100.0) var cage_wrestling: float = 50.0
@export_range(0.0, 100.0) var top_control: float = 50.0
@export_range(0.0, 100.0) var bottom_control: float = 50.0
@export_range(0.0, 100.0) var guard_pass: float = 50.0
@export_range(0.0, 100.0) var guard_retention: float = 50.0
@export_range(0.0, 100.0) var sub_offense: float = 50.0
@export_range(0.0, 100.0) var sub_defense: float = 50.0
@export_range(0.0, 100.0) var sub_awareness: float = 50.0

# ──────────────────────────────────
# 4. HEALTH PROFILE
# ──────────────────────────────────
@export_range(0.0, 100.0) var chin: float = 50.0
@export_range(0.0, 100.0) var cut_resistance: float = 50.0
@export_range(0.0, 100.0) var swell_resistance: float = 50.0
@export_range(0.0, 100.0) var bleed_resistance: float = 50.0
@export_range(0.0, 100.0) var limb_health: float = 50.0
@export_range(0.0, 100.0) var injury_recovery: float = 50.0

# ──────────────────────────────────
# 5. STAMINA PROFILE
# ──────────────────────────────────
@export_range(0.0, 100.0) var max_stamina_rating: float = 50.0
@export_range(0.0, 100.0) var drain_rate_rating: float = 50.0
@export_range(0.0, 100.0) var recovery_rate_rating: float = 50.0
@export_range(0.0, 100.0) var gassed_threshold_rating: float = 50.0
@export_range(0.0, 100.0) var cardio_drop_rating: float = 50.0

# ──────────────────────────────────
# 6. STYLE
# ──────────────────────────────────
@export var primary_style: String = "generic_mma"

# ──────────────────────────────────
# 7. DERIVED VALUES
# ──────────────────────────────────
var derived: Dictionary = {}
var health_pools: Dictionary = {}
var stamina_state: Dictionary = { "current": 100.0, "is_gassed": false }

# ──────────────────────────────────
# 8. PROGRESSION (XP, PRESTIGE, VARIANTS, CHALLENGES)
# ──────────────────────────────────
var strike_xp: Dictionary = {}          # { "jab": 450, "cross": 600, ... }
var strike_prestige: Dictionary = {}    # { "jab": 2, "cross": 3, ... }
var owned_variants: Array = ["standard_generic"]
var equipped_variants: Dictionary = {}  # { "jab": "jab_snap_boxing", ... }
var challenge_progress: Dictionary = {} # { "jab_3_consecutive_prog": { "progress": 3, ... } }

# ──────────────────────────────────
# INITIALIZATION
# ──────────────────────────────────

func _init() -> void:
	build_stats()

func build_stats() -> void:
	_apply_style_modifiers()
	_compute_derived()
	reset_health()
	reset_stamina()
	_init_variants()

func _init_variants() -> void:
	# Auto-equip standard_generic for any strike missing a variant
	var all_move_ids = ["jab", "cross", "hook", "uppercut", "front_kick", "roundhouse",
		"leg_kick", "head_kick", "knee", "elbow"]
	for mid in all_move_ids:
		if not equipped_variants.has(mid):
			equipped_variants[mid] = "standard_generic"

# ── Skill access ──
func get_skill(name: String) -> float:
	if name in self:
		return get(name) as float
	return 50.0

func get_d(key: String, default = 0.0):
	return derived.get(key, default)

# ──────────────────────────────────
# HEALTH POOLS
# ──────────────────────────────────
func get_health(zone: String) -> float: return health_pools.get(zone, 100.0)
func get_health_pct(zone: String) -> float:
	var max_hp = _max_hp_for_zone(zone)
	return health_pools.get(zone, 0.0) / max_hp if max_hp > 0 else 0.0

func apply_damage(zone: String, amount: float) -> void:
	if health_pools.has(zone): health_pools[zone] = max(0.0, health_pools[zone] - amount)

func reset_health() -> void:
	var d = derived
	health_pools = {
		"head": 100.0 + (chin * 0.5), "torso": 100.0 + (toughness * 1.0),
		"left_arm": d.limb_hp, "right_arm": d.limb_hp,
		"left_leg": d.limb_hp_leg, "right_leg": d.limb_hp_leg,
	}

func heal_between_rounds() -> void:
	for zone in health_pools.keys():
		var max_hp = _max_hp_for_zone(zone)
		var current = health_pools[zone]
		var missing = max_hp - current
		health_pools[zone] = min(max_hp, current + missing * derived.recovery_mult)

func _max_hp_for_zone(zone: String) -> float:
	match zone:
		"head": return 100.0 + (chin * 0.5)
		"torso": return 100.0 + (toughness * 1.0)
		"left_arm", "right_arm": return derived.limb_hp
		"left_leg", "right_leg": return derived.limb_hp_leg
	return 100.0

func get_limb_status(limb: String) -> Dictionary:
	var hp = health_pools.get(limb, 100.0)
	var max_hp = _max_hp_for_zone(limb)
	var pct = hp / max_hp if max_hp > 0 else 0.0
	return {
		"effective": pct, "is_compromised": pct < 0.5, "is_destroyed": hp <= 0.0,
		"power_mult": 1.0 if pct >= 0.5 else (0.3 + pct * 0.4),
		"speed_mult": 1.0 if pct >= 0.3 else (0.4 + pct * 0.5),
	}

# ──────────────────────────────────
# STAMINA
# ──────────────────────────────────
func reset_stamina() -> void:
	var max_s = derived.get("max_stamina", 100.0)
	stamina_state = { "current": max_s, "is_gassed": false }

func get_stamina() -> float: return stamina_state.get("current", 100.0)
func get_stamina_pct() -> float:
	var max_s = derived.get("max_stamina", 100.0)
	return stamina_state.get("current", 0.0) / max_s if max_s > 0 else 0.0

func spend_stamina(amount: float) -> void:
	stamina_state["current"] = max(0.0, stamina_state["current"] - amount * derived.get("stamina_drain", 1.0))
	_check_gassed()

func recover_stamina(delta: float) -> void:
	var max_s = derived.get("max_stamina", 100.0)
	stamina_state["current"] = min(max_s, stamina_state["current"] + derived.get("stamina_recovery", 4.0) * delta)
	var threshold_pct = derived.get("gassed_pct", 0.25)
	if stamina_state["current"] > (max_s * threshold_pct): stamina_state["is_gassed"] = false

func is_gassed() -> bool: return stamina_state.get("is_gassed", false)
func _check_gassed() -> void:
	var max_s = derived.get("max_stamina", 100.0)
	if stamina_state["current"] <= (max_s * derived.get("gassed_pct", 0.25)): stamina_state["is_gassed"] = true

# ──────────────────────────────────
# PROGRESSION METHODS
# ──────────────────────────────────

# ── XP ──
func add_strike_xp(strike_id: String, amount: int) -> void:
	var current = strike_xp.get(strike_id, 0)
	strike_xp[strike_id] = current + amount

func get_strike_level(strike_id: String) -> int:
	var xp = strike_xp.get(strike_id, 0)
	if xp >= 1000: return 5
	if xp >= 600:  return 4
	if xp >= 300:  return 3
	if xp >= 100:  return 2
	return 1

func get_strike_level_name(strike_id: String) -> String:
	match get_strike_level(strike_id):
		1: return "Novice"
		2: return "Proficient"
		3: return "Skilled"
		4: return "Expert"
		5: return "Master"
		_: return "Novice"

# ── PRESTIGE ──
func prestige_strike(strike_id: String) -> bool:
	if get_strike_level(strike_id) < 5: return false
	strike_xp[strike_id] = 0
	strike_prestige[strike_id] = strike_prestige.get(strike_id, 0) + 1
	return true

func get_strike_prestige_modifier(strike_id: String) -> Dictionary:
	var prestige = strike_prestige.get(strike_id, 0)
	var mods = { "damage": 0.0, "stamina": 0.0, "hit_chance": 0.0, "startup": 0.0, "recovery": 0.0 }
	for i in range(1, prestige + 1):
		var cycle = (i - 1) % 5
		var tier = floori((i - 1) / 5) + 1
		match cycle:
			0: mods["damage"] += 0.02 + (tier * 0.01)
			1: mods["stamina"] -= 0.02 - (tier * 0.005)
			2: mods["hit_chance"] += 0.015 + (tier * 0.005)
			3: mods["damage"] += 0.02 + (tier * 0.01)
			4: mods["recovery"] -= 0.015 + (tier * 0.005)
	return mods

# ── VARIANTS ──
func purchase_variant(strike_id: String, variant_id: String) -> bool:
	var v = _VarDB.get_variant(variant_id)
	if not v: return false
	if variant_id in owned_variants: return false
	if v.base_move_id != strike_id and v.base_move_id != "": return false
	
	if get_strike_level(strike_id) < v.level_required: return false
	for req_stat in v.requirements:
		var val = get(req_stat) if req_stat in self else 0.0
		if val < v.requirements[req_stat]: return false
	
	var pool = strike_xp.get(strike_id, 0)
	if pool < v.xp_cost: return false
	
	strike_xp[strike_id] = pool - v.xp_cost
	owned_variants.append(variant_id)
	return true

func equip_variant(strike_id: String, variant_id: String) -> bool:
	if variant_id not in owned_variants: return false
	equipped_variants[strike_id] = variant_id
	return true

func get_equipped_variant(strike_id: String):
	var vid = equipped_variants.get(strike_id, "standard_generic")
	return _VarDB.get_variant(vid)

func get_owned_variants_for_move(move_id: String) -> Array:
	var result: Array = []
	for vid in owned_variants:
		var v = _VarDB.get_variant(vid)
		if v and v.base_move_id == move_id:
			result.append(v)
	return result

# ── CHALLENGES ──
func report_combat_event(event_type: String, move_id: String, value: int = 1, is_counter: bool = false) -> void:
	var completed = _ChallengeDB.check_and_award(self, event_type, move_id, value, is_counter)
	for challenge in completed:
		# Award XP to the target move
		if challenge.target_move and challenge.target_move != "":
			add_strike_xp(challenge.target_move, challenge.xp_reward)

func reset_fight_challenges() -> void:
	_ChallengeDB.reset_fight_challenges(self)

# ──────────────────────────────────
# DERIVED STAT COMPUTATION
# ──────────────────────────────────
func _compute_derived() -> void:
	derived = {
		"punch_base_dmg": 5.0 + (strength * 0.12), "kick_base_dmg": 8.0 + (strength * 0.10),
		"takedown_power": 0.4 + (strength * 0.006), "clinch_push": 0.3 + (strength * 0.005),
		"gnp_damage_mult": 0.5 + (strength * 0.005),
		"strike_speed_mult": 1.8 - (speed * 0.012), "move_speed_mult": 0.6 + (speed * 0.009),
		"reaction_frames": 15.0 - (speed * 0.14), "combo_window": 0.3 + (speed * 0.005),
		"accuracy_bonus": 0.8 + (speed * 0.002),
		"max_stamina": 100.0 + (endurance * 0.5), "stamina_drain": 1.6 - (endurance * 0.011),
		"stamina_recovery": 1.0 + (endurance * 0.09), "gassed_pct": 0.35 - (endurance * 0.0025),
		"cardio_drop_round": 5 - int(endurance * 0.04),
		"dmg_taken_mult": 1.5 - (toughness * 0.01), "ko_threshold": 30.0 + (toughness * 0.7),
		"limb_hp": 50.0 + (toughness * 0.8), "limb_hp_leg": (50.0 + (toughness * 0.8)) * 1.2,
		"recovery_mult": 0.3 + (toughness * 0.005), "heal_base": 0.2,
		"stamina_pool_mult": 0.6 + (max_stamina_rating * 0.009),
		"drain_mult": 1.5 - (drain_rate_rating * 0.009),
		"recov_per_sec": 1.0 + (recovery_rate_rating * 0.09),
		"gassed_at_pct": 0.35 - (gassed_threshold_rating * 0.0025),
		"drop_round": 2 + int(cardio_drop_rating * 0.03),
	}

# ──────────────────────────────────
# STYLE MODIFIERS
# ──────────────────────────────────
func _apply_style_modifiers() -> void:
	var mods = _STYLE_MODIFIERS.get(primary_style, {})
	for skill_name in mods.get("bonus", {}):
		var v = get(skill_name) if skill_name in self else 50.0
		set(skill_name, clampf(v + mods["bonus"][skill_name], 0.0, 100.0))
	for skill_name in mods.get("penalty", {}):
		var v = get(skill_name) if skill_name in self else 50.0
		set(skill_name, clampf(v + mods["penalty"][skill_name], 0.0, 100.0))

const _STYLE_MODIFIERS: Dictionary = {
	"boxing": { "bonus": {"boxing": 12, "head_movement": 8, "footwork": 5}, "penalty": {"kickboxing": -8, "clinch_offense": -5, "clinch_defense": -3, "sub_offense": -5} },
	"muay_thai": { "bonus": {"muay_thai": 12, "clinch_offense": 10, "clinch_defense": 5}, "penalty": {"footwork": -5, "td_defense": -8, "sub_defense": -5} },
	"wrestling": { "bonus": {"td_offense": 15, "td_defense": 15, "top_control": 12, "cage_wrestling": 10}, "penalty": {"kickboxing": -8, "sub_offense": -8, "sub_awareness": -5} },
	"bjj": { "bonus": {"sub_offense": 15, "sub_defense": 12, "guard_retention": 10, "bottom_control": 10}, "penalty": {"boxing": -10, "td_offense": -10, "kickboxing": -8} },
	"kickboxing": { "bonus": {"kickboxing": 15, "footwork": 10, "muay_thai": 5}, "penalty": {"clinch_offense": -8, "td_defense": -8, "clinch_defense": -5} },
	"sambo": { "bonus": {"td_offense": 8, "td_defense": 8, "sub_offense": 8, "clinch_takedown": 8, "counter_td": 8}, "penalty": {"boxing": -3, "kickboxing": -3} },
	"judo": { "bonus": {"clinch_takedown": 15, "clinch_offense": 12, "top_control": 8, "sub_offense": 5}, "penalty": {"kickboxing": -8, "head_movement": -5, "boxing": -3} },
	"karate": { "bonus": {"kickboxing": 12, "footwork": 15, "head_movement": 8}, "penalty": {"clinch_offense": -10, "sub_defense": -5, "td_defense": -5} },
	"taekwondo": { "bonus": {"kickboxing": 15, "footwork": 10, "sub_awareness": 3}, "penalty": {"boxing": -10, "clinch_offense": -10, "td_defense": -10} },
	"catch_wrestling": { "bonus": {"td_defense": 12, "top_control": 10, "sub_offense": 10, "sub_defense": 5}, "penalty": {"boxing": -5, "kickboxing": -5} },
	"hapkido": { "bonus": {"counter_td": 12, "clinch_defense": 10, "sub_awareness": 10}, "penalty": {"boxing": -8, "top_control": -5, "td_offense": -5} },
	"generic_mma": { "bonus": {"boxing": 2, "kickboxing": 2, "muay_thai": 2, "head_movement": 2, "footwork": 2, "clinch_offense": 2, "clinch_defense": 2, "clinch_takedown": 2, "td_offense": 2, "td_defense": 2, "counter_td": 2, "cage_wrestling": 2, "top_control": 2, "bottom_control": 2, "guard_pass": 2, "guard_retention": 2, "sub_offense": 2, "sub_defense": 2, "sub_awareness": 2}, "penalty": {} },
}
