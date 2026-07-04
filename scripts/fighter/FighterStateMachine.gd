# scripts/fighter/FighterStateMachine.gd
# The core fight FSM — manages all combat states and transitions.
# Routes inputs via ControlMap, resolves combat via ImpactCalculator.
# Each fighter instance owns one of these.
extends RefCounted

const _ImpactCalc = preload("res://scripts/combat/ImpactCalculator.gd")
const _InputBuffer = preload("res://scripts/control/InputBuffer.gd")

# ── XP weight per strike type ──
const _XP_WEIGHT: Dictionary = {
	0: 1.0, 1: 1.2, 2: 1.4, 3: 1.6, 4: 1.5,
	5: 1.3, 6: 1.0, 7: 2.0, 8: 1.8, 9: 2.0,
}

# ── Map strike type int → string id ──
static func _strike_id_from_type(st: int) -> String:
	match st:
		0: return "jab"
		1: return "cross"
		2: return "hook"
		3: return "uppercut"
		4: return "roundhouse"
		5: return "front_kick"
		6: return "leg_kick"
		7: return "head_kick"
		8: return "knee"
		9: return "elbow"
		_: return "jab"

signal state_changed(old_state: int, new_state: int)
signal strike_landed(hit_result)
signal takedown_attempted(success: bool)
signal grapple_transitioned(from_pos: int, to_pos: int)
signal sub_attempted(locked: bool)
signal fighter_stunned(level: int)
signal fighter_ko()

# ── Owner reference ──
var fighter_data  # FighterData
var opponent_state = null  # FighterStateMachine (type ref removed for --script compat)

# ── Current state ──
var current_state: int = CombatGlobals.FightState.STAND_UP
var previous_state: int = CombatGlobals.FightState.STAND_UP

# ── Position tracking ──
var ground_position: int = CombatGlobals.GroundPosition.OPEN_GUARD

# ── Sub-state timers ──
var stun_timer: float = 0.0
var stun_level: int = 0
var knockdown_timer: float = 0.0
var submission_bar: float = 0.0  # 0-100, attacker fills to 100
var sub_escape_bar: float = 0.0  # defender fills to 100 to escape

# ── KO state ──
var is_knocked_out: bool = false
var is_stunned: bool = false

# ── Block state ──
var is_blocking: bool = false
var block_stamina: float = 100.0

# ── Input buffer ──
var input_buffer = _InputBuffer.new()

# ── Combat modifiers ──
var _attack_cooldown: float = 0.0
var _combo_count: int = 0
var _range_to_opponent: float = 2.0

# ────────────────────────────────────────────
# INITIALIZATION
# ────────────────────────────────────────────

func _init(fd) -> void:
	fighter_data = fd
	_reset_state()

func _reset_state() -> void:
	current_state = CombatGlobals.FightState.STAND_UP
	ground_position = CombatGlobals.GroundPosition.OPEN_GUARD
	stun_timer = 0.0; stun_level = 0
	submission_bar = 0.0; sub_escape_bar = 0.0
	is_knocked_out = false; is_stunned = false
	is_blocking = false
	_attack_cooldown = 0.0
	_combo_count = 0

# ────────────────────────────────────────────
# MAIN UPDATE LOOP
# ────────────────────────────────────────────

func update(delta: float) -> void:
	if is_knocked_out:
		return

	# Cooldowns
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta

	# Stun recovery
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
			stun_level = 0

	# Stamina recovery (passive, only if not gassed)
	if not fighter_data.is_gassed():
		fighter_data.recover_stamina(delta)

	# Knockdown timer
	if knockdown_timer > 0.0:
		knockdown_timer -= delta
		if knockdown_timer <= 0.0:
			# Fighter gets back to stand-up
			_transition_to(CombatGlobals.FightState.STAND_UP)

	# Input processing by state
	match current_state:
		CombatGlobals.FightState.STAND_UP:
			_update_stand_up(delta)
		CombatGlobals.FightState.CLINCH:
			_update_clinch(delta)
		CombatGlobals.FightState.GROUND_TOP:
			_update_ground_top(delta)
		CombatGlobals.FightState.GROUND_BOTTOM:
			_update_ground_bottom(delta)
		CombatGlobals.FightState.SUBMISSION_TOP:
			_update_submission(delta, true)
		CombatGlobals.FightState.SUBMISSION_BOTTOM:
			_update_submission(delta, false)

# ────────────────────────────────────────────
# STATE-SPECIFIC UPDATE
# ────────────────────────────────────────────

# Process incoming actions from ControlMap
func process_action(action_name: String, action_data: Dictionary) -> void:
	if is_knocked_out or is_stunned:
		return

	# Buffer the action
	input_buffer.push(action_name, action_data)

	match current_state:
		CombatGlobals.FightState.STAND_UP:
			_handle_stand_up_action(action_name, action_data)
		CombatGlobals.FightState.CLINCH:
			_handle_clinch_action(action_name, action_data)
		CombatGlobals.FightState.GROUND_TOP:
			_handle_ground_top_action(action_name, action_data)
		CombatGlobals.FightState.GROUND_BOTTOM:
			_handle_ground_bottom_action(action_name, action_data)
		CombatGlobals.FightState.SUBMISSION_TOP:
			_handle_submission_action(action_name, action_data, true)
		CombatGlobals.FightState.SUBMISSION_BOTTOM:
			_handle_submission_action(action_name, action_data, false)

# ────────────────────────────────────────────
# STAND-UP COMBAT
# ────────────────────────────────────────────

func _update_stand_up(delta: float) -> void:
	# Movement speed
	if opponent_state and _range_to_opponent > 0.1:
		var move_speed = fighter_data.get_d("move_speed_mult", 1.0)
		_apply_movement(delta, move_speed)

func _handle_stand_up_action(action_name: String, data: Dictionary) -> void:
	match action_name:
		"strike":
			_perform_strike(data)
		"block_start":
			is_blocking = true
		"clinch_entry":
			_attempt_clinch_entry()
		"takedown_shot":
			_attempt_takedown(data)
		"lunge":
			_apply_lunge(data)
		"slip_up", "duck", "slip_left", "slip_right":
			pass  # Head movement affects hit probability in ImpactCalculator
		"parry":
			_attempt_parry()

func _perform_strike(data: Dictionary) -> void:
	if _attack_cooldown > 0.0:
		return
	if not opponent_state:
		return

	var strike_type = _get_strike_type(data)
	var target_zone = data.get("target", "head")
	var perfect = data.get("perfect", false)

	# Check hit probability
	var defender_head_move = Vector2.ZERO  # Would come from opponent's head movement input
	var hits = _ImpactCalc.check_hit_probability(
		fighter_data, opponent_state.fighter_data,
		strike_type, opponent_state.is_blocking, defender_head_move
	)

	if not hits:
		# Miss — pay stamina, no damage
		_apply_stamina_cost(strike_type)
		_attack_cooldown = 0.15
		return

	# Resolve hit
	var velocity = _calc_strike_velocity(strike_type)
	var result = _ImpactCalc.resolve_strike(
		fighter_data, opponent_state.fighter_data,
		strike_type, target_zone, velocity,
		false, _range_to_opponent, perfect
	)

	# Apply results
	_apply_strike_result(result, strike_type)
	strike_landed.emit(result)

func _apply_strike_result(result, strike_type: int) -> void:
	# Apply damage to opponent
	opponent_state.fighter_data.apply_damage(result.zone, result.mitigated_damage)

	# Apply stamina costs
	_apply_stamina_cost_by_type(result)
	opponent_state.fighter_data.spend_stamina(result.stamina_damage * 0.5)

	# ── XP & Challenge progression ──
	fighter_data.add_strike_xp(_strike_id_from_type(strike_type), int(result.mitigated_damage * _XP_WEIGHT.get(strike_type, 1.0)))
	fighter_data.report_combat_event("strike_landed", _strike_id_from_type(strike_type), int(result.mitigated_damage), result.is_counter)
	if result.stun_level >= 5:
		fighter_data.report_combat_event("ko_with_move", _strike_id_from_type(strike_type), 1)

	# Stun effects
	if result.stun_level > 0:
		opponent_state._apply_stun(result.stun_level, result.stun_duration)

	# Cut
	if result.cut_applied:
		opponent_state._apply_cut(result.cut_depth)

	# Swelling
	if result.swell_amount > 0.0:
		opponent_state._apply_swelling(result.swell_amount)

	# Combo tracking
	_combo_count += 1

func _apply_stamina_cost(strike_type: int) -> void:
	var config = _ImpactCalc.StrikeConfig.new(strike_type)
	fighter_data.spend_stamina(config.stamina_cost)
	_attack_cooldown = (config.startup_frames + config.recovery_frames) / 60.0

func _apply_stamina_cost_by_type(result) -> void:
	fighter_data.spend_stamina(result.stamina_damage)
	_attack_cooldown = 0.2 + (result.stamina_damage * 0.03)

func _apply_stun(level: int, duration: float = 0.0) -> void:
	stun_level = level
	stun_timer = duration if duration > 0.0 else _default_stun_duration(level)
	is_stunned = level >= 1

	if level >= 6:
		# KO
		is_knocked_out = true
		current_state = CombatGlobals.FightState.KO
		fighter_ko.emit()
	elif level == 5:
		# Knockdown
		is_knocked_out = false
		knockdown_timer = stun_timer
		# Transition to ground state
		_transition_to(CombatGlobals.FightState.GROUND_BOTTOM)
		if opponent_state:
			opponent_state._transition_to(CombatGlobals.FightState.GROUND_TOP)

	fighter_stunned.emit(level)

func _default_stun_duration(level: int) -> float:
	match level:
		1: return 0.2
		2: return 0.4
		3: return 1.0
		4: return 1.8
		5: return 3.0
		6: return 999.0  # KO = infinity
		_: return 0.0

func _apply_cut(depth: float) -> void:
	pass  # Handled by the visual / doctor system

func _apply_swelling(amount: float) -> void:
	pass  # Handled by the visual / doctor system

func _attempt_clinch_entry() -> void:
	if not opponent_state: return
	var success_chance = fighter_data.get_skill("clinch_offense") / 100.0
	var defend_chance = opponent_state.fighter_data.get_skill("clinch_defense") / 100.0
	var net = success_chance * 0.6 - defend_chance * 0.4 + 0.3
	if randf() < net:
		_transition_to(CombatGlobals.FightState.CLINCH)
		opponent_state._transition_to(CombatGlobals.FightState.CLINCH)

func _attempt_takedown(data: Dictionary) -> void:
	if not opponent_state: return
	var shot_type = data.get("type", "double_leg")
	var td_skill = fighter_data.get_skill("td_offense") / 100.0
	var td_power = fighter_data.get_d("takedown_power", 1.0)
	var def_skill = opponent_state.fighter_data.get_skill("td_defense") / 100.0
	var success = (td_skill * td_power * 0.7) > (def_skill * 0.5 + randf() * 0.3)

	fighter_data.spend_stamina(8.0)
	opponent_state.fighter_data.spend_stamina(4.0)

	if success:
		_transition_to(CombatGlobals.FightState.GROUND_TOP)
		opponent_state._transition_to(CombatGlobals.FightState.GROUND_BOTTOM)
	else:
		# Takedown stuffed, slight stamina penalty
		_attack_cooldown = 0.5

	takedown_attempted.emit(success)

func _attempt_parry() -> void:
	pass  # Parry logic — opens counter window

func _calc_strike_velocity(strike_type: int) -> Vector3:
	var speed_mult = fighter_data.get_d("strike_speed_mult", 1.0)
	var base_speed = 5.0 + (fighter_data.speed * 0.05)
	var limb_status = fighter_data.get_limb_status("right_arm")
	var power_mult = limb_status.power_mult
	var total = base_speed * speed_mult * power_mult
	# Velocity direction toward opponent (simplified: forward)
	return Vector3(0, 0, -total)

func _apply_movement(delta: float, speed: float) -> void:
	pass  # Handled by FootworkController / CharacterBody3D

func _apply_lunge(data: Dictionary) -> void:
	fighter_data.spend_stamina(2.5)
	pass

# ────────────────────────────────────────────
# CLINCH
# ────────────────────────────────────────────

func _update_clinch(delta: float) -> void:
	pass  # Range maintained at 0.3-0.6m

func _handle_clinch_action(action_name: String, data: Dictionary) -> void:
	match action_name:
		"clinch_strike":
			_perform_clinch_strike(data)
		"pummel":
			_attempt_pummel()
		"clinch_takedown":
			_attempt_clinch_takedown(data)
		"clinch_break":
			_attempt_clinch_break()
		"cage_push":
			_attempt_cage_push(data)

func _perform_clinch_strike(data: Dictionary) -> void:
	if not opponent_state or _attack_cooldown > 0.0: return
	var strike_type = CombatGlobals.StrikeType.KNEE if data.get("type") == "knee" else \
		CombatGlobals.StrikeType.ELBOW
	var result = _ImpactCalc.resolve_strike(
		fighter_data, opponent_state.fighter_data,
		strike_type, "body" if strike_type == CombatGlobals.StrikeType.KNEE else "head",
		Vector3.ZERO, false, 0.4, false
	)
	_apply_strike_result(result, strike_type)
	strike_landed.emit(result)

func _attempt_pummel() -> void:
	if not opponent_state: return
	var off = fighter_data.get_skill("clinch_offense")
	var def = opponent_state.fighter_data.get_skill("clinch_defense")
	var win = (off / 100.0) > (def / 100.0 + randf_range(-0.2, 0.2))
	fighter_data.spend_stamina(2.0)
	opponent_state.fighter_data.spend_stamina(2.0)
	# Winner of pummel gets control advantage (affects next clinch action)

func _attempt_clinch_takedown(data: Dictionary) -> void:
	if not opponent_state: return
	var td_skill = fighter_data.get_skill("clinch_takedown") / 100.0
	var def = opponent_state.fighter_data.get_skill("td_defense") / 100.0
	var success = (td_skill * 0.7) > (def * 0.5 + randf() * 0.3)
	fighter_data.spend_stamina(6.0)
	if success:
		_transition_to(CombatGlobals.FightState.GROUND_TOP)
		opponent_state._transition_to(CombatGlobals.FightState.GROUND_BOTTOM)
	takedown_attempted.emit(success)

func _attempt_clinch_break() -> void:
	if not opponent_state: return
	var escape = fighter_data.get_skill("clinch_defense") / 100.0
	var control = opponent_state.fighter_data.get_skill("clinch_offense") / 100.0
	if (escape * 0.6) > (control * 0.4 + randf() * 0.2):
		_transition_to(CombatGlobals.FightState.STAND_UP)
		opponent_state._transition_to(CombatGlobals.FightState.STAND_UP)

func _attempt_cage_push(data: Dictionary) -> void:
	if not opponent_state: return
	var str = fighter_data.get_d("clinch_push", 0.3)
	var opp_str = opponent_state.fighter_data.get_d("clinch_push", 0.3)
	# Cage push moves opponent toward cage wall
	pass

# ────────────────────────────────────────────
# GROUND (TOP)
# ────────────────────────────────────────────

func _update_ground_top(delta: float) -> void:
	pass

func _handle_ground_top_action(action_name: String, data: Dictionary) -> void:
	match action_name:
		"gnp":
			_perform_gnp(data)
		"ground_transition":
			_attempt_ground_transition(data)
		"sub_attempt_top":
			_attempt_submission(true)
		"posture_up":
			_apply_posture()
		"stand_up":
			_attempt_stand_up()
		"deny_transition":
			_attempt_deny(data)

func _perform_gnp(data: Dictionary) -> void:
	if not opponent_state or _attack_cooldown > 0.0: return
	var gnp_mult = fighter_data.get_d("gnp_damage_mult", 0.5)
	var tc = fighter_data.get_skill("top_control") / 100.0
	var damage = 2.0 * gnp_mult * (0.5 + tc * 0.5)
	opponent_state.fighter_data.apply_damage("head", damage * 0.4)
	opponent_state.fighter_data.apply_damage("torso", damage * 0.6)
	fighter_data.spend_stamina(2.0)
	_attack_cooldown = 0.3

func _attempt_ground_transition(data: Dictionary) -> void:
	if not opponent_state: return
	var dir = data.get("direction", Vector2.DOWN)
	var gp_mult = 0.5 + (fighter_data.get_skill("guard_pass") / 200.0)
	var ret_mult = opponent_state.fighter_data.get_skill("guard_retention") / 100.0
	var progress = gp_mult - ret_mult * 0.5 + randf_range(-0.1, 0.1)

	if progress > 0.3:
		var new_pos = _next_ground_position_up(ground_position)
		if new_pos != ground_position:
			var old = ground_position
			ground_position = new_pos
			grapple_transitioned.emit(old, new_pos)

func _attempt_stand_up() -> void:
	if not opponent_state: return
	_transition_to(CombatGlobals.FightState.STAND_UP)
	opponent_state._transition_to(CombatGlobals.FightState.STAND_UP)

func _apply_posture() -> void:
	pass

func _attempt_deny(data: Dictionary) -> void:
	pass  # Successful deny stops opponent transition

func _next_ground_position_up(current: int) -> int:
	match current:
		CombatGlobals.GroundPosition.OPEN_GUARD: return CombatGlobals.GroundPosition.HALF_GUARD
		CombatGlobals.GroundPosition.HALF_GUARD: return CombatGlobals.GroundPosition.SIDE_CONTROL
		CombatGlobals.GroundPosition.SIDE_CONTROL: return CombatGlobals.GroundPosition.MOUNT
		CombatGlobals.GroundPosition.MOUNT: return CombatGlobals.GroundPosition.BACK_MOUNT
		_: return current

# ────────────────────────────────────────────
# GROUND (BOTTOM)
# ────────────────────────────────────────────

func _update_ground_bottom(delta: float) -> void:
	pass

func _handle_ground_bottom_action(action_name: String, data: Dictionary) -> void:
	match action_name:
		"sweep":
			_attempt_sweep(data)
		"sub_attempt_bottom":
			_attempt_submission(false)
		"frame":
			_apply_frame()
		"getup":
			_attempt_stand_up()
		"scramble":
			_attempt_scramble()
		"arm_drag":
			_attempt_arm_drag()
		"deny_gnp":
			_attempt_deny(data)

func _attempt_sweep(data: Dictionary) -> void:
	if not opponent_state: return
	var bc = fighter_data.get_skill("bottom_control") / 100.0
	var tc = opponent_state.fighter_data.get_skill("top_control") / 100.0
	var chance = bc * 0.7 - tc * 0.5 + randf_range(-0.1, 0.2)
	fighter_data.spend_stamina(5.0)
	if chance > 0.3:
		# Reversal
		_transition_to(CombatGlobals.FightState.GROUND_TOP)
		opponent_state._transition_to(CombatGlobals.FightState.GROUND_BOTTOM)

func _apply_frame() -> void:
	pass

func _attempt_scramble() -> void:
	fighter_data.spend_stamina(4.0)
	opponent_state.fighter_data.spend_stamina(4.0)
	var spd = fighter_data.speed / 100.0
	var opp_spd = opponent_state.fighter_data.speed / 100.0
	if spd > opp_spd + randf_range(-0.2, 0.2):
		_transition_to(CombatGlobals.FightState.STAND_UP)
		opponent_state._transition_to(CombatGlobals.FightState.GROUND_TOP)

func _attempt_arm_drag() -> void:
	if not opponent_state: return
	var chance = fighter_data.get_skill("bottom_control") / 100.0
	var opp_tc = opponent_state.fighter_data.get_skill("top_control") / 100.0
	if (chance * 0.5) > (opp_tc * 0.3 + randf() * 0.3):
		# Arm drag to back
		ground_position = CombatGlobals.GroundPosition.BACK_MOUNT
		opponent_state.ground_position = CombatGlobals.GroundPosition.BACK_MOUNT
		_transition_to(CombatGlobals.FightState.GROUND_TOP)
		opponent_state._transition_to(CombatGlobals.FightState.GROUND_BOTTOM)

# ────────────────────────────────────────────
# SUBMISSIONS
# ────────────────────────────────────────────

func _attempt_submission(am_attacker: bool) -> void:
	if not opponent_state: return
	var sub_off = fighter_data.get_skill("sub_offense") / 100.0
	var sub_def = opponent_state.fighter_data.get_skill("sub_defense") / 100.0
	var locked = (sub_off * 0.6) > (sub_def * 0.4 + randf() * 0.3)

	if locked:
		if am_attacker:
			_transition_to(CombatGlobals.FightState.SUBMISSION_TOP)
			opponent_state._transition_to(CombatGlobals.FightState.SUBMISSION_BOTTOM)
		else:
			_transition_to(CombatGlobals.FightState.SUBMISSION_BOTTOM)
			opponent_state._transition_to(CombatGlobals.FightState.SUBMISSION_TOP)
		submission_bar = 0.0
		sub_escape_bar = 0.0
	sub_attempted.emit(locked)

func _update_submission(delta: float, am_attacker: bool) -> void:
	if am_attacker:
		# Attacker uses SubOff to fill the bar
		var progress = (fighter_data.get_skill("sub_offense") / 100.0) * delta
		submission_bar += progress
		if submission_bar >= 100.0:
			# Submission victory
			_transition_to(CombatGlobals.FightState.SUBMISSION_LOSS)
	else:
		# Defender uses SubDef to escape
		var escape = (fighter_data.get_skill("sub_defense") / 100.0) * delta * 0.7
		sub_escape_bar += escape
		if sub_escape_bar >= 100.0:
			# Escape! Return to ground
			_transition_to(CombatGlobals.FightState.GROUND_BOTTOM)
			opponent_state._transition_to(CombatGlobals.FightState.GROUND_TOP)

func _handle_submission_action(action_name: String, data: Dictionary, am_attacker: bool) -> void:
	match action_name:
		"sub_escape":
			if not am_attacker:
				var dir = data.get("direction", Vector2.ZERO)
				# Direction-based escape mini-game
				sub_escape_bar += 10.0
				fighter_data.spend_stamina(3.0)
		"sub_advance":
			if am_attacker:
				var dir = data.get("direction", Vector2.ZERO)
				submission_bar += 10.0
				fighter_data.spend_stamina(3.0)
		"sub_tough_it":
			if not am_attacker:
				# Reduces sub bar progress rate but costs stamina
				submission_bar = max(0, submission_bar - 2.0)
				fighter_data.spend_stamina(2.0)
		"sub_chain":
			if am_attacker:
				# Attempt to chain to a different submission (reset bar)
				var chain_cost = 15.0
				if fighter_data.get_stamina() >= chain_cost:
					fighter_data.spend_stamina(chain_cost)
					submission_bar = 0.0
					sub_escape_bar = 0.0

# ────────────────────────────────────────────
# STATE TRANSITION
# ────────────────────────────────────────────

func _transition_to(new_state: int) -> void:
	previous_state = current_state
	current_state = new_state
	is_blocking = false
	state_changed.emit(previous_state, new_state)

# ── Utility: map string to strike type ──
func _get_strike_type(data: Dictionary) -> int:
	var type_str: String = data.get("type", "jab")
	match type_str:
		"jab": return CombatGlobals.StrikeType.JAB
		"cross": return CombatGlobals.StrikeType.CROSS
		"hook": return CombatGlobals.StrikeType.HOOK
		"uppercut": return CombatGlobals.StrikeType.UPPERCUT
		"roundhouse": return CombatGlobals.StrikeType.ROUNDHOUSE
		"front_kick": return CombatGlobals.StrikeType.FRONT_KICK
		"leg_kick": return CombatGlobals.StrikeType.LEG_KICK
		"head_kick": return CombatGlobals.StrikeType.HEAD_KICK
		"knee": return CombatGlobals.StrikeType.KNEE
		"elbow": return CombatGlobals.StrikeType.ELBOW
	return CombatGlobals.StrikeType.JAB
