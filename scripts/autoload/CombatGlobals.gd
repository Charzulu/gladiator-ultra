# scripts/autoload/CombatGlobals.gd
# Singleton autoload — holds runtime-global combat constants, easing curves, lookup tables.
# No class_name — registered as autoload in project.godot.
extends Node

# ── Weight class table ──
enum WeightClass {
	STRAW = 0,
	FLY,
	BANTAM,
	FEATHER,
	LIGHT,
	WELTER,
	MIDDLE,
	LHW,
	HW,
}

const WEIGHT_CLASS_NAMES: Dictionary = {
	WeightClass.STRAW: "Strawweight",
	WeightClass.FLY: "Flyweight",
	WeightClass.BANTAM: "Bantamweight",
	WeightClass.FEATHER: "Featherweight",
	WeightClass.LIGHT: "Lightweight",
	WeightClass.WELTER: "Welterweight",
	WeightClass.MIDDLE: "Middleweight",
	WeightClass.LHW: "Light Heavyweight",
	WeightClass.HW: "Heavyweight",
}

# ── Stance ──
enum Stance { ORTHODOX = 0, SOUTHPAW, SWITCH }

# ── Fight state ──
enum FightState { STAND_UP, CLINCH, GROUND_TOP, GROUND_BOTTOM, SUBMISSION_TOP, SUBMISSION_BOTTOM, KO, TKO, SUBMISSION_LOSS, DECISION }

# ── Body zones ──
enum BodyZone { HEAD, TORSO, LEFT_ARM, RIGHT_ARM, LEFT_LEG, RIGHT_LEG }

const BODY_ZONE_NAMES: Dictionary = {
	BodyZone.HEAD: "head",
	BodyZone.TORSO: "torso",
	BodyZone.LEFT_ARM: "left_arm",
	BodyZone.RIGHT_ARM: "right_arm",
	BodyZone.LEFT_LEG: "left_leg",
	BodyZone.RIGHT_LEG: "right_leg",
}

# ── Damage types ──
enum DamageType { BLUNT, SHARP, SUBMISSION, ACCUMULATED }

# ── Ground positions ──
enum GroundPosition {
	OPEN_GUARD = 0,
	HALF_GUARD,
	SIDE_CONTROL,
	MOUNT,
	BACK_MOUNT,
	KNEE_ON_BELLY,
	SCRAMBLE,
	BUTTERFLY_GUARD,
	RUBBER_GUARD,
	X_GUARD,
	NORTH_SOUTH,
	CRUCIFIX,
}

# ── Strike types ──
enum StrikeType { JAB, CROSS, HOOK, UPPERCUT, ROUNDHOUSE, FRONT_KICK, LEG_KICK, HEAD_KICK, KNEE, ELBOW, FRONT_KICK_BODY, SWITCH_KICK }

# ── Derived stat formula ──
static func formula_punch_base_dmg(strength: float) -> float:
	return 5.0 + (strength * 0.12)

static func formula_kick_base_dmg(strength: float) -> float:
	return 8.0 + (strength * 0.10)

static func formula_strike_speed_mult(speed: float) -> float:
	return 1.8 - (speed * 0.012)

static func formula_stamina_drain(endurance: float) -> float:
	return 1.6 - (endurance * 0.011)

static func formula_max_stamina(endurance: float) -> float:
	return 100.0 + (endurance * 0.5)

static func formula_ko_threshold(toughness: float) -> float:
	return 30.0 + (toughness * 0.7)

# ── Easing curves converted to Godot-friendly lookup──
# Stamina cost per action type
const STAMINA_COST: Dictionary = {
	"jab": 2.0,
	"cross": 3.5,
	"hook": 4.0,
	"uppercut": 4.0,
	"front_kick": 3.0,
	"roundhouse": 5.5,
	"leg_kick": 3.5,
	"head_kick": 7.0,
	"knee_clinch": 3.0,
	"elbow_clinch": 3.5,
	"takedown_shot": 8.0,
	"sprawl": 4.0,
	"clinch_entry": 4.0,
	"clinch_pummel": 2.0,
	"guard_pass": 6.0,
	"sweep": 5.0,
	"sub_attempt_lock": 3.0,
	"sub_defense_lock": 2.0,
	"ground_strike": 2.0,
	"block_per_strike": 1.5,
	"head_movement": 1.0,
	"lunge": 2.5,
}
