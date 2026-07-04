# scripts/ui/FightHUD.gd
# In-fight HUD overlay — health bars, stamina, timer, status.
extends CanvasLayer

var match_manager
var fighter1  # FighterData
var fighter2  # FighterData
var fighter1_fsm
var fighter2_fsm

# ── UI Nodes (created in _ready) ──
var _container: Control
var _panel_top: Panel
var _panel_bottom: Panel

# Fighter 1 (red, top-left)
var _f1_name: Label
var _f1_record: Label
var _f1_hp_bar: ColorRect
var _f1_hp_bg: ColorRect
var _f1_stam_bar: ColorRect
var _f1_stam_bg: ColorRect

# Fighter 2 (blue, bottom-right)
var _f2_name: Label
var _f2_record: Label
var _f2_hp_bar: ColorRect
var _f2_hp_bg: ColorRect
var _f2_stam_bar: ColorRect
var _f2_stam_bg: ColorRect

# Center
var _round_label: Label
var _timer_label: Label
var _versus_label: Label
var _status_label: Label  # STUNNED / DAZED / BLEEDING

# Colors
const HP_GREEN: Color = Color(0.2, 0.8, 0.2)
const HP_YELLOW: Color = Color(0.9, 0.8, 0.2)
const HP_RED: Color = Color(0.9, 0.2, 0.2)
const STAM_BLUE: Color = Color(0.2, 0.5, 0.9)
const STAM_ORANGE: Color = Color(0.9, 0.6, 0.1)
const RED_CORNER: Color = Color(0.8, 0.2, 0.2)
const BLUE_CORNER: Color = Color(0.2, 0.3, 0.8)

func _ready() -> void:
	layer = 10  # Above 3D
	_build_ui()

func _build_ui() -> void:
	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_container)
	
	# ── Round & Timer (top center) ──
	var center_box = HBoxContainer.new()
	center_box.position = Vector2(get_viewport().size.x * 0.3, 20)
	center_box.size = Vector2(get_viewport().size.x * 0.4, 40)
	add_child(center_box)
	
	_round_label = Label.new()
	_round_label.text = "ROUND 1"
	_round_label.add_theme_color_override("font_color", Color.WHITE)
	_round_label.add_theme_font_size_override("font_size", 24)
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(_round_label)
	
	_timer_label = Label.new()
	_timer_label.text = "5:00"
	_timer_label.add_theme_color_override("font_color", Color(1, 1, 0.8))
	_timer_label.add_theme_font_size_override("font_size", 28)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(_timer_label)
	
	# ── STATUS LABEL ──
	_status_label = Label.new()
	_status_label.position = Vector2(get_viewport().size.x * 0.35, 70)
	_status_label.size = Vector2(get_viewport().size.x * 0.3, 30)
	_status_label.add_theme_color_override("font_color", Color(1, 0.6, 0))
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.text = ""
	add_child(_status_label)
	
	# ── VERSUS ──
	_versus_label = Label.new()
	_versus_label.position = Vector2(get_viewport().size.x * 0.45, 200)
	_versus_label.size = Vector2(get_viewport().size.x * 0.1, 30)
	_versus_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_versus_label.add_theme_font_size_override("font_size", 16)
	_versus_label.text = "VS"
	_versus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_versus_label)
	
	# ── FIGHTER 1 (Red, top-left) ──
	_build_fighter_panel(0)
	
	# ── FIGHTER 2 (Blue, bottom-right) ──
	_build_fighter_panel(1)

func _build_fighter_panel(fighter_id: int) -> void:
	var is_f1 = fighter_id == 0
	var y_base = 60 if is_f1 else get_viewport().size.y - 100
	var x_base = 20
	
	var color = RED_CORNER if is_f1 else BLUE_CORNER
	
	# Name label
	var name_label = Label.new()
	name_label.position = Vector2(x_base, y_base)
	name_label.size = Vector2(250, 24)
	name_label.add_theme_color_override("font_color", color)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.text = fighter1.fighter_name if is_f1 else fighter2.fighter_name
	add_child(name_label)
	
	# Record
	var rec_label = Label.new()
	rec_label.position = Vector2(x_base, y_base + 22)
	rec_label.size = Vector2(250, 16)
	rec_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	rec_label.add_theme_font_size_override("font_size", 11)
	var fd = fighter1 if is_f1 else fighter2
	rec_label.text = "%d-%d (%d KO)" % [fd.record_wins, fd.record_losses, fd.record_kos]
	add_child(rec_label)
	
	# HP bar background
	var hp_bg = ColorRect.new()
	hp_bg.position = Vector2(x_base, y_base + 40)
	hp_bg.size = Vector2(200, 16)
	hp_bg.color = Color(0.2, 0.2, 0.2)
	add_child(hp_bg)
	
	# HP bar fill
	var hp_bar = ColorRect.new()
	hp_bar.position = Vector2(x_base + 2, y_base + 42)
	hp_bar.size = Vector2(196, 12)
	hp_bar.color = HP_GREEN
	add_child(hp_bar)
	
	# HP label
	var hp_lab = Label.new()
	hp_lab.position = Vector2(x_base + 205, y_base + 40)
	hp_lab.size = Vector2(80, 16)
	hp_lab.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hp_lab.add_theme_font_size_override("font_size", 11)
	hp_lab.text = "HP"
	add_child(hp_lab)
	
	# Stamina bar bg
	var stam_bg = ColorRect.new()
	stam_bg.position = Vector2(x_base, y_base + 58)
	stam_bg.size = Vector2(200, 10)
	stam_bg.color = Color(0.15, 0.15, 0.2)
	add_child(stam_bg)
	
	# Stamina bar fill
	var stam_bar = ColorRect.new()
	stam_bar.position = Vector2(x_base + 2, y_base + 59)
	stam_bar.size = Vector2(196, 8)
	stam_bar.color = STAM_BLUE
	add_child(stam_bar)
	
	# Stamina label
	var stam_lab = Label.new()
	stam_lab.position = Vector2(x_base + 205, y_base + 57)
	stam_lab.size = Vector2(80, 12)
	stam_lab.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	stam_lab.add_theme_font_size_override("font_size", 10)
	stam_lab.text = "STM"
	add_child(stam_lab)
	
	# Store references
	if is_f1:
		_f1_name = name_label
		_f1_record = rec_label
		_f1_hp_bar = hp_bar
		_f1_hp_bg = hp_bg
		_f1_stam_bar = stam_bar
		_f1_stam_bg = stam_bg
	else:
		_f2_name = name_label
		_f2_record = rec_label
		_f2_hp_bar = hp_bar
		_f2_hp_bg = hp_bg
		_f2_stam_bar = stam_bar
		_f2_stam_bg = stam_bg

func _process(delta: float) -> void:
	if not match_manager:
		return
	
	# Timer
	var time_left = match_manager.get_time_remaining()
	var mins = int(time_left) / 60
	var secs = int(time_left) % 60
	_timer_label.text = "%d:%02d" % [mins, secs]
	
	# Round
	_round_label.text = "ROUND %d" % match_manager.get_current_round()
	
	# Fighter 1 bars
	if fighter1:
		var f1_hp = _get_total_health_pct(fighter1)
		var f1_stam = fighter1.get_stamina_pct()
		_update_bar(_f1_hp_bar, f1_hp, _f1_stam_bar, f1_stam)
	
	# Fighter 2 bars
	if fighter2:
		var f2_hp = _get_total_health_pct(fighter2)
		var f2_stam = fighter2.get_stamina_pct()
		_update_bar(_f2_hp_bar, f2_hp, _f2_stam_bar, f2_stam)
	
	# Status
	var status_text = ""
	if fighter1_fsm and fighter1_fsm.is_knocked_out:
		status_text = "KO!"
	elif fighter2_fsm and fighter2_fsm.is_knocked_out:
		status_text = "KO!"
	elif fighter2_fsm and fighter2_fsm.is_stunned:
		var lv = fighter2_fsm.stun_level
		match lv:
			1: status_text = "DAZED"
			2: status_text = "HURT"
			3,4: status_text = "STUNNED"
			5: status_text = "KNOCKDOWN!"
	_status_label.text = status_text

func _update_bar(hp_bar: ColorRect, hp_pct: float, stam_bar: ColorRect, stam_pct: float) -> void:
	if not hp_bar or not stam_bar:
		return
	
	# HP bar
	hp_bar.size.x = max(0, 196.0 * hp_pct)
	if hp_pct > 0.5:
		hp_bar.color = HP_GREEN
	elif hp_pct > 0.25:
		hp_bar.color = HP_YELLOW
	else:
		hp_bar.color = HP_RED
	
	# Stamina bar
	stam_bar.size.x = max(0, 196.0 * stam_pct)
	if stam_pct > 0.3:
		stam_bar.color = STAM_BLUE
	else:
		stam_bar.color = STAM_ORANGE

# Called when viewport resizes
func _on_viewport_size_changed() -> void:
	pass

func _get_total_health_pct(fd) -> float:
	if not fd or not fd.health_pools:
		return 1.0
	var total = 0.0
	var max_total = 0.0
	for zone in fd.health_pools:
		total += fd.health_pools[zone]
		# Match FighterData._max_hp_for_zone formulas
		match zone:
			"head": max_total += 100.0 + (fd.chin * 0.5)
			"torso": max_total += 100.0 + (fd.toughness * 1.0)
			"left_arm", "right_arm": max_total += fd.derived.get("limb_hp", 50.0)
			"left_leg", "right_leg": max_total += fd.derived.get("limb_hp_leg", 60.0)
			_: max_total += 100.0
	return total / max(max_total, 1.0)
