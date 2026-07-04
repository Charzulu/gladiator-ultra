# scripts/progression/MoveVariantDatabase.gd
# Static registry of all move variants in the game.
# Each base move has 8+ variants: 5 core modifier types + 3+ style-origin variants.
extends RefCounted

const _V = preload("res://scripts/progression/MoveVariantData.gd")

# ── Registry (lazy-loaded) ──
static var _ALL_VARIANTS: Dictionary = {}

static func _get_all() -> Dictionary:
	if _ALL_VARIANTS.is_empty():
		_build_registry()
	return _ALL_VARIANTS

static func get_variant(variant_id: String):
	return _get_all().get(variant_id)

static func get_variants_for_move(move_id: String) -> Array:
	var result: Array = []
	for v in _get_all().values():
		if v.base_move_id == move_id:
			result.append(v)
	return result

static func get_variants_for_move_by_category(move_id: String, category: String) -> Array:
	var result: Array = []
	for v in _get_all().values():
		if v.base_move_id == move_id and v.category == category:
			result.append(v)
	return result

# ── FALLBACK ──
const _DEFAULT_VARIANT_ID = "standard_generic"

static func get_default() -> _V.MoveVariant:
	return _get_all().get(_DEFAULT_VARIANT_ID)

# ── Build registry ──
static func _build_registry() -> void:

	# ────────────────────────────────────────────
	# CORE MODIFIER VARIANTS (generic, 5 per move)
	# ────────────────────────────────────────────
	
	# These use "base" as the move placeholder — they work for ALL strike types.
	# The database defines them once here; code should look up the move-specific version.
	# For simplicity, we define them per-strike below.

	# ────────────────────────────────────────────
	# JAB VARIANTS (8)
	# ────────────────────────────────────────────
	_ALL_VARIANTS["jab_heavy"] = _V.create("jab_heavy", "Heavy Jab", "Telegraphed power jab. Slow wind-up, big impact.", "jab", "core", "generic",
		1.4, 1.2, 1.3, 1.5, 1.6, 1.1, 1.0, 1.3, 0, 0.2, 0, 2, 0, "", 100, {"strength": 40}, 2)
	_ALL_VARIANTS["jab_fast"] = _V.create("jab_fast", "Fast Jab", "Snappy, low-commitment jab. Great for setting up combos.", "jab", "core", "generic",
		0.7, 0.8, 0.7, 0.8, 0.8, 1.0, 1.1, 0.8, 0, 0, 0, -1, -1, "", 100, {"speed": 40}, 2)
	_ALL_VARIANTS["jab_efficient"] = _V.create("jab_efficient", "Efficient Jab", "Minimal movement, low stamina cost. Safe and conservative.", "jab", "core", "generic",
		1.0, 1.0, 0.8, 0.9, 0.6, 0.95, 1.0, 1.0, 0, 0, 0, 0, 0, "", 100, {"endurance": 40}, 2)
	_ALL_VARIANTS["jab_extended"] = _V.create("jab_extended", "Long Jab", "Extra reach through full extension. Vulnerable to counters.", "jab", "core", "generic",
		1.1, 1.3, 1.4, 1.1, 1.3, 1.4, 0.9, 1.0, 0, 0.3, 0, 3, 0, "", 100, {"speed": 40}, 2)
	_ALL_VARIANTS["jab_body"] = _V.create("jab_body", "Body Jab", "Dip and drive to the body. Drains opponent stamina.", "jab", "core", "generic",
		1.1, 0.9, 0.9, 1.0, 1.1, 0.9, 1.0, 1.0, 0, 0, 0, 0, 0, "", 75, {}, 2)
	
	_ALL_VARIANTS["jab_snap_boxing"] = _V.create("jab_snap_boxing", "Snap Jab", "Classic boxing snap jab. Quick return, extra follow-up speed.", "jab", "style", "boxing",
		1.0, 0.9, 0.7, 0.9, 1.0, 1.0, 1.1, 0.9, 0, 0, 0, 0, -2, "", 200, {"boxing": 40}, 3)
	_ALL_VARIANTS["jab_thai"] = _V.create("jab_thai", "Thai Jab", "Heavy-hip Muay Thai jab. Extra guard damage, slight telegraph.", "jab", "style", "muay_thai",
		1.2, 1.0, 1.1, 1.15, 1.1, 1.0, 0.95, 1.4, 0, 0, 0, 1, 0, "", 200, {"muay_thai": 40}, 3)
	_ALL_VARIANTS["jab_karate_snap"] = _V.create("jab_karate_snap", "Snap Punch", "Karate hiki-te snap punch. Very fast recovery, slightly less power.", "jab", "style", "karate",
		0.8, 1.1, 0.6, 0.85, 0.9, 1.15, 1.1, 0.85, 0, 0, 0, -1, -1, "", 200, {"boxing": 35}, 3)

	# ────────────────────────────────────────────
	# CROSS VARIANTS (8)
	# ────────────────────────────────────────────
	_ALL_VARIANTS["cross_heavy"] = _V.create("cross_heavy", "Heavy Cross", "Full hip rotation power cross. Devastating when it lands.", "cross", "core", "generic",
		1.4, 1.2, 1.4, 1.5, 1.6, 1.15, 0.95, 1.3, 0.5, 0.3, 0, 2, 0, "", 100, {"strength": 40}, 2)
	_ALL_VARIANTS["cross_fast"] = _V.create("cross_fast", "Fast Cross", "Quick straight, less hip commitment.", "cross", "core", "generic",
		0.75, 0.8, 0.7, 0.85, 0.85, 1.0, 1.1, 0.85, 0, 0, 0, -1, -1, "", 100, {"speed": 40}, 2)
	_ALL_VARIANTS["cross_efficient"] = _V.create("cross_efficient", "Efficient Cross", "Compact cross with good economy of motion.", "cross", "core", "generic",
		1.0, 1.0, 0.8, 0.9, 0.6, 0.95, 1.0, 1.0, 0, 0, 0, 0, 0, "", 100, {"endurance": 40}, 2)
	_ALL_VARIANTS["cross_extended"] = _V.create("cross_extended", "Step Cross", "Step in with the cross for extra range. Over-commits.", "cross", "core", "generic",
		1.1, 1.3, 1.5, 1.15, 1.3, 1.4, 0.9, 1.0, 0, 0.4, 0, 3, 0, "", 100, {"speed": 40}, 2)
	_ALL_VARIANTS["cross_body"] = _V.create("cross_body", "Body Cross", "Straight to the body. Drains stamina.", "cross", "core", "generic",
		1.1, 0.9, 0.9, 1.1, 1.1, 0.9, 1.0, 1.1, 0, 0, 0, 0, 0, "", 75, {}, 2)
	
	_ALL_VARIANTS["cross_power_boxing"] = _V.create("cross_power_boxing", "Power Cross", "Boxing's signature power punch. Massive rotation, KO threat.", "cross", "style", "boxing",
		1.3, 1.1, 1.2, 1.6, 1.5, 1.1, 0.9, 1.5, 1.0, 0.4, 0, 2, 0, "", 250, {"boxing": 60}, 3)
	_ALL_VARIANTS["cross_reverse_karate"] = _V.create("cross_reverse_karate", "Reverse Punch", "Karate reverse punch with hiki-te pull for extra power.", "cross", "style", "karate",
		1.1, 1.0, 1.0, 1.2, 1.1, 1.05, 1.05, 1.1, 0.5, 0.1, 0, 0, 0, "", 250, {"boxing": 40, "speed": 40}, 3)
	_ALL_VARIANTS["cross_counter"] = _V.create("cross_counter", "Counter Cross", "Lean-back cross designed for countering. Extra counter frames.", "cross", "style", "generic",
		0.9, 1.0, 1.2, 1.2, 1.1, 1.0, 1.2, 1.0, 0.5, 0, 1.0, 0, 0, "", 200, {"head_movement": 40}, 3)

	# ────────────────────────────────────────────
	# HOOK VARIANTS (8)
	# ────────────────────────────────────────────
	_ALL_VARIANTS["hook_heavy"] = _V.create("hook_heavy", "Heavy Hook", "Wide, devastating hook. Slow but fight-ending power.", "hook", "core", "generic",
		1.4, 1.2, 1.4, 1.5, 1.6, 1.1, 0.95, 1.2, 1.0, 0.3, 0, 2, 0, "", 100, {"strength": 40}, 2)
	_ALL_VARIANTS["hook_fast"] = _V.create("hook_fast", "Fast Hook", "Compact hook, less rotation. Quick recovery.", "hook", "core", "generic",
		0.75, 0.8, 0.7, 0.8, 0.85, 0.95, 1.1, 0.85, 0, 0, 0, -1, -1, "", 100, {"speed": 40}, 2)
	_ALL_VARIANTS["hook_efficient"] = _V.create("hook_efficient", "Efficient Hook", "Conservative hook. Low power but minimal stamina cost.", "hook", "core", "generic",
		1.0, 1.0, 0.8, 0.85, 0.6, 1.0, 1.0, 1.0, 0, 0, 0, 0, 0, "", 100, {"endurance": 40}, 2)
	_ALL_VARIANTS["hook_extended"] = _V.create("hook_extended", "Wide Hook", "Extended arc, catches opponents at max range. Very counterable.", "hook", "core", "generic",
		1.2, 1.3, 1.5, 1.15, 1.4, 1.4, 0.85, 1.0, 0.5, 0.3, 0, 4, 0, "", 100, {"speed": 40}, 2)
	_ALL_VARIANTS["hook_body"] = _V.create("hook_body", "Body Hook", "Liver shot. Devastating to the body, drains stamina fast.", "hook", "core", "generic",
		1.15, 0.9, 1.0, 1.2, 1.15, 0.85, 1.0, 1.2, 0, 0, 0, 0, 0, "", 100, {"strength": 30}, 2)
	
	_ALL_VARIANTS["hook_check_boxing"] = _V.create("hook_check_boxing", "Check Hook", "Step-back hook. Evasive counter that creates distance.", "hook", "style", "boxing",
		0.8, 1.0, 1.2, 0.85, 1.2, 1.1, 1.15, 0.8, 0, 0.5, 0, 0, 0, "", 200, {"boxing": 40, "head_movement": 40}, 3)
	_ALL_VARIANTS["hook_overhand"] = _V.create("hook_overhand", "Overhand", "Loopy overhand punch. Comes over the guard, huge KO potential.", "hook", "style", "generic",
		1.3, 1.2, 1.5, 1.6, 1.7, 1.1, 0.8, 1.6, 1.5, 0.3, 0, 3, 0, "", 300, {"strength": 50, "boxing": 50}, 4)
	_ALL_VARIANTS["hook_lead_uppercut"] = _V.create("hook_lead_uppercut", "Lead Uppercut", "Uppercut from the lead hand. Tight, close-range, surprises opponent.", "hook", "style", "generic",
		1.1, 0.8, 1.0, 1.2, 1.1, 0.7, 1.15, 1.0, 0.5, 0, 0, 0, 0, "", 200, {"boxing": 40}, 3)

	# ────────────────────────────────────────────
	# UPPERCUT VARIANTS (8)
	# ────────────────────────────────────────────
	_ALL_VARIANTS["uppercut_heavy"] = _V.create("uppercut_heavy", "Heavy Uppercut", "Driving uppercut from the legs. Massive power.", "uppercut", "core", "generic",
		1.4, 1.2, 1.3, 1.5, 1.6, 1.0, 0.95, 1.3, 1.0, 0.2, 0, 2, 0, "", 100, {"strength": 40}, 2)
	_ALL_VARIANTS["uppercut_fast"] = _V.create("uppercut_fast", "Snap Uppercut", "Quick rising uppercut. Less power, short recovery.", "uppercut", "core", "generic",
		0.7, 0.8, 0.7, 0.8, 0.8, 0.95, 1.1, 0.8, 0, 0, 0, -1, -1, "", 100, {"speed": 40}, 2)
	_ALL_VARIANTS["uppercut_efficient"] = _V.create("uppercut_efficient", "Compact Uppercut", "Short, economical uppercut.", "uppercut", "core", "generic",
		1.0, 1.0, 0.8, 0.9, 0.6, 0.95, 1.0, 1.0, 0, 0, 0, 0, 0, "", 100, {"endurance": 40}, 2)
	_ALL_VARIANTS["uppercut_extended"] = _V.create("uppercut_extended", "Long Uppercut", "Reaching uppercut from further out. Telegraphs.", "uppercut", "core", "generic",
		1.2, 1.2, 1.4, 1.1, 1.3, 1.3, 0.9, 1.0, 0.5, 0.3, 0, 3, 0, "", 100, {"speed": 40}, 2)
	_ALL_VARIANTS["uppercut_body"] = _V.create("uppercut_body", "Body Uppercut", "Uppercut to the solar plexus. Wind-crushing.", "uppercut", "core", "generic",
		1.1, 0.9, 0.9, 1.1, 1.1, 0.85, 1.0, 1.2, 0, 0, 0, 0, 0, "", 75, {}, 2)
	
	_ALL_VARIANTS["uppercut_muay_thai"] = _V.create("uppercut_muay_thai", "Thai Uppercut", "Muay Thai uppercut with clinch setup subtext. Extra cut chance.", "uppercut", "style", "muay_thai",
		1.15, 1.0, 1.1, 1.15, 1.1, 0.9, 0.95, 1.1, 0.5, 0, 0.05, 1, 0, "", 200, {"muay_thai": 40}, 3)
	_ALL_VARIANTS["uppercut_dirty_boxing"] = _V.create("uppercut_dirty_boxing", "Dirty Uppercut", "Inside uppercut from clinch range. Short, vicious.", "uppercut", "style", "boxing",
		0.9, 0.8, 0.9, 1.1, 1.0, 0.75, 1.1, 1.1, 0.5, 0, 0, 0, 0, "", 200, {"boxing": 40, "clinch_offense": 30}, 3)
	_ALL_VARIANTS["uppercut_karate"] = _V.create("uppercut_karate", "Ridge Hand", "Karate ridge hand strike. Unorthodox angle, cuts often.", "uppercut", "style", "karate",
		1.2, 0.9, 1.0, 1.0, 1.0, 1.1, 0.9, 1.0, 0, 0, 0.08, 1, 0, "", 250, {"kickboxing": 40}, 3)

	# ────────────────────────────────────────────
	# FRONT KICK VARIANTS (8)
	# ────────────────────────────────────────────
	_ALL_VARIANTS["front_kick_heavy"] = _V.create("front_kick_heavy", "Power Teep", "Stamping front kick with full hip drive.", "front_kick", "core", "generic",
		1.3, 1.2, 1.3, 1.4, 1.5, 1.1, 0.95, 1.2, 0, 0.6, 0, 2, 0, "", 100, {"strength": 35}, 2)
	_ALL_VARIANTS["front_kick_fast"] = _V.create("front_kick_fast", "Snap Kick", "Quick snap front kick. Range finder.", "front_kick", "core", "generic",
		0.7, 0.8, 0.7, 0.75, 0.8, 0.95, 1.15, 0.85, 0, 0, 0, -1, -1, "", 100, {"speed": 40}, 2)
	_ALL_VARIANTS["front_kick_efficient"] = _V.create("front_kick_efficient", "Economy Teep", "Minimal hip commitment teep. Safe, conservative.", "front_kick", "core", "generic",
		1.0, 1.0, 0.8, 0.85, 0.6, 0.95, 1.0, 1.0, 0, 0.3, 0, 0, 0, "", 100, {"endurance": 40}, 2)
	_ALL_VARIANTS["front_kick_extended"] = _V.create("front_kick_extended", "Long Teep", "Deep step-in front kick. Maximum distance.", "front_kick", "core", "generic",
		1.2, 1.3, 1.4, 1.1, 1.4, 1.4, 0.9, 1.0, 0, 0.8, 0, 3, 0, "", 100, {"speed": 40}, 2)
	
	_ALL_VARIANTS["front_kick_teep_mt"] = _V.create("front_kick_teep_mt", "Muay Thai Teep", "Classic Muay Thai teep. Powerful push, sets up the roundhouse.", "front_kick", "style", "muay_thai",
		1.1, 1.0, 1.0, 1.1, 1.0, 1.1, 1.0, 1.2, 0, 0.8, 0, 0, 0, "", 200, {"muay_thai": 40}, 3)
	_ALL_VARIANTS["front_kick_karate"] = _V.create("front_kick_karate", "Front Snap", "Karate front snap kick. Chambered, very fast return.", "front_kick", "style", "karate",
		0.7, 0.9, 0.7, 0.8, 0.9, 1.0, 1.15, 0.8, 0, 0.1, 0, -1, -1, "", 200, {"kickboxing": 40}, 3)
	_ALL_VARIANTS["front_kick_push"] = _V.create("front_kick_push", "Push Kick", "Bladed front kick. Maximum push, minimal damage.", "front_kick", "style", "generic",
		1.2, 1.1, 1.0, 0.7, 1.2, 1.1, 0.95, 0.8, 0, 1.2, 0, 1, 0, "", 150, {"kickboxing": 35}, 2)
	_ALL_VARIANTS["front_kick_step"] = _V.create("front_kick_step", "Step Teep", "Switch step into teep. Unpredictable timing.", "front_kick", "style", "generic",
		1.1, 1.0, 1.1, 1.0, 1.1, 1.0, 1.05, 1.0, 0, 0.5, 0, 0, 0, "", 200, {"kickboxing": 40}, 3)

	# ────────────────────────────────────────────
	# ROUNDHOUSE VARIANTS (8)
	# ────────────────────────────────────────────
	_ALL_VARIANTS["roundhouse_heavy"] = _V.create("roundhouse_heavy", "Heavy Roundhouse", "Full hip rotation. Devastating to body and legs.", "roundhouse", "core", "generic",
		1.4, 1.2, 1.4, 1.5, 1.7, 1.1, 0.95, 1.3, 1.0, 0.3, 0, 2, 0, "", 100, {"strength": 40}, 2)
	_ALL_VARIANTS["roundhouse_fast"] = _V.create("roundhouse_fast", "Quick Roundhouse", "Compact roundhouse, less rotation.", "roundhouse", "core", "generic",
		0.75, 0.8, 0.75, 0.8, 0.85, 0.95, 1.1, 0.85, 0, 0, 0, -1, -1, "", 100, {"speed": 40}, 2)
	_ALL_VARIANTS["roundhouse_efficient"] = _V.create("roundhouse_efficient", "Economy Roundhouse", "Minimal wind-up roundhouse. Saves stamina.", "roundhouse", "core", "generic",
		1.0, 1.0, 0.8, 0.85, 0.6, 0.95, 1.0, 1.0, 0, 0, 0, 0, 0, "", 100, {"endurance": 40}, 2)
	_ALL_VARIANTS["roundhouse_extended"] = _V.create("roundhouse_extended", "Long Roundhouse", "Deep step and extended arc. Maximum reach.", "roundhouse", "core", "generic",
		1.2, 1.3, 1.5, 1.1, 1.4, 1.4, 0.85, 1.0, 0.5, 0.3, 0, 3, 0, "", 100, {"speed": 40}, 2)
	
	_ALL_VARIANTS["roundhouse_thai"] = _V.create("roundhouse_thai", "Thai Roundhouse", "Full hip rotation Thai kick. Crushing to the body.", "roundhouse", "style", "muay_thai",
		1.2, 1.1, 1.2, 1.3, 1.2, 1.05, 0.95, 1.4, 1.0, 0.3, 0, 1, 0, "", 250, {"muay_thai": 60, "kickboxing": 40}, 3)
	_ALL_VARIANTS["roundhouse_lead_leg"] = _V.create("roundhouse_lead_leg", "Lead Roundhouse", "Roundhouse from the lead leg. Faster, less power, unpredictable.", "roundhouse", "style", "generic",
		0.8, 0.9, 0.9, 0.8, 1.0, 0.9, 1.15, 0.9, 0, 0, 0, -1, 0, "", 250, {"kickboxing": 50}, 3)
	_ALL_VARIANTS["roundhouse_switch"] = _V.create("roundhouse_switch", "Switch Kick", "Switch stance into roundhouse. Confusing timing, extra power.", "roundhouse", "style", "generic",
		1.3, 1.0, 1.2, 1.2, 1.3, 1.1, 0.9, 1.1, 0.5, 0.2, 0, 2, 0, "", 300, {"kickboxing": 50, "speed": 40}, 4)
	_ALL_VARIANTS["roundhouse_karate"] = _V.create("roundhouse_karate", "Karate Roundhouse", "Chambered roundhouse. Snaps at the apex, fast return.", "roundhouse", "style", "karate",
		0.9, 1.0, 0.8, 0.9, 0.9, 1.1, 1.1, 0.85, 0, 0, 0, 0, -1, "", 200, {"kickboxing": 40}, 3)

	# ────────────────────────────────────────────
	# LEG KICK VARIANTS (8)
	# ────────────────────────────────────────────
	_ALL_VARIANTS["leg_kick_heavy"] = _V.create("leg_kick_heavy", "Heavy Leg Kick", "Crashing low kick. Checks hurt.", "leg_kick", "core", "generic",
		1.3, 1.2, 1.2, 1.5, 1.5, 1.1, 0.95, 1.2, 0, 0.1, 0, 2, 0, "", 100, {"strength": 35}, 2)
	_ALL_VARIANTS["leg_kick_fast"] = _V.create("leg_kick_fast", "Quick Low Kick", "Snapping low kick. Hard to see coming.", "leg_kick", "core", "generic",
		0.7, 0.8, 0.7, 0.75, 0.8, 0.95, 1.15, 0.85, 0, 0, 0, -1, -1, "", 100, {"speed": 40}, 2)
	_ALL_VARIANTS["leg_kick_efficient"] = _V.create("leg_kick_efficient", "Economy Low Kick", "Light low kick. Accumulates damage over time.", "leg_kick", "core", "generic",
		1.0, 1.0, 0.8, 0.85, 0.6, 0.95, 1.0, 1.0, 0, 0, 0, 0, 0, "", 100, {"endurance": 40}, 2)
	_ALL_VARIANTS["leg_kick_extended"] = _V.create("leg_kick_extended", "Long Low Kick", "Reaching low kick from distance. Telegraphs.", "leg_kick", "core", "generic",
		1.2, 1.2, 1.3, 1.1, 1.3, 1.4, 0.9, 1.0, 0, 0.15, 0, 3, 0, "", 100, {"speed": 40}, 2)
	
	_ALL_VARIANTS["leg_kick_thai"] = _V.create("leg_kick_thai", "Thai Low Kick", "Muay Thai low kick with full hip. Checks shatter.", "leg_kick", "style", "muay_thai",
		1.15, 1.1, 1.15, 1.3, 1.2, 1.1, 0.95, 1.5, 0.5, 0.15, 0, 1, 0, "", 200, {"muay_thai": 40}, 3)
	_ALL_VARIANTS["leg_kick_calf"] = _V.create("leg_kick_calf", "Calf Kick", "Low line calf kick. Affects opponent's movement immediately.", "leg_kick", "style", "generic",
		1.1, 1.0, 1.0, 0.9, 1.0, 0.9, 1.05, 0.9, 0, 0, 0, 1, 0, "", 200, {"kickboxing": 40}, 3)
	_ALL_VARIANTS["leg_kick_switch"] = _V.create("leg_kick_switch", "Switch Low Kick", "Switch stance into low kick. Unexpected angle.", "leg_kick", "style", "generic",
		1.2, 1.0, 1.1, 1.1, 1.2, 1.0, 1.1, 1.0, 0, 0.1, 0, 1, 0, "", 250, {"kickboxing": 45}, 3)
	_ALL_VARIANTS["leg_kick_karate"] = _V.create("leg_kick_karate", "Karate Low Kick", "Chambered low kick from karate stance. Fast, precise.", "leg_kick", "style", "karate",
		0.85, 0.9, 0.8, 0.85, 0.9, 1.05, 1.1, 0.85, 0, 0, 0, -1, 0, "", 200, {"kickboxing": 35}, 3)

	# ────────────────────────────────────────────
	# HEAD KICK VARIANTS (8)
	# ────────────────────────────────────────────
	_ALL_VARIANTS["head_kick_heavy"] = _V.create("head_kick_heavy", "High Crush", "High kick with full body weight. Fight-ending power.", "head_kick", "core", "generic",
		1.4, 1.2, 1.5, 1.5, 1.8, 1.1, 0.9, 1.3, 1.5, 0.3, 0, 3, 0, "", 100, {"strength": 40, "speed": 40}, 2)
	_ALL_VARIANTS["head_kick_fast"] = _V.create("head_kick_fast", "Quick High Kick", "Snapping high kick. Less power, shorter recovery.", "head_kick", "core", "generic",
		0.75, 0.8, 0.8, 0.8, 0.9, 0.95, 1.1, 0.85, 0, 0, 0, -1, 0, "", 100, {"speed": 50}, 2)
	_ALL_VARIANTS["head_kick_efficient"] = _V.create("head_kick_efficient", "Economy High Kick", "Conservative high kick. Saves stamina, sacrifices power.", "head_kick", "core", "generic",
		1.0, 1.0, 0.9, 0.85, 0.65, 0.95, 1.0, 1.0, 0, 0, 0, 0, 0, "", 100, {"endurance": 45}, 2)
	
	_ALL_VARIANTS["head_kick_question_mark"] = _V.create("head_kick_question_mark", "Question Mark Kick", "Fakes body, goes high. Extremely deceptive, slow start.", "head_kick", "style", "generic",
		1.5, 1.0, 1.5, 1.2, 1.8, 1.0, 0.8, 1.2, 2.0, 0.2, 0, 3, 0, "", 500, {"kickboxing": 70, "speed": 60}, 5)
	_ALL_VARIANTS["head_kick_axe"] = _V.create("head_kick_axe", "Axe Kick", "Vertical axe kick. Chopping motion, devastating when it lands.", "head_kick", "style", "generic",
		1.6, 1.0, 1.5, 1.3, 1.7, 1.0, 0.75, 1.5, 2.0, 0, 0, 3, 0, "", 450, {"kickboxing": 65}, 5)
	_ALL_VARIANTS["head_kick_wheel"] = _V.create("head_kick_wheel", "Wheel Kick", "Spinning wheel kick. 360° of destruction, very telegraphed.", "head_kick", "style", "generic",
		1.8, 1.2, 1.8, 1.6, 2.0, 1.2, 0.7, 1.8, 2.5, 0.4, 0, 5, 0, "", 500, {"kickboxing": 70, "speed": 65}, 5)
	_ALL_VARIANTS["head_kick_step_up"] = _V.create("head_kick_step_up", "Step-Up High Kick", "Step forward into high kick. Gains range, loses some power.", "head_kick", "style", "generic",
		1.2, 1.1, 1.3, 1.1, 1.3, 1.3, 0.9, 1.0, 1.0, 0.3, 0, 2, 0, "", 300, {"kickboxing": 50}, 4)
	_ALL_VARIANTS["head_kick_southpaw"] = _V.create("head_kick_southpaw", "Southpaw High Kick", "Lead high kick from southpaw. Unusual angle catches orthodox fighters.", "head_kick", "style", "generic",
		1.1, 1.0, 1.1, 1.1, 1.1, 1.0, 1.1, 1.1, 0.5, 0, 0, 1, 0, "", 300, {"kickboxing": 50, "footwork": 40}, 4)

	# ────────────────────────────────────────────
	# KNEE VARIANTS (8)
	# ────────────────────────────────────────────
	_ALL_VARIANTS["knee_heavy"] = _V.create("knee_heavy", "Driving Knee", "Explosive knee with full hip drive. Devastating in the clinch.", "knee", "core", "generic",
		1.3, 1.2, 1.3, 1.5, 1.6, 1.0, 0.95, 1.3, 1.5, 0.3, 0, 2, 0, "", 100, {"strength": 40}, 2)
	_ALL_VARIANTS["knee_fast"] = _V.create("knee_fast", "Snap Knee", "Quick snapping knee. Less power, fast return.", "knee", "core", "generic",
		0.7, 0.8, 0.7, 0.8, 0.8, 0.95, 1.1, 0.85, 0, 0, 0, -1, -1, "", 100, {"speed": 40}, 2)
	_ALL_VARIANTS["knee_efficient"] = _V.create("knee_efficient", "Conservative Knee", "Short knee. Saves stamina at close range.", "knee", "core", "generic",
		1.0, 1.0, 0.8, 0.9, 0.6, 0.95, 1.0, 1.0, 0, 0, 0, 0, 0, "", 100, {"endurance": 40}, 2)
	_ALL_VARIANTS["knee_extended"] = _V.create("knee_extended", "Leaping Knee", "Jumping knee from range. Surprising distance, huge stamina cost.", "knee", "core", "generic",
		1.3, 1.3, 1.5, 1.2, 1.8, 1.5, 0.85, 1.1, 1.0, 0.5, 0, 4, 0, "", 150, {"speed": 50}, 2)
	
	_ALL_VARIANTS["knee_thai_clinch"] = _V.create("knee_thai_clinch", "Thai Clinch Knee", "Double-collar tie knee. Extra damage from clinch control.", "knee", "style", "muay_thai",
		1.1, 1.0, 1.0, 1.25, 1.1, 1.0, 1.05, 1.3, 1.0, 0, 0, 1, 0, "", 200, {"muay_thai": 40, "clinch_offense": 40}, 3)
	_ALL_VARIANTS["knee_body_lock"] = _V.create("knee_body_lock", "Body Lock Knee", "Knee from body lock. Less range, harder to escape.", "knee", "style", "generic",
		1.1, 1.1, 1.0, 1.1, 1.1, 0.85, 1.0, 1.2, 0.5, 0, 0, 1, 0, "", 200, {"clinch_offense": 40}, 3)
	_ALL_VARIANTS["knee_jumping"] = _V.create("knee_jumping", "Flying Knee", "Leaping knee from open range. High risk, fight-ending potential.", "knee", "style", "generic",
		1.5, 1.2, 1.8, 1.6, 2.0, 1.6, 0.7, 1.5, 2.0, 0.5, 0, 5, 0, "", 400, {"speed": 60, "muay_thai": 50}, 5)
	_ALL_VARIANTS["knee_switch"] = _V.create("knee_switch", "Switch Knee", "Switch stance step into knee. Unpredictable timing.", "knee", "style", "generic",
		1.15, 1.0, 1.1, 1.1, 1.2, 1.1, 1.05, 1.0, 0.5, 0, 0, 1, 0, "", 250, {"muay_thai": 45, "speed": 45}, 3)

# ── Get variant count ──
static func get_variant_count() -> int:
	return _ALL_VARIANTS.size()

# ── Get X per strike ──
static func get_variant_count_for_move(move_id: String) -> int:
	return get_variants_for_move(move_id).size()
