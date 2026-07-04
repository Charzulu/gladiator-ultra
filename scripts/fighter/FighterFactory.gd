# scripts/fighter/FighterFactory.gd
# Static factory methods that create FighterData instances from config dictionaries.
# Each fighter is defined inline so they're version-controlled and editable without .tres files.
# Use: var fighter = FighterFactory.create("ivan_drakov")
extends RefCounted

const _FighterData = preload("res://scripts/fighter/FighterData.gd")

# ── Create by ID ──
static func create(fighter_id: String):
	var factories = get_factories()
	if factories.has(fighter_id):
		return factories[fighter_id].call()
	push_error("FighterFactory: unknown fighter_id '%s'" % fighter_id)
	return null

# ── Create all fighters in an array ──
static func create_all() -> Array:
	var result = []
	for fid in get_factories().keys():
		var f = create(fid)
		if f: result.append(f)
	return result

# ── Factory registry ──
static func get_factories() -> Dictionary:
	return {
		"ivan_drakov": _build_ivan_drakov,
		"kenji_takeshi": _build_kenji_takeshi,
		"damien_cruz": _build_damien_cruz,
		"marcus_steele": _build_marcus_steele,
		"hiro_tanaka": _build_hiro_tanaka,
		"luciana_santos": _build_luciana_santos,
	}

# ────────────────────────────────────────────
# FIGHTER DEFINITIONS
# ────────────────────────────────────────────

# Heavyweight Power Puncher — Boxing style, devastating KO power, limited cardio
static func _build_ivan_drakov():
	var f = _FighterData.new()
	f.fighter_name = "Ivan Drakov"
	f.nickname = "The Hammer"
	f.weight_class = 8  # HW
	f.nationality = "Russia"
	f.age = 28
	f.reach_inches = 78.0
	f.height_ft = 6
	f.height_in = 4
	f.stance = 0  # orthodox
	f.strength = 92; f.speed = 38; f.endurance = 55; f.toughness = 85
	f.boxing = 82; f.kickboxing = 35; f.muay_thai = 25; f.head_movement = 38; f.footwork = 35
	f.clinch_offense = 45; f.clinch_defense = 50; f.clinch_takedown = 15
	f.td_offense = 25; f.td_defense = 60; f.counter_td = 20; f.cage_wrestling = 30
	f.top_control = 35; f.bottom_control = 15; f.guard_pass = 20; f.guard_retention = 25
	f.sub_offense = 10; f.sub_defense = 20; f.sub_awareness = 15
	f.chin = 88; f.cut_resistance = 65; f.swell_resistance = 70; f.bleed_resistance = 60
	f.limb_health = 75; f.injury_recovery = 55
	f.max_stamina_rating = 45; f.drain_rate_rating = 40; f.recovery_rate_rating = 40
	f.gassed_threshold_rating = 35; f.cardio_drop_rating = 30
	f.record_wins = 18; f.record_losses = 2; f.record_kos = 16
	f.primary_style = "boxing"
	f.strike_xp = {"jab": 450, "cross": 600, "hook": 400, "uppercut": 150}
	f.strike_prestige = {"jab": 2, "cross": 3, "hook": 1}
	f.owned_variants = ["standard_generic", "jab_heavy", "cross_heavy", "cross_power_boxing", "jab_snap_boxing", "hook_check_boxing", "hook_heavy", "cross_fast"]
	f.equipped_variants = {"jab": "jab_heavy", "cross": "cross_power_boxing", "hook": "hook_check_boxing", "uppercut": "uppercut_heavy", "front_kick": "standard_generic", "roundhouse": "standard_generic", "leg_kick": "standard_generic", "head_kick": "standard_generic", "knee": "standard_generic", "elbow": "standard_generic"}
	f.build_stats()
	return f

# Lightweight Grappler — Wrestling+Judo hybrid, suffocating top game, sub defense
static func _build_kenji_takeshi():
	var f = _FighterData.new()
	f.fighter_name = "Kenji Takeshi"
	f.nickname = "The Octopus"
	f.weight_class = 4  # LW
	f.nationality = "Japan"
	f.age = 26
	f.reach_inches = 70.0
	f.height_ft = 5
	f.height_in = 9
	f.stance = 0
	f.strength = 60; f.speed = 72; f.endurance = 82; f.toughness = 65
	f.boxing = 45; f.kickboxing = 30; f.muay_thai = 45; f.head_movement = 50; f.footwork = 55
	f.clinch_offense = 78; f.clinch_defense = 72; f.clinch_takedown = 85
	f.td_offense = 88; f.td_defense = 68; f.counter_td = 55; f.cage_wrestling = 65
	f.top_control = 82; f.bottom_control = 72; f.guard_pass = 68; f.guard_retention = 78
	f.sub_offense = 72; f.sub_defense = 80; f.sub_awareness = 68
	f.chin = 60; f.cut_resistance = 50; f.swell_resistance = 45; f.bleed_resistance = 55
	f.limb_health = 65; f.injury_recovery = 70
	f.max_stamina_rating = 85; f.drain_rate_rating = 90; f.recovery_rate_rating = 88
	f.gassed_threshold_rating = 85; f.cardio_drop_rating = 90
	f.record_wins = 14; f.record_losses = 3; f.record_subs = 9; f.record_decisions = 5
	f.primary_style = "wrestling"
	f.strike_xp = {"jab": 250, "cross": 150, "hook": 100, "td_offense": 900, "clinch_takedown": 700, "sub_offense": 600}
	f.strike_prestige = {"td_offense": 3, "clinch_takedown": 2, "sub_offense": 2, "jab": 1}
	f.owned_variants = ["standard_generic", "jab_efficient", "cross_efficient", "td_blast_double", "td_reactive_single", "knee_efficient", "sub_kimura"]
	f.equipped_variants = {"jab": "jab_efficient", "cross": "cross_efficient", "hook": "standard_generic", "uppercut": "standard_generic", "front_kick": "standard_generic", "roundhouse": "standard_generic", "leg_kick": "standard_generic", "head_kick": "standard_generic", "knee": "knee_efficient", "elbow": "standard_generic"}
	f.build_stats()
	return f

# Welterweight Striker — Karate style, elite footwork, exceptional kicks, suspect TDD
static func _build_damien_cruz():
	var f = _FighterData.new()
	f.fighter_name = "Damien Cruz"
	f.nickname = "The Phantom"
	f.weight_class = 5  # WW
	f.nationality = "Brazil"
	f.age = 30
	f.reach_inches = 74.0
	f.height_ft = 6
	f.height_in = 0
	f.stance = 1  # southpaw
	f.strength = 68; f.speed = 88; f.endurance = 72; f.toughness = 58
	f.boxing = 62; f.kickboxing = 92; f.muay_thai = 75; f.head_movement = 68; f.footwork = 92
	f.clinch_offense = 50; f.clinch_defense = 58; f.clinch_takedown = 35
	f.td_offense = 30; f.td_defense = 62; f.counter_td = 72; f.cage_wrestling = 35
	f.top_control = 25; f.bottom_control = 30; f.guard_pass = 22; f.guard_retention = 28
	f.sub_offense = 18; f.sub_defense = 28; f.sub_awareness = 32
	f.chin = 52; f.cut_resistance = 55; f.swell_resistance = 42; f.bleed_resistance = 50
	f.limb_health = 48; f.injury_recovery = 62
	f.max_stamina_rating = 75; f.drain_rate_rating = 80; f.recovery_rate_rating = 78
	f.gassed_threshold_rating = 72; f.cardio_drop_rating = 75
	f.record_wins = 22; f.record_losses = 4; f.record_kos = 11; f.record_decisions = 11
	f.primary_style = "karate"
	f.strike_xp = {"front_kick": 800, "roundhouse": 700, "cross": 500, "head_kick": 400, "jab": 350, "hook": 200}
	f.strike_prestige = {"front_kick": 4, "roundhouse": 3, "cross": 2, "head_kick": 1, "jab": 1}
	f.owned_variants = ["standard_generic", "front_kick_karate", "roundhouse_karate", "cross_reverse_karate", "jab_karate_snap", "head_kick_fast", "front_kick_fast", "leg_kick_karate"]
	f.equipped_variants = {"jab": "jab_karate_snap", "cross": "cross_reverse_karate", "hook": "hook_fast", "uppercut": "uppercut_fast", "front_kick": "front_kick_karate", "roundhouse": "roundhouse_karate", "leg_kick": "leg_kick_karate", "head_kick": "head_kick_fast", "knee": "standard_generic", "elbow": "standard_generic"}
	f.build_stats()
	return f

# Middleweight Balanced — MMA style, well-rounded, no elite skill, no critical weakness
static func _build_marcus_steele():
	var f = _FighterData.new()
	f.fighter_name = "Marcus Steele"
	f.nickname = "The All-Around"
	f.weight_class = 6  # MW
	f.nationality = "USA"
	f.age = 29
	f.reach_inches = 73.0
	f.height_ft = 5
	f.height_in = 11
	f.stance = 0
	f.strength = 65; f.speed = 68; f.endurance = 72; f.toughness = 62
	f.boxing = 65; f.kickboxing = 60; f.muay_thai = 55; f.head_movement = 58; f.footwork = 62
	f.clinch_offense = 58; f.clinch_defense = 60; f.clinch_takedown = 55
	f.td_offense = 60; f.td_defense = 65; f.counter_td = 55; f.cage_wrestling = 58
	f.top_control = 60; f.bottom_control = 55; f.guard_pass = 52; f.guard_retention = 58
	f.sub_offense = 50; f.sub_defense = 55; f.sub_awareness = 52
	f.chin = 60; f.cut_resistance = 55; f.swell_resistance = 55; f.bleed_resistance = 58
	f.limb_health = 60; f.injury_recovery = 58
	f.max_stamina_rating = 70; f.drain_rate_rating = 65; f.recovery_rate_rating = 68
	f.gassed_threshold_rating = 65; f.cardio_drop_rating = 68
	f.record_wins = 12; f.record_losses = 1; f.record_kos = 4; f.record_subs = 3; f.record_decisions = 5
	f.primary_style = "generic_mma"
	f.strike_xp = {"jab": 350, "cross": 300, "hook": 250, "roundhouse": 200, "front_kick": 180, "leg_kick": 150}
	f.strike_prestige = {"jab": 1, "cross": 1, "hook": 1, "roundhouse": 1}
	f.owned_variants = ["standard_generic", "jab_fast", "cross_efficient", "roundhouse_fast", "front_kick_efficient"]
	f.equipped_variants = {"jab": "jab_fast", "cross": "cross_efficient", "hook": "hook_efficient", "uppercut": "standard_generic", "front_kick": "front_kick_efficient", "roundhouse": "roundhouse_fast", "leg_kick": "leg_kick_efficient", "head_kick": "standard_generic", "knee": "standard_generic", "elbow": "standard_generic"}
	f.build_stats()
	return f

# Featherweight BJJ specialist — Elite guard, submission danger everywhere, weak stand-up
static func _build_hiro_tanaka():
	var f = _FighterData.new()
	f.fighter_name = "Hiro Tanaka"
	f.nickname = "The Cobra"
	f.weight_class = 3  # FW
	f.nationality = "Japan"
	f.age = 27
	f.reach_inches = 69.0
	f.height_ft = 5
	f.height_in = 7
	f.stance = 0
	f.strength = 48; f.speed = 75; f.endurance = 78; f.toughness = 55
	f.boxing = 38; f.kickboxing = 35; f.muay_thai = 40; f.head_movement = 55; f.footwork = 60
	f.clinch_offense = 65; f.clinch_defense = 70; f.clinch_takedown = 72
	f.td_offense = 68; f.td_defense = 55; f.counter_td = 65; f.cage_wrestling = 48
	f.top_control = 75; f.bottom_control = 92; f.guard_pass = 70; f.guard_retention = 88
	f.sub_offense = 95; f.sub_defense = 85; f.sub_awareness = 88
	f.chin = 45; f.cut_resistance = 50; f.swell_resistance = 48; f.bleed_resistance = 52
	f.limb_health = 50; f.injury_recovery = 65
	f.max_stamina_rating = 80; f.drain_rate_rating = 82; f.recovery_rate_rating = 85
	f.gassed_threshold_rating = 80; f.cardio_drop_rating = 85
	f.record_wins = 16; f.record_losses = 5; f.record_subs = 14; f.record_decisions = 2
	f.primary_style = "bjj"
	f.strike_xp = {"jab": 150, "cross": 120, "td_offense": 500, "sub_offense": 900, "clinch_takedown": 400, "bottom_control": 700}
	f.strike_prestige = {"sub_offense": 4, "bottom_control": 3, "td_offense": 2}
	f.owned_variants = ["standard_generic", "jab_efficient", "cross_efficient", "knee_efficient", "sub_triangle", "sub_armbar", "sub_omoplata"]
	f.equipped_variants = {"jab": "jab_efficient", "cross": "cross_efficient", "hook": "standard_generic", "uppercut": "standard_generic", "front_kick": "standard_generic", "roundhouse": "standard_generic", "leg_kick": "standard_generic", "head_kick": "standard_generic", "knee": "knee_efficient", "elbow": "standard_generic"}
	f.build_stats()
	return f

# Women's Strawweight Striker — Muay Thai volume striker, excellent clinch, suspect TD defense
static func _build_luciana_santos():
	var f = _FighterData.new()
	f.fighter_name = "Luciana Santos"
	f.nickname = "The Hurricane"
	f.weight_class = 0  # Straw
	f.nationality = "Brazil"
	f.age = 25
	f.reach_inches = 65.0
	f.height_ft = 5
	f.height_in = 4
	f.stance = 1  # southpaw
	f.strength = 55; f.speed = 88; f.endurance = 85; f.toughness = 48
	f.boxing = 55; f.kickboxing = 78; f.muay_thai = 88; f.head_movement = 62; f.footwork = 72
	f.clinch_offense = 85; f.clinch_defense = 72; f.clinch_takedown = 60
	f.td_offense = 35; f.td_defense = 45; f.counter_td = 50; f.cage_wrestling = 30
	f.top_control = 35; f.bottom_control = 42; f.guard_pass = 28; f.guard_retention = 45
	f.sub_offense = 25; f.sub_defense = 40; f.sub_awareness = 35
	f.chin = 42; f.cut_resistance = 55; f.swell_resistance = 40; f.bleed_resistance = 50
	f.limb_health = 45; f.injury_recovery = 68
	f.max_stamina_rating = 90; f.drain_rate_rating = 88; f.recovery_rate_rating = 92
	f.gassed_threshold_rating = 88; f.cardio_drop_rating = 92
	f.record_wins = 10; f.record_losses = 1; f.record_kos = 3; f.record_decisions = 7
	f.primary_style = "muay_thai"
	f.strike_xp = {"roundhouse": 500, "front_kick": 350, "knee": 300, "jab": 200, "cross": 150, "elbow": 200}
	f.strike_prestige = {"roundhouse": 2, "front_kick": 1, "knee": 1}
	f.owned_variants = ["standard_generic", "roundhouse_thai", "front_kick_teep_mt", "knee_thai_clinch", "jab_thai", "leg_kick_thai", "roundhouse_lead_leg"]
	f.equipped_variants = {"jab": "jab_thai", "cross": "standard_generic", "hook": "standard_generic", "uppercut": "uppercut_fast", "front_kick": "front_kick_teep_mt", "roundhouse": "roundhouse_thai", "leg_kick": "leg_kick_thai", "head_kick": "standard_generic", "knee": "knee_thai_clinch", "elbow": "standard_generic"}
	f.build_stats()
	return f
