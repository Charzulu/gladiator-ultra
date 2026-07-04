# scripts/fighter/StyleData.gd
# Style definition — animation set references + modifier table + visual config.
# Extends Resource so styles can be authored as .tres files.
extends RefCounted

# Self-reference for internal construction
const _Self = preload("res://scripts/fighter/StyleData.gd")

@export var style_name: String = "generic_mma"
@export var display_name: String = "Generic MMA"
@export var description: String = "A well-rounded fighting style with no particular specialty."

# ── Animation set references ──
@export var anim_set_stand_up: String = ""      # e.g. "res://assets/animations/boxing_stand_up.res"
@export var anim_set_clinch: String = ""         # e.g. "res://assets/animations/boxing_clinch.res"
@export var anim_set_ground_top: String = ""
@export var anim_set_ground_bottom: String = ""
@export var anim_set_submissions: String = ""

# ── Visual config ──
@export var fight_stance_bone_modifier: String = ""  # skeleton modifier name
@export var guard_height: float = 1.0                # 0.0 (low) to 1.0 (high)
@export var stance_width: float = 1.0               # 0.5 (narrow) to 1.5 (wide)
@export var lead_hand_forward: float = 0.5           # how far forward the lead hand sits
@export var head_bob_amount: float = 0.3             # idle head movement amount

# ── Range profile ──
@export var ideal_range_min: float = 1.0    # ideal combat distance (meters)
@export var ideal_range_max: float = 2.5
@export var lunge_distance: float = 1.5     # how far this style lunges on attacks
@export var pivot_speed_mult: float = 1.0

# ─── BUILT-IN STYLES ──
static func get_style_data(style_name: String):
	var catalog = _build_catalog()
	return catalog.get(style_name, catalog["generic_mma"])

static func get_all_styles() -> Array:
	return _build_catalog().values()

static func _build_catalog() -> Dictionary:
	return {
		"boxing": _boxing(),
		"muay_thai": _muay_thai(),
		"wrestling": _wrestling(),
		"bjj": _bjj(),
		"kickboxing": _kickboxing(),
		"sambo": _sambo(),
		"judo": _judo(),
		"karate": _karate(),
		"taekwondo": _taekwondo(),
		"catch_wrestling": _catch_wrestling(),
		"hapkido": _hapkido(),
		"generic_mma": _generic_mma(),
	}

static func _boxing():
	var s = _Self.new()
	s.style_name = "boxing"
	s.display_name = "Boxing"
	s.description = "Classic Western boxing — elite hands, footwork, and head movement. Vulnerable to kicks and takedowns."
	s.guard_height = 0.9; s.stance_width = 0.8; s.lead_hand_forward = 0.6
	s.ideal_range_min = 0.8; s.ideal_range_max = 1.8; s.lunge_distance = 1.8; s.pivot_speed_mult = 1.3
	return s

static func _muay_thai():
	var s = _Self.new()
	s.style_name = "muay_thai"
	s.display_name = "Muay Thai"
	s.description = "The art of eight limbs — punches, kicks, knees, and elbows. Devastating in close range and clinch."
	s.guard_height = 0.95; s.stance_width = 0.9; s.lead_hand_forward = 0.5
	s.ideal_range_min = 0.5; s.ideal_range_max = 1.5; s.lunge_distance = 1.2; s.pivot_speed_mult = 0.8
	return s

static func _wrestling():
	var s = _Self.new()
	s.style_name = "wrestling"
	s.display_name = "Wrestling"
	s.description = "Explosive takedowns, relentless top pressure, and suffocating control. Limited striking arsenal."
	s.guard_height = 0.5; s.stance_width = 1.3; s.lead_hand_forward = 0.3
	s.ideal_range_min = 0.3; s.ideal_range_max = 1.2; s.lunge_distance = 2.2; s.pivot_speed_mult = 1.1
	return s

static func _bjj():
	var s = _Self.new()
	s.style_name = "bjj"
	s.display_name = "Brazilian Jiu-Jitsu"
	s.description = "Dangerous off the back — elite submissions, sweeps, and guard. Weak takedowns and striking."
	s.guard_height = 0.4; s.stance_width = 1.0; s.lead_hand_forward = 0.3
	s.ideal_range_min = 0.5; s.ideal_range_max = 1.5; s.lunge_distance = 1.0; s.pivot_speed_mult = 0.7
	return s

static func _kickboxing():
	var s = _Self.new()
	s.style_name = "kickboxing"
	s.display_name = "Kickboxing"
	s.description = "Devastating kicks and crisp combinations at range. Vulnerable in close quarters and on the ground."
	s.guard_height = 0.85; s.stance_width = 0.8; s.lead_hand_forward = 0.45
	s.ideal_range_min = 1.2; s.ideal_range_max = 2.5; s.lunge_distance = 1.6; s.pivot_speed_mult = 1.1
	return s

static func _sambo():
	var s = _Self.new()
	s.style_name = "sambo"
	s.display_name = "Sambo"
	s.description = "A hybrid of wrestling and submissions — explosive takedowns with finishing ability on the ground."
	s.guard_height = 0.7; s.stance_width = 1.1; s.lead_hand_forward = 0.4
	s.ideal_range_min = 0.5; s.ideal_range_max = 1.8; s.lunge_distance = 1.8; s.pivot_speed_mult = 1.0
	return s

static func _judo():
	var s = _Self.new()
	s.style_name = "judo"
	s.display_name = "Judo"
	s.description = "Master of the clinch throw — devastating trips and tosses from the tie-up. Linear striking."
	s.guard_height = 0.6; s.stance_width = 1.2; s.lead_hand_forward = 0.35
	s.ideal_range_min = 0.3; s.ideal_range_max = 1.0; s.lunge_distance = 1.4; s.pivot_speed_mult = 0.8
	return s

static func _karate():
	var s = _Self.new()
	s.style_name = "karate"
	s.display_name = "Karate"
	s.description = "Blitzing movement, devastating kicks, and exceptional footwork. Vulnerable in the clinch."
	s.guard_height = 0.6; s.stance_width = 0.7; s.lead_hand_forward = 0.35
	s.ideal_range_min = 1.5; s.ideal_range_max = 3.0; s.lunge_distance = 2.0; s.pivot_speed_mult = 1.4
	return s

static func _taekwondo():
	var s = _Self.new()
	s.style_name = "taekwondo"
	s.display_name = "Taekwondo"
	s.description = "The most dynamic kicks in the sport, with elite speed and flexibility. Severe grappling weakness."
	s.guard_height = 0.5; s.stance_width = 0.8; s.lead_hand_forward = 0.3
	s.ideal_range_min = 1.8; s.ideal_range_max = 3.5; s.lunge_distance = 2.2; s.pivot_speed_mult = 1.5
	return s

static func _catch_wrestling():
	var s = _Self.new()
	s.style_name = "catch_wrestling"
	s.display_name = "Catch Wrestling"
	s.description = "A hybrid of wrestling and submission holds — punishing top pressure with submission threats."
	s.guard_height = 0.65; s.stance_width = 1.1; s.lead_hand_forward = 0.4
	s.ideal_range_min = 0.5; s.ideal_range_max = 1.5; s.lunge_distance = 1.6; s.pivot_speed_mult = 0.9
	return s

static func _hapkido():
	var s = _Self.new()
	s.style_name = "hapkido"
	s.display_name = "Hapkido"
	s.description = "A defensive counter-fighting style — joint locks, throws, and exceptional clinch defense."
	s.guard_height = 0.75; s.stance_width = 0.9; s.lead_hand_forward = 0.45
	s.ideal_range_min = 1.0; s.ideal_range_max = 2.2; s.lunge_distance = 1.5; s.pivot_speed_mult = 1.1
	return s

static func _generic_mma():
	var s = _Self.new()
	s.style_name = "generic_mma"
	s.display_name = "MMA"
	s.description = "A well-rounded mixed martial arts base with no extreme strengths or weaknesses."
	s.guard_height = 0.7; s.stance_width = 1.0; s.lead_hand_forward = 0.45
	s.ideal_range_min = 0.8; s.ideal_range_max = 2.0; s.lunge_distance = 1.5; s.pivot_speed_mult = 1.0
	return s
