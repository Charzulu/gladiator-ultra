# scripts/animation/LimbSolver.gd
# FABRIK (Forward And Backward Reaching Inverse Kinematics) for 2-bone chains.
# Solves shoulder → elbow → fist for arms, hip → knee → foot for legs.
# Pure math, no scene tree dependency. ~0.005ms per solve.
extends RefCounted

# ── Solve result ──
class IKResult:
	var shoulder_rotation: Quaternion   # bone rotation for upper arm
	var elbow_rotation: Quaternion     # bone rotation for forearm
	var elbow_position: Vector3        # world-space elbow position (for debug/effects)
	var reached_target: bool           # true if target is within physical reach
	var extension_pct: float           # 0.0 (fully bent) to 1.0 (fully extended)

# ── Solve a 2-bone chain ──
# start: Vector3 — shoulder/hip world position (parent joint)
# target: Vector3 — desired end-effector world position (fist/foot)
# hint: Vector3 — direction the middle joint should bow (for natural arcs)
# upper_len: float — length of first bone (upper arm / thigh)
# lower_len: float — length of second bone (forearm / shin)
# weight: float — 0.0-1.0 blend toward full solution (for partial strikes)
static func solve_two_bone(
	start: Vector3,
	target: Vector3,
	hint: Vector3,
	upper_len: float,
	lower_len: float,
	weight: float = 1.0
) -> IKResult:
	var result = IKResult.new()
	var total_len = upper_len + lower_len

	# Clamp target to physical reach limits
	var dir = target - start
	var dist = dir.length()

	if dist > total_len:
		# Target beyond full extension — reach max distance toward it
		target = start + dir.normalized() * total_len
		dist = total_len
		result.reached_target = false
	elif dist < abs(upper_len - lower_len):
		# Target too close — push to minimum bend distance
		target = start + dir.normalized() * abs(upper_len - lower_len)
		dist = abs(upper_len - lower_len)
		result.reached_target = false
	else:
		result.reached_target = true

	# Extension percentage (0 = bent, 1 = straight)
	result.extension_pct = (dist - abs(upper_len - lower_len)) / (total_len - abs(upper_len - lower_len))

	# Law of cosines to find elbow angle
	var cos_angle = (upper_len * upper_len + dist * dist - lower_len * lower_len) / max(2.0 * upper_len * dist, 0.0001)
	cos_angle = clampf(cos_angle, -1.0, 1.0)
	var elbow_angle = acos(cos_angle)

	# Calculate elbow position in the plane defined by start → target and hint
	var start_to_target = (target - start).normalized()
	var hint_dir: Vector3
	if hint.length_squared() > 0.0001:
		hint_dir = hint.normalized()
	else:
		# Default hint: perpendicular to start→target, biased by world up
		var perp = start_to_target.cross(Vector3.UP)
		if perp.length_squared() < 0.0001:
			perp = start_to_target.cross(Vector3.RIGHT)
		hint_dir = perp.cross(start_to_target).normalized()

	# The perpendicular direction that defines the elbow bend plane
	var perp_bend = hint_dir.cross(start_to_target).normalized()
	if perp_bend.length_squared() < 0.0001:
		perp_bend = start_to_target.cross(Vector3.UP).normalized()

	# Rotate the start→target direction by elbow_angle/2 in the bend plane
	var half_angle = elbow_angle * 0.5 * weight
	var elbow_dir = start_to_target.rotated(perp_bend, half_angle).normalized()
	var elbow_pos = start + elbow_dir * upper_len

	result.elbow_position = elbow_pos
	result.shoulder_rotation = _look_rotation(start_to_target, perp_bend)
	result.elbow_rotation = _look_rotation((target - elbow_pos).normalized(), perp_bend)

	return result

# ── Solve both arms simultaneously (for clinch/ground positions) ──
static func solve_both_arms(
	left_shoulder: Vector3, left_target: Vector3,
	right_shoulder: Vector3, right_target: Vector3,
	hint: Vector3,
	upper_len: float, lower_len: float,
	weight: float = 1.0
) -> Dictionary:
	return {
		"left": solve_two_bone(left_shoulder, left_target, hint, upper_len, lower_len, weight),
		"right": solve_two_bone(right_shoulder, right_target, hint, upper_len, lower_len, weight),
	}

# ── Compute a look rotation (point +Z toward target, +Y as up) ──
static func _look_rotation(forward: Vector3, up: Vector3) -> Quaternion:
	var fwd = forward.normalized()
	var y_axis = up.normalized()
	var x_axis = y_axis.cross(fwd).normalized()
	if x_axis.length_squared() < 0.0001:
		x_axis = Vector3.RIGHT
		y_axis = fwd.cross(x_axis).normalized()
	else:
		y_axis = fwd.cross(x_axis).normalized()
	var basis = Basis(x_axis, y_axis, -fwd)
	return basis.orthonormalized().get_rotation_quaternion()

# ── Helper: get bone length from Skeleton3D rest pose ──
static func get_bone_length(skeleton: Skeleton3D, bone_idx: int) -> float:
	var pose = skeleton.get_bone_pose_position(bone_idx)
	return pose.length()

# ── Helper: get total arm length from skeleton (shoulder + forearm) ──
static func get_arm_length(skeleton: Skeleton3D, shoulder_bone: String, elbow_bone: String) -> float:
	var shoulder_idx = skeleton.find_bone(shoulder_bone)
	var elbow_idx = skeleton.find_bone(elbow_bone)
	if shoulder_idx == -1 or elbow_idx == -1:
		return 0.5  # default fallback
	return get_bone_length(skeleton, shoulder_idx) + get_bone_length(skeleton, elbow_idx)
