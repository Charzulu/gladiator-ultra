# scripts/animation/StrikePlanner.gd
# Procedural strike trajectory planner.
# Each strike type is a parametric function: local_pos = f(t) where t ∈ [0, 1]
# Speed, range, and recovery are modulated by fighter stats.
# Pure math — no scene tree dependency.
extends RefCounted

# ── Strike plan output ──
class StrikePlan:
	var strike_type: int = 0
	var trajectory_func  # Callable: func(t: float, stats_mod: Dictionary) -> Vector3
	var target_zone: String = "head"
	var total_duration: float = 0.0     # seconds from start to recovery end
	var startup_frames: int = 0         # frames before contact possible
	var active_frames: int = 0          # frames where hurtbox is live
	var recovery_frames: int = 0        # frames after contact/miss to return to guard
	var limb_bone: String = ""          # which helper bone is the weapon (e.g. "Bone_fist_R")
	var stamina_cost: float = 0.0
	var base_damage: float = 0.0
	var reach_meters: float = 0.0       # max extension distance from shoulder
	var velocity_at_contact: Vector3 = Vector3.ZERO  # computed limb tip velocity
	var target_position: Vector3 = Vector3.ZERO       # where the IK aims

# ── Stats modifier structure (compressed from FighterData) ──
class StatsMod:
	var speed_mult: float = 1.0       # from SPD stat
	var strength_mult: float = 1.0    # from STR stat
	var gassed: bool = false
	var limb_power: float = 1.0       # limb damage penalty
	var limb_speed: float = 1.0       # limb damage penalty
	var reach_mod: float = 1.0        # from stance + limb health
	var combo_penalty: float = 1.0    # per consecutive strike
	var lunge_distance: float = 1.5   # from StyleData
	var ideal_range: float = 1.5      # from StyleData
	var weight_class: int = 0
	var is_counter: bool = false
	var perfect_timing: bool = false

# ── Plan a strike ──
static func plan(strike_type: int, target_zone: String, stats: StatsMod, variant = null) -> StrikePlan:
	var plan = StrikePlan.new()
	plan.strike_type = strike_type
	plan.target_zone = target_zone

	match strike_type:
		0: _plan_jab(plan, stats)
		1: _plan_cross(plan, stats)
		2: _plan_hook(plan, stats)
		3: _plan_uppercut(plan, stats)
		4: _plan_roundhouse(plan, stats)
		5: _plan_front_kick(plan, stats)
		6: _plan_leg_kick(plan, stats)
		7: _plan_head_kick(plan, stats)
		8: _plan_knee(plan, stats)
		9: _plan_elbow(plan, stats)
		_: _plan_jab(plan, stats)
	
	# ── Apply variant multipliers (before stat modifiers) ──
	if variant:
		plan.startup_frames   = max(1, int(plan.startup_frames * variant.startup_mult))
		plan.active_frames    = max(1, int(plan.active_frames * variant.active_mult))
		plan.recovery_frames  = max(1, int(plan.recovery_frames * variant.recovery_mult))
		plan.base_damage      = plan.base_damage * variant.damage_mult
		plan.stamina_cost     = plan.stamina_cost * variant.stamina_cost_mult
		plan.reach_meters     = plan.reach_meters * variant.reach_mult
		plan.stamina_cost    += variant.stun_chance_add * 0.5  # slight stam bump for stun chance
	
	# ── Apply stat modifiers (existing) ──
	var spd = stats.speed_mult
	var gassed = stats.gassed
	var limb_spd = stats.limb_speed

	plan.startup_frames = max(1, int(plan.startup_frames * spd * (1.3 if gassed else 1.0) / limb_spd))
	plan.active_frames = max(1, int(plan.active_frames * spd * (1.2 if gassed else 1.0) / limb_spd))
	plan.recovery_frames = max(1, int(plan.recovery_frames * spd * (1.5 if gassed else 1.0) * stats.combo_penalty / limb_spd))
	plan.total_duration = (plan.startup_frames + plan.active_frames + plan.recovery_frames) / 60.0
	plan.reach_meters *= stats.reach_mod * (0.85 if gassed else 1.0)
	plan.stamina_cost *= (1.3 if gassed else 1.0) * stats.combo_penalty
	plan.base_damage *= stats.strength_mult * stats.limb_power * (1.25 if stats.perfect_timing else 1.0) * (1.35 if stats.is_counter else 1.0)

	return plan

# ── Trajectory functions ──
# Each returns a local-space offset from the strike origin bone (shoulder/hip).
# t goes from 0.0 (start) to 1.0 (full extension).
# The caller applies IK to reach this position, then reverses for recovery.

static func get_trajectory(strike_type: int) -> Callable:
	match strike_type:
		0: return _jab_traj
		1: return _cross_traj
		2: return _hook_traj
		3: return _uppercut_traj
		4: return _roundhouse_traj
		5: return _front_kick_traj
		6: return _leg_kick_traj
		7: return _head_kick_traj
		8: return _knee_traj
		9: return _elbow_traj
		_: return _jab_traj

# ── Individual trajectory functions ──
# Parameters: t (0-1), reach_meters (max extension distance)

static func _jab_traj(t: float, reach: float) -> Vector3:
	# Linear forward extension with slight lateral variance
	var fwd = t * reach
	var lat = sin(t * PI) * 0.02
	return Vector3(lat, 0, -fwd)

static func _cross_traj(t: float, reach: float) -> Vector3:
	# Linear forward, slightly across body, slight rise at end
	var fwd = t * reach
	var lat = -t * 0.04  # slight cross-body
	var rise = t * t * 0.03
	return Vector3(lat, rise, -fwd)

static func _hook_traj(t: float, reach: float) -> Vector3:
	# Horizontal arc — wide, then inward
	var angle = t * PI * 0.85
	var radius = 0.25 + t * 0.12
	return Vector3(
		-sin(angle) * radius,
		sin(t * PI * 0.5) * 0.04,
		-cos(angle) * radius - 0.08
	)

static func _uppercut_traj(t: float, reach: float) -> Vector3:
	# Vertical rising arc — dips slightly then rises sharply
	var fwd = t * reach * 0.6
	var rise = -t * 0.05 + t * t * 0.35
	return Vector3(0, rise, -fwd)

static func _roundhouse_traj(t: float, reach: float) -> Vector3:
	# Circular rising arc, wide
	var angle = t * PI * 0.9
	var height = sin(t * PI) * 0.5
	return Vector3(
		sin(angle) * reach * 0.5,
		height * 0.5,
		-cos(angle) * reach * 0.4
	)

static func _front_kick_traj(t: float, reach: float) -> Vector3:
	# Linear forward, slight rise at end (teep)
	var fwd = t * reach
	var rise = t * t * 0.12
	return Vector3(0, rise, -fwd)

static func _leg_kick_traj(t: float, reach: float) -> Vector3:
	# Low circular arc, stays below 0.5m height
	var angle = t * PI * 0.8
	var height = sin(angle) * 0.3
	return Vector3(
		sin(angle) * reach * 0.4,
		-height,
		-cos(angle) * reach * 0.4
	)

static func _head_kick_traj(t: float, reach: float) -> Vector3:
	# High rising arc, peaks late
	var angle = t * PI * 0.95
	var height = sin(angle) * 0.9
	return Vector3(
		sin(angle) * reach * 0.5,
		height,
		-cos(angle) * reach * 0.4
	)

static func _knee_traj(t: float, reach: float) -> Vector3:
	# Short rising drive — straight up then forward
	var fwd = t * reach * 0.3
	var rise = t * 0.35
	return Vector3(0, rise, -fwd)

static func _elbow_traj(t: float, reach: float) -> Vector3:
	# Short horizontal arc — tight, devastating
	var angle = t * PI * 0.6
	return Vector3(
		-sin(angle) * 0.15,
		sin(t * PI) * 0.02,
		-cos(angle) * 0.2 - 0.1
	)

# ── Individual strike stat definitions ──

static func _plan_jab(plan: StrikePlan, stats: StatsMod) -> void:
	plan.limb_bone = "Bone_fist_L"
	plan.trajectory_func = _jab_traj
	plan.startup_frames = 3; plan.active_frames = 3; plan.recovery_frames = 4
	plan.reach_meters = 1.0 + stats.lunge_distance * 0.1
	plan.stamina_cost = 2.0; plan.base_damage = 5.0

static func _plan_cross(plan: StrikePlan, stats: StatsMod) -> void:
	plan.limb_bone = "Bone_fist_R"
	plan.trajectory_func = _cross_traj
	plan.startup_frames = 5; plan.active_frames = 4; plan.recovery_frames = 7
	plan.reach_meters = 1.1 + stats.lunge_distance * 0.12
	plan.stamina_cost = 3.5; plan.base_damage = 9.0

static func _plan_hook(plan: StrikePlan, stats: StatsMod) -> void:
	plan.limb_bone = "Bone_fist_L"
	plan.trajectory_func = _hook_traj
	plan.startup_frames = 7; plan.active_frames = 4; plan.recovery_frames = 9
	plan.reach_meters = 0.8 + stats.lunge_distance * 0.08
	plan.stamina_cost = 4.0; plan.base_damage = 12.0

static func _plan_uppercut(plan: StrikePlan, stats: StatsMod) -> void:
	plan.limb_bone = "Bone_fist_R"
	plan.trajectory_func = _uppercut_traj
	plan.startup_frames = 6; plan.active_frames = 4; plan.recovery_frames = 8
	plan.reach_meters = 0.7 + stats.lunge_distance * 0.05
	plan.stamina_cost = 4.0; plan.base_damage = 11.0

static func _plan_roundhouse(plan: StrikePlan, stats: StatsMod) -> void:
	plan.limb_bone = "Bone_toe_R"
	plan.trajectory_func = _roundhouse_traj
	plan.startup_frames = 10; plan.active_frames = 5; plan.recovery_frames = 14
	plan.reach_meters = 1.5 + stats.lunge_distance * 0.15
	plan.stamina_cost = 5.5; plan.base_damage = 14.0

static func _plan_front_kick(plan: StrikePlan, stats: StatsMod) -> void:
	plan.limb_bone = "Bone_toe_L"
	plan.trajectory_func = _front_kick_traj
	plan.startup_frames = 7; plan.active_frames = 4; plan.recovery_frames = 8
	plan.reach_meters = 1.4 + stats.lunge_distance * 0.1
	plan.stamina_cost = 3.0; plan.base_damage = 8.0

static func _plan_leg_kick(plan: StrikePlan, stats: StatsMod) -> void:
	plan.limb_bone = "Bone_knee_L"
	plan.trajectory_func = _leg_kick_traj
	plan.startup_frames = 7; plan.active_frames = 4; plan.recovery_frames = 8
	plan.reach_meters = 1.2 + stats.lunge_distance * 0.1
	plan.stamina_cost = 3.5; plan.base_damage = 7.0

static func _plan_head_kick(plan: StrikePlan, stats: StatsMod) -> void:
	plan.limb_bone = "Bone_toe_R"
	plan.trajectory_func = _head_kick_traj
	plan.startup_frames = 12; plan.active_frames = 5; plan.recovery_frames = 18
	plan.reach_meters = 1.5 + stats.lunge_distance * 0.15
	plan.stamina_cost = 7.0; plan.base_damage = 18.0

static func _plan_knee(plan: StrikePlan, stats: StatsMod) -> void:
	plan.limb_bone = "Bone_knee_R"
	plan.trajectory_func = _knee_traj
	plan.startup_frames = 4; plan.active_frames = 3; plan.recovery_frames = 6
	plan.reach_meters = 0.5 + stats.lunge_distance * 0.02
	plan.stamina_cost = 3.0; plan.base_damage = 10.0

static func _plan_elbow(plan: StrikePlan, stats: StatsMod) -> void:
	plan.limb_bone = "Bone_elbow_R"
	plan.trajectory_func = _elbow_traj
	plan.startup_frames = 5; plan.active_frames = 3; plan.recovery_frames = 8
	plan.reach_meters = 0.4 + stats.lunge_distance * 0.02
	plan.stamina_cost = 3.5; plan.base_damage = 13.0

# ── Evaluate trajectory at a specific t value ──
static func eval_trajectory(plan: StrikePlan, t: float) -> Vector3:
	var traj = plan.trajectory_func
	if traj:
		return traj.call(t, plan.reach_meters)
	return Vector3.ZERO

# ── Compute IK target from trajectory + opponent position ──
static func compute_target_position(
	plan: StrikePlan,
	attacker_shoulder: Vector3,
	opponent_hitbox_center: Vector3,
	t: float
) -> Vector3:
	# Use trajectory path relative to shoulder, rotated toward opponent
	var local_offset = eval_trajectory(plan, t)
	var dir_to_opponent = (opponent_hitbox_center - attacker_shoulder).normalized()
	var up = Vector3.UP

	# Build rotation matrix from shoulder to opponent
	var right = up.cross(dir_to_opponent).normalized()
	if right.length_squared() < 0.0001:
		right = Vector3.RIGHT
	up = dir_to_opponent.cross(right).normalized()

	var world_offset = right * local_offset.x + up * local_offset.y + dir_to_opponent * (-local_offset.z)
	return attacker_shoulder + world_offset
