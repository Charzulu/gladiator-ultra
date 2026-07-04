# scripts/animation/RecoveryPlanner.gd
# Computes the return-to-guard trajectory after a strike or missed strike.
# Recovery speed is modulated by: stamina level, limb damage, combo count, speed stat.
# Pure math — no scene tree dependency.
extends RefCounted

# ── Recovery plan ──
class RecoveryPlan:
	var total_frames: int = 0       # total recovery frames
	var return_speed_mult: float = 1.0  # speed of return animation
	var guard_position: Vector3 = Vector3.ZERO  # where the limb returns to
	var is_balanced: bool = true    # false if recovery causes a stumble
	var stamina_cost: float = 0.0   # additional stamina for recovery
	var combo_chain_bonus: float = 1.0  # frame reduction for chaining

# ── Compute recovery plan ──
static func plan(
	base_recovery_frames: int,     # from StrikePlan.recovery_frames (already stat-modified)
	fighter_data,                  # FighterData (for SPD, stamina, limb status)
	current_stamina_pct: float,    # 0.0-1.0
	combo_count: int,              # 0 = first strike, 1 = second, etc.
	limb_name: String,             # "right_arm" or "left_arm" or "right_leg" etc.
	style_data,                    # StyleData (for guard position)
	is_miss: bool                  # true if strike didn't land
) -> RecoveryPlan:
	var plan = RecoveryPlan.new()

	# ── Base recovery from state machine ──
	plan.total_frames = base_recovery_frames

	# ── Stamina penalty ──
	if current_stamina_pct < 0.3:
		plan.total_frames = int(plan.total_frames * 1.4)
		plan.is_balanced = false
	elif current_stamina_pct < 0.5:
		plan.total_frames = int(plan.total_frames * 1.2)
		plan.stamina_cost = 1.0

	# ── Gassed penalty (compounds) ──
	if fighter_data and fighter_data.is_gassed():
		plan.total_frames = int(plan.total_frames * 1.3)
		plan.is_balanced = false

	# ── Limb damage penalty ──
	if limb_name and fighter_data:
		var status = fighter_data.get_limb_status(limb_name)
		if status.is_compromised:
			plan.total_frames = int(plan.total_frames / max(status.speed_mult, 0.1))
			plan.is_balanced = false

	# ── Combo chain bonus (faster recovery for chain strikes) ──
	if combo_count > 0:
		# Each subsequent strike recovers slightly faster (momentum)
		var chain_bonus = 1.0 - min(combo_count * 0.03, 0.15)
		plan.total_frames = max(1, int(plan.total_frames * chain_bonus))
		plan.combo_chain_bonus = chain_bonus

	# ── Miss penalty (over-committed) ──
	if is_miss:
		plan.total_frames = int(plan.total_frames * 1.25)
		plan.stamina_cost += 2.0

	# ── Guard position from style data ──
	if style_data:
		plan.guard_position = Vector3(
			style_data.lead_hand_forward * 0.2,
			style_data.guard_height * 0.5,
			-0.3
		)
	else:
		plan.guard_position = Vector3(0.15, 0.4, -0.3)

	# ── Return speed ──
	plan.return_speed_mult = 1.0
	if fighter_data:
		var spd_mult = fighter_data.get_d("strike_speed_mult", 1.0)
		plan.return_speed_mult = 1.0 / max(spd_mult, 0.3)

	return plan

# ── Quick compute for FSM integration ──
static func quick_recovery_frames(
	base_frames: int,
	fighter_data,
	is_gassed: bool,
	combo_count: int,
	limb: String
) -> int:
	var stam_pct = 1.0
	if fighter_data:
		stam_pct = fighter_data.get_stamina_pct()
	var p = plan(base_frames, fighter_data, stam_pct, combo_count, limb, null, false)
	return p.total_frames
