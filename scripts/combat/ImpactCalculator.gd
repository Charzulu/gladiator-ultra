# scripts/combat/ImpactCalculator.gd
# Physics-based damage resolution engine.
# Takes two velocity vectors, a hit angle, contact point, and fighter stats → returns damage profile.
# Pure math — no Node/SceneTree dependency, testable in isolation.
extends RefCounted

# ── Damage result structure ──
class HitResult:
	var damage: float = 0.0
	var mitigated_damage: float = 0.0
	var zone: String = "head"
	var damage_type: int = 0  # CombatGlobals.DamageType
	var stun_level: int = 0  # 0=none, 1=daze, 2=heavy_daze, 3=stun, 4=heavy_stun, 5=KD, 6=KO
	var stun_duration: float = 0.0  # seconds
	var is_knockdown: bool = false
	var is_ko: bool = false
	var cut_applied: bool = false
	var cut_depth: float = 0.0
	var swell_amount: float = 0.0
	var is_counter: bool = false
	var stamina_damage: float = 0.0
	var hit_velocity: float = 0.0
	var hit_angle: float = 0.0

	func _to_string() -> String:
		return "HitResult(zone=%s, damage=%.1f, mitigated=%.1f, stun=%d, cut=%s)" % [zone, damage, mitigated_damage, stun_level, cut_applied]

# ── Strike configuration ──
class StrikeConfig:
	var strike_type: int = 0  # CombatGlobals.StrikeType
	var base_damage: float = 5.0
	var cut_chance: float = 0.0     # 0.0-1.0 probability of cut
	var cut_depth_base: float = 1.0 # severity if cut lands
	var blunt_ratio: float = 1.0    # 1.0 = pure blunt, 0.0 = pure sharp
	var range: float = 1.0          # reach in meters
	var startup_frames: int = 5
	var recovery_frames: int = 8
	var stamina_cost: float = 3.0
	var damage_type: int = 0       # CombatGlobals.DamageType

	func _init(type: int) -> void:
		strike_type = type
		_configure(type)

	func _configure(type: int) -> void:
		match type:
			CombatGlobals.StrikeType.JAB:
				base_damage = 5.0; cut_chance = 0.05; startup_frames = 3
				recovery_frames = 4; stamina_cost = 2.0; range = 1.2; blunt_ratio = 1.0
			CombatGlobals.StrikeType.CROSS:
				base_damage = 9.0; cut_chance = 0.08; startup_frames = 6
				recovery_frames = 7; stamina_cost = 3.5; range = 1.3; blunt_ratio = 1.0
			CombatGlobals.StrikeType.HOOK:
				base_damage = 12.0; cut_chance = 0.10; startup_frames = 8
				recovery_frames = 9; stamina_cost = 4.0; range = 1.0; blunt_ratio = 1.0
			CombatGlobals.StrikeType.UPPERCUT:
				base_damage = 11.0; cut_chance = 0.08; startup_frames = 7
				recovery_frames = 8; stamina_cost = 4.0; range = 0.8; blunt_ratio = 1.0
			CombatGlobals.StrikeType.ROUNDHOUSE:
				base_damage = 14.0; cut_chance = 0.02; startup_frames = 12
				recovery_frames = 14; stamina_cost = 5.5; range = 1.8; blunt_ratio = 1.0
			CombatGlobals.StrikeType.FRONT_KICK:
				base_damage = 8.0; cut_chance = 0.0; startup_frames = 8
				recovery_frames = 8; stamina_cost = 3.0; range = 1.6; blunt_ratio = 1.0
			CombatGlobals.StrikeType.LEG_KICK:
				base_damage = 7.0; cut_chance = 0.01; startup_frames = 8
				recovery_frames = 8; stamina_cost = 3.5; range = 1.5; blunt_ratio = 0.8
			CombatGlobals.StrikeType.HEAD_KICK:
				base_damage = 18.0; cut_chance = 0.03; startup_frames = 14
				recovery_frames = 18; stamina_cost = 7.0; range = 1.8; blunt_ratio = 1.0
			CombatGlobals.StrikeType.KNEE:
				base_damage = 10.0; cut_chance = 0.01; startup_frames = 5
				recovery_frames = 6; stamina_cost = 3.0; range = 0.6; blunt_ratio = 1.0
			CombatGlobals.StrikeType.ELBOW:
				base_damage = 13.0; cut_chance = 0.35; startup_frames = 6
				recovery_frames = 8; stamina_cost = 3.5; range = 0.5; blunt_ratio = 0.4
			CombatGlobals.StrikeType.SWITCH_KICK:
				base_damage = 15.0; cut_chance = 0.02; startup_frames = 14
				recovery_frames = 16; stamina_cost = 6.5; range = 1.8; blunt_ratio = 1.0
			CombatGlobals.StrikeType.FRONT_KICK_BODY:
				base_damage = 9.0; cut_chance = 0.0; startup_frames = 9
				recovery_frames = 9; stamina_cost = 3.5; range = 1.6; blunt_ratio = 1.0

# ────────────────────────────────────────────
# MAIN RESOLUTION
# ────────────────────────────────────────────

# Resolve a strike impact between attacker and defender.
# Returns HitResult with all damage, stun, cut, and swell data.
static func resolve_strike(
	attacker_fighter_data,  # FighterData
	defender_fighter_data,  # FighterData
	strike_type: int,
	target_zone: String = "head",
	attacker_velocity: Vector3 = Vector3.ZERO,  # body velocity at impact
	is_counter: bool = false,
	range_at_impact: float = 1.0,
	perfect_timing: bool = false,
) -> HitResult:

	var result = HitResult.new()
	result.zone = target_zone
	result.is_counter = is_counter

	var config = StrikeConfig.new(strike_type)
	var atk = attacker_fighter_data
	var defn = defender_fighter_data

	# ── STEP 1: BASE DAMAGE ──
	var punch_base = atk.get_d("punch_base_dmg", 5.0)
	var kick_base = atk.get_d("kick_base_dmg", 8.0)
	var is_kick = strike_type in [
		CombatGlobals.StrikeType.ROUNDHOUSE,
		CombatGlobals.StrikeType.FRONT_KICK,
		CombatGlobals.StrikeType.LEG_KICK,
		CombatGlobals.StrikeType.HEAD_KICK,
		CombatGlobals.StrikeType.SWITCH_KICK,
		CombatGlobals.StrikeType.FRONT_KICK_BODY,
	]
	var base_damage = config.base_damage
	var stat_modified_damage = base_damage * (1.0 + (atk.strength * 0.01))

	# ── STEP 2: SKILL ACCURACY MODIFIER ──
	var skill_name = _skill_for_strike(strike_type)
	var skill_val = atk.get_skill(skill_name)
	var skill_mult = 0.5 + (skill_val / 200.0)  # range: 0.5 (0 skill) to 1.0 (100 skill)
	var damage_with_skill = stat_modified_damage * skill_mult

	# ── STEP 3: RANGE FALLOFF ──
	var optimal_range = config.range
	var range_error = abs(range_at_impact - optimal_range)
	var falloff = 1.0 - (range_error * 0.15)
	falloff = clampf(falloff, 0.2, 1.0)
	var damage_at_range = damage_with_skill * falloff

	# ── STEP 4: VELOCITY BONUS (physics) ──
	var velocity_magnitude = attacker_velocity.length()
	var velocity_bonus = 1.0 + (velocity_magnitude * 0.05)  # +5% per m/s of body velocity
	velocity_bonus = clampf(velocity_bonus, 0.8, 2.0)
	var raw_damage = damage_at_range * velocity_bonus

	# ── STEP 5: PERFECT TIMING ──
	if perfect_timing:
		raw_damage *= 1.25

	# ── STEP 6: COUNTER ──
	if is_counter:
		raw_damage *= 1.35

	# ── STEP 7: DEFENDER MITIGATION (Toughness) ──
	var dmg_mult = defn.get_d("dmg_taken_mult", 1.0)
	var mitigated = raw_damage * dmg_mult

	# ── STEP 8: STAMINA PENALTY ON DEFENDER ──
	if defn.is_gassed():
		mitigated *= 1.2  # take 20% more damage when gassed

	result.damage = raw_damage
	result.mitigated_damage = mitigated
	result.hit_velocity = velocity_magnitude
	result.hit_angle = _calc_hit_angle(attacker_velocity, target_zone)

	# ── STEP 9: STUN / HIT REACTION (progressive, counter-aware) ──
	var chin_val = defn.chin
	result.is_counter = is_counter

	# Only head shots cause meaningful stun; torso/arm/leg hits only daze at most
	var can_stun = (target_zone == "head") or (target_zone == "torso" and mitigated > 20.0)

	if mitigated > 0.0:
		if can_stun:
			# ── TIER 1: Every clean hit = daze ──
			result.stun_level = 1
			result.stun_duration = clampf(0.15 + mitigated * 0.002, 0.15, 0.35)

			# Counter = minimum stun (T3)
			if is_counter:
				result.stun_level = 3
				result.stun_duration = clampf(0.8 + (mitigated / max(chin_val, 1.0)) * 0.5, 0.8, 1.5)

			# ── TIER 2: Heavy Daze ──
			if (mitigated > chin_val * 0.6) or (is_counter and mitigated > chin_val * 0.4):
				result.stun_level = max(result.stun_level, 2)
				result.stun_duration = clampf(0.35 + mitigated * 0.004, 0.35, 0.5)

			# Counter already guaranteed T3+, but check for higher
			if not is_counter:
				# ── TIER 3: Stun (normal hit, high damage) ──
				if mitigated > chin_val * 1.0:
					result.stun_level = 3
					result.stun_duration = clampf(0.8 + (mitigated / max(chin_val, 1.0)) * 0.5, 0.8, 1.5)

			# ── TIER 4: Heavy Stun ──
			if (mitigated > chin_val * 1.5) or (is_counter and mitigated > chin_val * 1.0):
				result.stun_level = max(result.stun_level, 4)
				result.stun_duration = clampf(1.5 + (mitigated / max(chin_val, 1.0)) * 1.0, 1.5, 2.5)

			# ── TIER 5: Knockdown ──
			if (mitigated > chin_val * 2.0) or (is_counter and mitigated > chin_val * 1.5):
				result.stun_level = max(result.stun_level, 5)
				result.stun_duration = clampf((3.0 + (mitigated / max(chin_val, 1.0)) * 2.0) * (1.0 - defn.toughness * 0.003), 3.0, 5.0)
				result.is_knockdown = true

			# ── TIER 6: KO ──
			if (mitigated > chin_val * 3.0) or (is_counter and mitigated > chin_val * 2.0):
				result.stun_level = max(result.stun_level, 6)
				result.is_ko = true

		else:
			# Non-head hit — daze only
			result.stun_level = 1
			result.stun_duration = 0.1

	# ── STEP 10: CUT CHECK (sharp damage to head) ──
	if target_zone in ["head", "torso"] and config.cut_chance > 0.0:
		var cut_skill = atk.muay_thai  # elbows and sharp strikes scale with MT skill
		var effective_cut_chance = config.cut_chance * (cut_skill / 100.0)
		# Defender cut resistance reduces chance
		var cut_resist_mult = (100.0 - defn.cut_resistance) / 100.0
		var final_cut_chance = effective_cut_chance * cut_resist_mult

		if randf() < final_cut_chance:
			result.cut_applied = true
			result.cut_depth = config.cut_depth_base * (1.0 - (defn.bleed_resistance / 200.0))

	# ── STEP 11: SWELLING (blunt damage to head) ──
	if target_zone == "head" and config.blunt_ratio > 0.5:
		var swell_resist_mult = (100.0 - defn.swell_resistance) / 100.0
		result.swell_amount = mitigated * 0.1 * swell_resist_mult

	# ── STEP 12: STAMINA DAMAGE ──
	result.stamina_damage = config.stamina_cost
	# Body shots drain more stamina
	if target_zone == "torso":
		result.stamina_damage *= 1.5
	# Gassed attacker pays more stamina
	if attacker_fighter_data.is_gassed():
		result.stamina_damage *= 1.3

	result.damage_type = CombatGlobals.DamageType.BLUNT if config.blunt_ratio > 0.5 else CombatGlobals.DamageType.SHARP

	return result

# ── Helper: map strike type to the skill that governs it ──
static func _skill_for_strike(strike_type: int) -> String:
	match strike_type:
		CombatGlobals.StrikeType.JAB, CombatGlobals.StrikeType.CROSS, \
		CombatGlobals.StrikeType.HOOK, CombatGlobals.StrikeType.UPPERCUT:
			return "boxing"

		CombatGlobals.StrikeType.ROUNDHOUSE, CombatGlobals.StrikeType.FRONT_KICK, \
		CombatGlobals.StrikeType.LEG_KICK, CombatGlobals.StrikeType.HEAD_KICK, \
		CombatGlobals.StrikeType.SWITCH_KICK, CombatGlobals.StrikeType.FRONT_KICK_BODY:
			return "kickboxing"

		CombatGlobals.StrikeType.KNEE, CombatGlobals.StrikeType.ELBOW:
			return "muay_thai"

	return "boxing"

# ── Calculate angle of incidence from velocity ──
static func _calc_hit_angle(velocity: Vector3, zone: String) -> float:
	# Returns angle from dead-center (0 = center, 1.0 = 90 degrees off)
	if velocity.length_squared() < 0.01:
		return 0.0
	# Simple: angle relative to forward vector (0,0,-1 in Godot)
	var forward = Vector3(0, 0, -1)
	var dot = forward.normalized().dot(velocity.normalized())
	return acos(clampf(dot, -1.0, 1.0))

# ── Hit probability check ──
static func check_hit_probability(
	attacker_fighter_data,
	defender_fighter_data,
	strike_type: int,
	defender_is_blocking: bool = false,
	defender_head_movement_dir: Vector2 = Vector2.ZERO,
) -> bool:
	var atk = attacker_fighter_data
	var defn = defender_fighter_data

	# Attacker accuracy
	var skill_name = _skill_for_strike(strike_type)
	var skill = atk.get_skill(skill_name)
	var acc_bonus = atk.get_d("accuracy_bonus", 0.8)
	var hit_chance = (skill / 100.0) * acc_bonus

	# Defender evasion
	var head_move = defn.get_skill("head_movement")
	var reaction = defn.get_d("reaction_frames", 15.0)
	var evasion = (head_move / 100.0) * (reaction / 15.0)

	# Stamina penalties
	if atk.is_gassed():
		hit_chance *= 0.85
	if defn.is_gassed():
		evasion *= 0.65

	# Head movement bonus
	if defender_head_movement_dir.length_squared() > 0.3:
		evasion *= 1.4  # active head movement helps a lot

	# Block reduces hit chance to the body/head but not legs
	if defender_is_blocking:
		if strike_type == CombatGlobals.StrikeType.LEG_KICK:
			evasion *= 0.5  # can't block leg kicks well
		else:
			evasion *= 2.0  # block is very effective

	# Final: if randf() * hit_chance > (1.0 - evasion) * 0.8, hit lands
	var hit_roll = randf() * hit_chance
	var def_roll = (1.0 - evasion) * 0.8
	return hit_roll > def_roll
