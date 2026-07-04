# scripts/autoload/InputSetup.gd
# Registers input actions at runtime so project.godot stays clean.
# Called from CombatGlobals or Main scene.
extends Node

static func register_all() -> void:
	var im = InputMap
	
	if not im.has_action("move_left"): im.add_action("move_left", 0.3)
	if not im.has_action("move_right"): im.add_action("move_right", 0.3)
	if not im.has_action("move_up"): im.add_action("move_up", 0.3)
	if not im.has_action("move_down"): im.add_action("move_down", 0.3)
	if not im.has_action("action_a_punch"): im.add_action("action_a_punch")
	if not im.has_action("action_b_hook"): im.add_action("action_b_hook")
	if not im.has_action("action_x_kick"): im.add_action("action_x_kick")
	if not im.has_action("action_y_special"): im.add_action("action_y_special")
	if not im.has_action("mod_high"): im.add_action("mod_high")
	if not im.has_action("mod_low"): im.add_action("mod_low")
	if not im.has_action("mod_perfect"): im.add_action("mod_perfect")
	if not im.has_action("action_block"): im.add_action("action_block")
	if not im.has_action("head_slip_up"): im.add_action("head_slip_up")
	if not im.has_action("head_slip_down"): im.add_action("head_slip_down")
	if not im.has_action("head_slip_left"): im.add_action("head_slip_left")
	if not im.has_action("head_slip_right"): im.add_action("head_slip_right")
	if not im.has_action("parry"): im.add_action("parry")
	if not im.has_action("action_deny"): im.add_action("action_deny")
	if not im.has_action("action_transition"): im.add_action("action_transition")
	if not im.has_action("action_getup"): im.add_action("action_getup")
	if not im.has_action("action_pummel"): im.add_action("action_pummel")
	if not im.has_action("action_escape"): im.add_action("action_escape")

	# ── Keyboard bindings ──
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_key("move_up", KEY_W)
	_add_key("move_down", KEY_S)
	_add_key("action_a_punch", KEY_J)
	_add_key("action_b_hook", KEY_K)
	_add_key("action_x_kick", KEY_U)
	_add_key("action_y_special", KEY_I)
	_add_key("mod_high", KEY_Q)
	_add_key("mod_low", KEY_E)
	_add_key("mod_perfect", KEY_T)
	_add_key("action_block", KEY_SPACE)
	_add_key("head_slip_up", KEY_UP)
	_add_key("head_slip_down", KEY_DOWN)
	_add_key("head_slip_left", KEY_LEFT)
	_add_key("head_slip_right", KEY_RIGHT)
	_add_key("parry", KEY_ENTER)
	_add_key("action_deny", KEY_F)
	_add_key("action_transition", KEY_R)
	_add_key("action_getup", KEY_G)
	_add_key("action_pummel", KEY_P)
	_add_key("action_escape", KEY_SHIFT)

static func _add_key(action: String, keycode: Key) -> void:
	var ev = InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)
