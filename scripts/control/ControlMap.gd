# scripts/control/ControlMap.gd
# Routes raw player input to context-sensitive actions based on current fight state.
# Each fight state (STAND_UP, CLINCH, GROUND_TOP, GROUND_BOTTOM, SUBMISSION) reinterprets the same face buttons.
# Singleton pattern — use via ControlMap.get_instance()
extends RefCounted

signal action_triggered(action_name: String, action_data: Dictionary)

# ── Singleton access ──
static var _instance: ControlMap = null

static func get_instance() -> ControlMap:
	if _instance == null:
		_instance = ControlMap.new()
	return _instance

# ── Current state ──
var current_state: int = 0  # CombatGlobals.FightState
var previous_state: int = 0

# ── Action buffer ──
var last_action: Dictionary = {}  # { "action": "...", "timestamp": 0.0, "directional": Vector2 }

# ── Poll and route ──
func poll(delta: float) -> void:
	var state = current_state
	match state:
		0: _poll_stand_up()
		1: _poll_clinch()
		2: _poll_ground_top()
		3: _poll_ground_bottom()
		4, 5: _poll_submission()
		_: _poll_stand_up()

func set_state(new_state: int) -> void:
	previous_state = current_state
	current_state = new_state

# ── Helper: emit action ──
func _action(name: String, data: Dictionary = {}) -> void:
	data["state"] = current_state
	last_action = {"action": name, "timestamp": Time.get_ticks_usec() / 1000000.0, "directional": _get_ls_dir()}
	action_triggered.emit(name, data)

# ── Direction helpers ──
func _get_ls_dir() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

func _get_rs_dir() -> Vector2:
	var x = Input.get_axis(&"head_slip_left", &"head_slip_right")
	var y = Input.get_axis(&"head_slip_up", &"head_slip_down")
	return Vector2(x, y)

func _is_held(action: String) -> bool:
	return Input.is_action_pressed(action)

func _is_just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)

# ────────────────────────────────────────────
# STAND-UP CONTROL MAP
# ────────────────────────────────────────────

func _poll_stand_up() -> void:
	var ls = _get_ls_dir()
	var rs = _get_rs_dir()
	var lt = _is_held(&"mod_perfect")   # LT = perfect striking
	var high = _is_held(&"mod_high")     # LB = high target
	var low = _is_held(&"mod_low")      # RB = low target
	var block = _is_held(&"action_block") # RT = block

	# HEAD MOVEMENT (Right stick)
	if rs.length_squared() > 0.3:
		if rs.y < -0.5: _action("slip_up")
		elif rs.y > 0.5: _action("duck")
		elif rs.x < -0.5: _action("slip_left")
		elif rs.x > 0.5: _action("slip_right")

	# PARRY (RS click)
	if _is_just_pressed(&"parry"):
		_action("parry")

	# LEAD HAND (A / Cross button)
	if _is_just_pressed(&"action_a_punch"):
		if high: _action("strike", {"type": "jab", "target": "head", "perfect": lt})
		elif low: _action("strike", {"type": "jab", "target": "body", "perfect": lt})
		else: _action("strike", {"type": "jab", "target": "head", "perfect": lt})

	# REAR HAND / HOOK (B / Circle)
	if _is_just_pressed(&"action_b_hook"):
		if high: _action("strike", {"type": "hook", "target": "head", "perfect": lt})
		elif low: _action("strike", {"type": "hook", "target": "body", "perfect": lt})
		else: _action("strike", {"type": "cross", "target": "head", "perfect": lt})

	# LEAD KICK (X / Square)
	if _is_just_pressed(&"action_x_kick"):
		if high: _action("strike", {"type": "front_kick", "target": "body", "perfect": lt})
		elif low: _action("strike", {"type": "leg_kick", "target": "leg", "perfect": lt})
		else: _action("strike", {"type": "front_kick", "target": "body", "perfect": lt})

	# REAR KICK / SPECIAL (Y / Triangle)
	if _is_just_pressed(&"action_y_special"):
		if high: _action("strike", {"type": "head_kick", "target": "head", "perfect": lt})
		elif low: _action("strike", {"type": "roundhouse", "target": "body", "perfect": lt})
		else: _action("strike", {"type": "roundhouse", "target": "body", "perfect": lt})

	# CLINCH ENTRY (LS toward opponent + A with low modifier held)
	if low and _is_just_pressed(&"action_a_punch") and ls.length_squared() > 0.5:
		_action("clinch_entry")

	# TAKEDOWN SHOT (LS toward + A held with perfect modifier)
	if lt and _is_just_pressed(&"action_a_punch") and ls.length_squared() > 0.5:
		_action("takedown_shot", {"type": "double_leg"})

	# SINGLE LEG (LS toward + LT + X)
	if lt and _is_just_pressed(&"action_x_kick") and ls.length_squared() > 0.5:
		_action("takedown_shot", {"type": "single_leg"})

	# BLOCK
	if block:
		_action("block_start")

	# LUNGE (LS double-tap or LS toward + A without modifier)
	if ls.length_squared() > 0.7 and _is_just_pressed(&"action_a_punch") and not lt and not low:
		_action("lunge", {"direction": ls})

func _poll_clinch() -> void:
	var ls = _get_ls_dir()
	var rs = _get_rs_dir()
	var lt = _is_held(&"mod_perfect")

	# STRIKES
	if _is_just_pressed(&"action_a_punch"): _action("clinch_strike", {"type": "knee"})
	if _is_just_pressed(&"action_b_hook"): _action("clinch_strike", {"type": "elbow"})
	if _is_just_pressed(&"action_x_kick"): _action("clinch_strike", {"type": "body_knee"})

	# PUMMEL
	if _is_just_pressed(&"action_y_special"): _action("pummel")

	# TAKEDOWN FROM CLINCH
	if lt and _is_just_pressed(&"action_a_punch"):
		_action("clinch_takedown", {"direction": ls})

	# BREAK / ESCAPE
	if _is_just_pressed(&"action_escape"): _action("clinch_break")

	# CAGE PUSH (RS direction + RT)
	if _is_held(&"action_block") and rs.length_squared() > 0.3:
		_action("cage_push", {"direction": rs})

func _poll_ground_top() -> void:
	var rs = _get_rs_dir()
	var lt = _is_held(&"mod_perfect")

	# GROUND AND POUND
	if _is_just_pressed(&"action_a_punch"): _action("gnp", {"hand": "right"})
	if _is_just_pressed(&"action_b_hook"): _action("gnp", {"hand": "left"})
	if lt and _is_just_pressed(&"action_a_punch"): _action("gnp", {"hand": "hammer"})
	if lt and _is_just_pressed(&"action_b_hook"): _action("gnp", {"hand": "elbow"})

	# TRANSITIONS (RS direction)
	if _is_just_pressed(&"action_transition") and rs.length_squared() > 0.3:
		_action("ground_transition", {"direction": rs})

	# SUBMISSION ATTEMPT
	if _is_just_pressed(&"action_x_kick"): _action("sub_attempt_top")

	# POSTURE / STAND
	if _is_just_pressed(&"action_y_special"):
		if lt: _action("stand_up")
		else: _action("posture_up")

	# DENY opponent transition
	if _is_just_pressed(&"action_deny") and rs.length_squared() > 0.3:
		_action("deny_transition", {"direction": rs})

func _poll_ground_bottom() -> void:
	var rs = _get_rs_dir()
	var lt = _is_held(&"mod_perfect")

	# SWEEP
	if _is_just_pressed(&"action_a_punch") and rs.length_squared() > 0.3:
		_action("sweep", {"direction": rs})

	# SUBMISSION FROM BOTTOM
	if _is_just_pressed(&"action_b_hook"): _action("sub_attempt_bottom")

	# FRAME / WRIST CONTROL
	if _is_just_pressed(&"action_x_kick"): _action("frame")

	# STAND UP
	if _is_just_pressed(&"action_y_special"):
		if lt: _action("wall_walk")
		else: _action("getup")

	# SCRAMBLE
	if lt and _is_just_pressed(&"action_a_punch"): _action("scramble")

	# ARM DRAG
	if lt and _is_just_pressed(&"action_x_kick"): _action("arm_drag")

	# DENY GNP / PASS
	if _is_just_pressed(&"action_deny") and rs.length_squared() > 0.3:
		_action("deny_gnp", {"direction": rs})

func _poll_submission() -> void:
	var ls = _get_ls_dir()

	# ESCAPE DIRECTION (rotate stick as prompted)
	if _is_just_pressed(&"action_escape"):
		_action("sub_escape", {"direction": ls})

	# TAP OUT
	if _is_just_pressed(&"action_deny"):
		_action("tap_out")

	# GRIMACE / TOUGH IT OUT
	if _is_held(&"mod_perfect"):
		_action("sub_tough_it")

	# ROTATE TO ADVANCE (attacker)
	if _is_just_pressed(&"action_transition"):
		_action("sub_advance", {"direction": ls})

	# CHAIN TO DIFFERENT SUB
	if _is_held(&"mod_perfect") and _is_just_pressed(&"action_transition"):
		_action("sub_chain", {"direction": ls})
