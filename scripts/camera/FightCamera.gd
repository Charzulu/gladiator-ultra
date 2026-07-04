# scripts/camera/FightCamera.gd
# Third-person camera that tracks the action between two fighters.
# Orbits around the fight midpoint, adjusts distance by fight state,
# and applies shake on heavy impacts.
extends Camera3D

# ── Config ──
@export var base_distance: float = 3.5        # stand-up distance
@export var clinch_distance: float = 2.0      # clinch zoom
@export var ground_distance: float = 2.8      # ground distance (top-down-ish)
@export var height_offset: float = 1.5        # height above midpoint (stand-up)
@export var ground_height_offset: float = 2.5 # height above midpoint (ground)
@export var orbit_speed: float = 3.0          # rad/s for orbit rotation
@export var follow_lerp: float = 5.0          # position smoothing
@export var look_lerp: float = 8.0            # look-at smoothing
@export var shake_decay: float = 6.0          # shake intensity decay rate

# ── References ──
var target_a: Node3D  # Fighter 1 position node
var target_b: Node3D  # Fighter 2 position node
var match_manager_ref  # MatchManager (optional, for state-aware behavior)

# ── Internal ──
var _orbit_angle: float = 0.0                # horizontal orbit angle (rad)
var _orbit_pitch: float = 0.3                # vertical angle (rad, from horizon)
var _current_distance: float = 3.5
var _target_distance: float = 3.5
var _shake_offset: Vector3 = Vector3.ZERO
var _shake_intensity: float = 0.0

var _current_pos: Vector3
var _current_look: Vector3

# ──────────────────────────────────────────────────────
# INIT
# ──────────────────────────────────────────────────────

func setup(t1: Node3D, t2: Node3D, match_mgr = null) -> void:
	"""Initialize camera with fighter position nodes."""
	target_a = t1
	target_b = t2
	match_manager_ref = match_mgr
	
	# Set initial position behind the midpoint
	var mid = _get_midpoint()
	_current_pos = mid + Vector3(0, height_offset, base_distance)
	_current_look = mid
	global_position = _current_pos

# ──────────────────────────────────────────────────────
# INPUT
# ──────────────────────────────────────────────────────

func rotate_orbit(delta_h: float, delta_v: float) -> void:
	"""Apply orbit rotation from right stick or mouse.
	delta_h/delta_v are already delta-time-multiplied (e.g. axis_value * delta)."""
	_orbit_angle += delta_h * orbit_speed
	_orbit_pitch = clampf(_orbit_pitch + delta_v * 0.5, -0.2, 1.2)

# ──────────────────────────────────────────────────────
# PHYSICS UPDATE
# ──────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not target_a or not target_b:
		return
	
	# ── 1. Get midpoint of both fighters ──
	var mid = _get_midpoint()
	
	# ── 2. Check fight state for distance/height adjustments ──
	_adjust_for_fight_state()
	
	# ── 3. Calculate camera position ──
	# Orbit around the midpoint
	var horizontal = Vector3(sin(_orbit_angle), 0, cos(_orbit_angle))
	var vertical = Vector3.UP * sin(_orbit_pitch)
	var dir = (horizontal + vertical).normalized()
	var desired_pos = mid + dir * _current_distance
	
	# Clamp height so camera doesn't go below y=0
	desired_pos.y = max(desired_pos.y, 0.5)
	
	# ── 4. Apply shake ──
	_shake_offset = _update_shake(delta)
	desired_pos += _shake_offset
	
	# ── 5. Smooth follow ──
	_current_pos = _current_pos.lerp(desired_pos, follow_lerp * delta)
	global_position = _current_pos
	
	# ── 6. Look at midpoint ──
	_current_look = _current_look.lerp(mid, look_lerp * delta)
	look_at(_current_look, Vector3.UP)

# ──────────────────────────────────────────────────────
# FIGHT STATE AWARENESS
# ──────────────────────────────────────────────────────

func _adjust_for_fight_state() -> void:
	"""Adjust distance and height based on current fight state."""
	if not match_manager_ref:
		# No match manager — use default stand-up distance
		_target_distance = base_distance
		return
	
	var state = match_manager_ref.current_state
	# Check fight state via match manager or fighter FSM states
	
	var fsm_a = match_manager_ref.get_fighter_fsm(0)
	var fsm_b = match_manager_ref.get_fighter_fsm(1)
	
	if not fsm_a or not fsm_b:
		_target_distance = base_distance
		return
	
	# Determine state from either fighter's FSM
	var fight_state = fsm_a.current_state
	
	match fight_state:
		CombatGlobals.FightState.STAND_UP:
			_target_distance = base_distance
		CombatGlobals.FightState.CLINCH:
			_target_distance = clinch_distance
		CombatGlobals.FightState.GROUND_TOP, CombatGlobals.FightState.GROUND_BOTTOM:
			_target_distance = ground_distance
		CombatGlobals.FightState.SUBMISSION_TOP, CombatGlobals.FightState.SUBMISSION_BOTTOM:
			_target_distance = ground_distance * 0.8
		CombatGlobals.FightState.KO, CombatGlobals.FightState.TKO:
			_target_distance = clinch_distance  # zoom in on finish
		_:
			_target_distance = base_distance
	
	_current_distance = lerpf(_current_distance, _target_distance, follow_lerp * get_physics_process_delta_time())

# ──────────────────────────────────────────────────────
# CAMERA SHAKE
# ──────────────────────────────────────────────────────

func trigger_shake(intensity: float = 0.5) -> void:
	"""Start camera shake at given intensity (0.0 - 1.0)."""
	_shake_intensity = clampf(intensity, 0.0, 1.0)

func _update_shake(delta: float) -> Vector3:
	"""Apply shake decay and return current shake offset."""
	if _shake_intensity <= 0.01:
		_shake_intensity = 0.0
		return Vector3.ZERO
	
	_shake_intensity = max(0.0, _shake_intensity - shake_decay * delta)
	var mag = _shake_intensity * 0.15  # max 15cm shake
	return Vector3(
		randf_range(-mag, mag),
		randf_range(-mag, mag),
		randf_range(-mag, mag)
	)

# ──────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────

func _get_midpoint() -> Vector3:
	"""Return the midpoint between both fighters."""
	if not target_a or not target_b:
		return Vector3.ZERO
	return (target_a.global_position + target_b.global_position) * 0.5

func reposition(instant: bool = false) -> void:
	"""Snap camera to correct position immediately (for round starts)."""
	if not target_a or not target_b:
		return
	var mid = _get_midpoint()
	var horizontal = Vector3(sin(_orbit_angle), 0, cos(_orbit_angle))
	var vertical = Vector3.UP * sin(_orbit_pitch)
	var dir = (horizontal + vertical).normalized()
	_current_pos = mid + dir * _current_distance
	_current_pos.y = max(_current_pos.y, 0.5)
	_current_look = mid
	global_position = _current_pos
	look_at(_current_look, Vector3.UP)
