# Fighter 3D Skeleton & Hitbox Architecture

> **Aesthetic:** Virtua Fighter low-poly (~400-800 tris per fighter, vertex-colored, no textures)
> **Hitbox philosophy:** Generous capsules over simplified meshes — readability over tight-fit collision
> **Physics:** Limb-tip velocity vectors feed directly into ImpactCalculator
> **Animation philosophy:** FULLY PROCEDURAL — every strike is IK-driven, not pre-baked keyframes. Animation IS the physics output.
> **Reuse:** Same skeleton + hitbox layout works for MMA, beat-em-up, and fighting game

---

## 1. Skeleton Bone Hierarchy

Standard humanoid with 17 core bones + 6 limb-tip helpers. Bones named with `Bone_` prefix for Godot Skeleton3D compatibility.

```
Skeleton3D
├── Bone_root                   # Root/pelvis center — controls entire fighter position
├── Bone_hips                   # Hip pivot (root of all upper body)
│   ├── Bone_spine_01           # Lower spine (flexion/extension)
│   │   ├── Bone_spine_02       # Upper spine (twist, lean)
│   │   │   ├── Bone_chest      # Chest center — damage zone: TORSO
│   │   │   │   ├── Bone_neck   # Neck (short, stiff)
│   │   │   │   │   ├── Bone_head            # Head pivot — damage zone: HEAD
│   │   │   │   │   │   └── Bone_head_tip    # ★ HELPER: top-of-head position
│   │   │   │   │   └── Bone_jaw             # Jaw (for chin hit detection)
│   │   │   │   │       └── Bone_jaw_tip     # ★ HELPER: chin position
│   │   │   │   ├── Bone_clavicle_L          # Left shoulder
│   │   │   │   │   ├── Bone_upperarm_L      # Upper arm — damage zone: L_ARM
│   │   │   │   │   │   ├── Bone_forearm_L   # Forearm
│   │   │   │   │   │   │   ├── Bone_hand_L  # Hand
│   │   │   │   │   │   │   │   └── Bone_fist_L         # ★ HELPER: fist tip position
│   │   │   │   │   │   │   └── Bone_elbow_L           # ★ HELPER: elbow tip position
│   │   │   │   │   │   └── Bone_upperarm_L_end        # IK target
│   │   │   │   ├── Bone_clavicle_R          # Right shoulder
│   │   │   │   │   ├── Bone_upperarm_R      # Upper arm — damage zone: R_ARM
│   │   │   │   │   │   ├── Bone_forearm_R   # Forearm
│   │   │   │   │   │   │   ├── Bone_hand_R  # Hand
│   │   │   │   │   │   │   │   └── Bone_fist_R         # ★ HELPER: fist tip position
│   │   │   │   │   │   │   └── Bone_elbow_R           # ★ HELPER: elbow tip position
│   │   │   │   │   │   └── Bone_upperarm_R_end        # IK target
│   │   │   │   └── Bone_breastbone           # Center chest (for torso hit center)
│   │   │   └── Bone_spine_02_end
│   │   └── Bone_spine_01_end
│   └── Bone_hips_end
├── Bone_thigh_L                  # Left thigh — damage zone: L_LEG
│   ├── Bone_shin_L               # Left shin
│   │   ├── Bone_foot_L           # Left foot
│   │   │   └── Bone_toe_L        # ★ HELPER: foot tip (for kicks)
│   │   └── Bone_knee_L           # ★ HELPER: knee tip (for knees)
│   └── Bone_thigh_L_end          # IK target
└── Bone_thigh_R                  # Right thigh — damage zone: R_LEG
    ├── Bone_shin_R               # Right shin
    │   ├── Bone_foot_R           # Right foot
    │   │   └── Bone_toe_R        # ★ HELPER: foot tip (for kicks)
    │   └── Bone_knee_R           # ★ HELPER: knee tip (for knees)
    └── Bone_thigh_R_end          # IK target
```

**Total:** 17 base bones + 6 helper bones = **23 bones total**

The 6 helper bones (marked ★) are what the physics system tracks for velocity — they sit at the impact points of strikes. Their world-space velocity each physics tick is what ImpactCalculator reads.

---

## 2. Skeleton Configuration Table

| Bone | Parent | Damage Zone | Type | Notes |
|------|--------|-------------|------|-------|
| Bone_root | — | — | Root | World-position root, Y=0 ground plane |
| Bone_hips | Bone_root | TORSO | Deforming | Hips are part of torso zone |
| Bone_spine_01 | Bone_hips | TORSO | Deforming | Lower spine |
| Bone_spine_02 | Bone_spine_01 | TORSO | Deforming | Upper spine |
| Bone_chest | Bone_spine_02 | TORSO | Deforming | Chest center |
| Bone_neck | Bone_chest | HEAD | Deforming | Short, stiff |
| Bone_head | Bone_neck | HEAD | Deforming | Head pivot |
| Bone_jaw | Bone_head | HEAD | Deforming | Chin |
| Bone_clavicle_L | Bone_chest | TORSO | Deforming | Left shoulder |
| Bone_upperarm_L | Bone_clavicle_L | L_ARM | Deforming | Left upper arm |
| Bone_forearm_L | Bone_upperarm_L | L_ARM | Deforming | Left forearm |
| Bone_hand_L | Bone_forearm_L | L_ARM | Deforming | Left hand |
| Bone_clavicle_R | Bone_chest | TORSO | Deforming | Right shoulder |
| Bone_upperarm_R | Bone_clavicle_R | R_ARM | Deforming | Right upper arm |
| Bone_forearm_R | Bone_upperarm_R | R_ARM | Deforming | Right forearm |
| Bone_hand_R | Bone_forearm_R | R_ARM | Deforming | Right hand |
| Bone_breastbone | Bone_chest | TORSO | Deforming | Center chest |
| Bone_thigh_L | Bone_root | L_LEG | Deforming | Left thigh |
| Bone_shin_L | Bone_thigh_L | L_LEG | Deforming | Left shin |
| Bone_foot_L | Bone_shin_L | L_LEG | Deforming | Left foot |
| Bone_thigh_R | Bone_root | R_LEG | Deforming | Right thigh |
| Bone_shin_R | Bone_thigh_R | R_LEG | Deforming | Right shin |
| Bone_foot_R | Bone_shin_R | R_LEG | Deforming | Right foot |
| **Bone_head_tip** | Bone_head | — | **Helper** | Top of head, for head kick impact |
| **Bone_jaw_tip** | Bone_jaw | — | **Helper** | Chin, for uppercut/hook impact |
| **Bone_fist_L** | Bone_hand_L | — | **Helper** | Left fist, for punch impact velocity |
| **Bone_elbow_L** | Bone_forearm_L | — | **Helper** | Left elbow, for elbow strike velocity |
| **Bone_fist_R** | Bone_hand_R | — | **Helper** | Right fist, for punch impact velocity |
| **Bone_elbow_R** | Bone_forearm_R | — | **Helper** | Right elbow, for elbow strike velocity |
| **Bone_knee_L** | Bone_shin_L | — | **Helper** | Left knee, for knee strike velocity |
| **Bone_toe_L** | Bone_foot_L | — | **Helper** | Left foot tip, for kick velocity |
| **Bone_knee_R** | Bone_shin_R | — | **Helper** | Right knee |
| **Bone_toe_R** | Bone_foot_R | — | **Helper** | Right foot tip |

---

## 3. Hitbox Design (Capsule Colliders)

Each damage zone gets a capsule collider. These are NOT mesh colliders — they are simplified `CollisionShape3D` capsules parented to specific bones. Generous sizing for readability at low-poly resolution.

**Sizing principles:**
- Capsules are 10-20% larger than the mesh bounds for that bone cluster
- Overlap between adjacent zones is acceptable (only the most specific zone takes damage)
- Capsule radius = half the bone length at rest pose
- Capsule height = bone length at rest pose

### Hitbox Configurations

| Zone ID | Parent Bone | Capsule Radius | Capsule Height | Offset (local) | Coverage |
|---------|------------|---------------|---------------|----------------|---------|
| HEAD | Bone_head | 0.09m | 0.18m | (0, 0.05, 0.02) | Skull, face, jaw |
| TORSO | Bone_chest | 0.18m | 0.30m | (0, 0, 0) | Chest, upper back, shoulders |
| TORSO_LOWER | Bone_spine_01 | 0.15m | 0.22m | (0, 0, 0) | Abs, lower back, hips |
| L_ARM | Bone_upperarm_L | 0.06m | 0.28m | (0, -0.05, 0) | Left upper arm |
| L_FOREARM | Bone_forearm_L | 0.05m | 0.25m | (0, -0.02, 0) | Left forearm + hand |
| R_ARM | Bone_upperarm_R | 0.06m | 0.28m | (0, -0.05, 0) | Right upper arm |
| R_FOREARM | Bone_forearm_R | 0.05m | 0.25m | (0, -0.02, 0) | Right forearm + hand |
| L_THIGH | Bone_thigh_L | 0.09m | 0.30m | (0, -0.05, 0) | Left thigh |
| L_SHIN | Bone_shin_L | 0.06m | 0.28m | (0, -0.03, 0) | Left shin + foot |
| R_THIGH | Bone_thigh_R | 0.09m | 0.30m | (0, -0.05, 0) | Right thigh |
| R_SHIN | Bone_shin_R | 0.06m | 0.28m | (0, -0.03, 0) | Right shin + foot |

**Collision layer mapping:**
```
Layer 1: Hitbox (defender) — each zone capsule is on this layer
Layer 2: Hurtbox (attacker weapon) — fist/shin/elbow helpers on this layer
Layer 3: Body blocker (non-damage collision for push)
```

---

## 4. Limb-Tip Velocity Tracking (Physics Input)

The 6 helper bones (fist_L/R, elbow_L/R, knee_L/R, toe_L/R) are tracked every physics frame for their world-space velocity. This is what feeds ImpactCalculator.

### Velocity Capture System

```gdscript
# autoload/LimbTracker.gd
# Global singleton. Each physics frame, captures world-space velocity of all helper bones.
# FighterStateMachine queries this when a strike impact is detected.

extends Node

class LimbSnapshot:
	var bone_path: String
	var global_position: Vector3
	var velocity: Vector3      # m/s, derived from position delta
	var angular_velocity: float # rad/s, derived from rotation delta
	var timestamp: float

var _fighters: Array[Dictionary] = []  # [{ "skeleton": Skeleton3D, "bones": [...], "prev_pos": {...} }]

func register_fighter(skeleton: Skeleton3D) -> void:
	var entry = {
		"skeleton": skeleton,
		"bones": _find_helper_bones(skeleton),
		"prev_pos": {},
		"prev_rot": {},
	}
	for bone_name in entry["bones"]:
		var idx = skeleton.find_bone(bone_name)
		entry["prev_pos"][bone_name] = skeleton.to_global(skeleton.get_bone_pose_position(idx))
		entry["prev_rot"][bone_name] = skeleton.get_bone_pose_rotation(idx)
	_fighters.append(entry)

func unregister_fighter(skeleton: Skeleton3D) -> void:
	for i in range(_fighters.size() - 1, -1, -1):
		if _fighters[i]["skeleton"] == skeleton:
			_fighters.remove_at(i)
			return

func _physics_process(delta: float) -> void:
	var now = Time.get_ticks_usec() / 1000000.0
	for entry in _fighters:
		var skel = entry["skeleton"]
		for bone_name in entry["bones"]:
			var idx = skel.find_bone(bone_name)
			var current_pos = skel.to_global(skel.get_bone_pose_position(idx))
			var prev_pos = entry["prev_pos"].get(bone_name, current_pos)
			var vel = (current_pos - prev_pos) / max(delta, 0.0001)
			entry["prev_pos"][bone_name] = current_pos
			# Store for query
			skel.set_meta("vel_" + bone_name, { "velocity": vel, "timestamp": now, "position": current_pos })

func get_limb_velocity(skeleton: Skeleton3D, bone_name: String, now: float) -> Dictionary:
	var meta = skeleton.get_meta("vel_" + bone_name, {})
	if meta.get("timestamp", 0) == now:
		return meta
	return { "velocity": Vector3.ZERO, "position": skeleton.to_global(
		skeleton.get_bone_pose_position(skeleton.find_bone(bone_name))
	)}
```

### Strike-to-Limb Mapping

| Strike Type | Velocity Source Bone | Impact Zone |
|-------------|---------------------|-------------|
| Jab / Cross | Bone_fist_L / Bone_fist_R | Any (targeted) |
| Hook | Bone_fist_L / Bone_fist_R (+ angular) | Any |
| Uppercut | Bone_fist_L / Bone_fist_R (+ vertical) | HEAD / TORSO |
| Elbow | Bone_elbow_L / Bone_elbow_R | HEAD / TORSO |
| Roundhouse Kick | Bone_toe_L / Bone_toe_R | Any |
| Front Kick | Bone_toe_L / Bone_toe_R | TORSO |
| Leg Kick | Bone_knee_L / Bone_knee_R | L_LEG / R_LEG |
| Head Kick | Bone_toe_L / Bone_toe_R | HEAD |
| Knee (clinch) | Bone_knee_L / Bone_knee_R | TORSO / L_LEG |

---

## 5. Fighter Scene Tree

```
Fighter (RigidBody3D / CharacterBody3D)
├── Mesh (Node3D)
│   └── LowPolyFighter (MeshInstance3D)
│       └── Skeleton3D (with all 23 bones above)
│           └── AnimationPlayer
├── HitboxContainer (Node3D)
│   ├── Capsule_Head (CollisionShape3D — capsule shape)
│   │   └── Attached: Bone_head
│   ├── Capsule_Torso (CollisionShape3D)
│   │   └── Attached: Bone_chest
│   ├── Capsule_TorsoLower (CollisionShape3D)
│   │   └── Attached: Bone_spine_01
│   ├── Capsule_LeftArm (CollisionShape3D)
│   │   └── Attached: Bone_upperarm_L
│   ├── Capsule_LeftForearm (CollisionShape3D)
│   │   └── Attached: Bone_forearm_L
│   ├── Capsule_RightArm (CollisionShape3D)
│   │   └── Attached: Bone_upperarm_R
│   ├── Capsule_RightForearm (CollisionShape3D)
│   │   └── Attached: Bone_forearm_R
│   ├── Capsule_LeftThigh (CollisionShape3D)
│   │   └── Attached: Bone_thigh_L
│   ├── Capsule_LeftShin (CollisionShape3D)
│   │   └── Attached: Bone_shin_L
│   ├── Capsule_RightThigh (CollisionShape3D)
│   │   └── Attached: Bone_thigh_R
│   └── Capsule_RightShin (CollisionShape3D)
│       └── Attached: Bone_shin_R
├── HurtboxContainer (Node3D) — weapon hitboxes, enabled per strike animation
│   ├── Hurtbox_FistL (CollisionShape3D — small sphere)
│   │   └── Attached: Bone_fist_L
│   ├── Hurtbox_FistR (CollisionShape3D — small sphere)
│   │   └── Attached: Bone_fist_R
│   ├── Hurtbox_ElbowL (CollisionShape3D — small sphere)
│   ├── Hurtbox_ElbowR
│   ├── Hurtbox_KneeL
│   ├── Hurtbox_KneeR
│   ├── Hurtbox_ToeL
│   └── Hurtbox_ToeR
├── FighterData (Resource) — the stat block
├── FighterStateMachine (Node)
├── AnimationStateMachine (AnimationTree)
└── HealthBar (Node3D — billboarded)
```

---

## 6. Weapon Hitbox Activation Per Animation

The hurtboxes (weapon hitboxes) are disabled by default. Each strike animation enables the appropriate one at the contact frame.

### Hitbox Activation Table

| Animation Clip | Active Hurtbox | Active Frames | Notes |
|---------------|---------------|---------------|-------|
| jab_L | Bone_fist_L | 3-5 | Snappy, short active window |
| cross_R | Bone_fist_R | 5-8 | Extended follow-through |
| hook_L | Bone_fist_L | 7-10 | Wide arc, longer active |
| uppercut_R | Bone_fist_R | 6-9 | Vertical trajectory |
| elbow_L | Bone_elbow_L | 4-6 | Short, devastating |
| roundhouse_R | Bone_toe_R | 10-14 | Wide arc, long reach |
| front_kick_L | Bone_toe_L | 7-10 | Linear, teep |
| leg_kick_L | Bone_knee_L | 6-9 | Low arc |
| head_kick_R | Bone_toe_R | 12-16 | High arc, slow recovery |
| clinch_knee_L | Bone_knee_L | 3-5 | Very short, close range |
| clinch_elbow_R | Bone_elbow_R | 3-5 | Very short |

---

## 7. Impact Resolution Flow

```
Frame N (physics tick):
  1. LimbTracker captures velocity of all helper bones
  2. Hurtbox overlaps with opponent's Hitbox → Area2D signal fires
  3. System reads:
     - Which hurtbox (strike type, attacker info)
     - Which hitbox zone (head/torso/arm/leg)
     - Attacker's limb velocity from LimbTracker
     - Range at impact (distance between Bone_chest positions)
  4. Pass to ImpactCalculator.resolve_strike(
       attacker_data, defender_data,
       strike_type, zone,
       limb_velocity, false, range, perfect_timing
     )
  5. ImpactCalculator returns HitResult
  6. FighterStateMachine applies: damage, stamina costs, stun/KO, cut, swell
  7. Visual: hitstop (Enginertime_scale = 0), camera shake
```

---

## 8. Mesh & Skeleton Export Checklist (Blender → Godot)

### Blender Setup
```
- Armature with EXACT bone names from Section 1 above
- Apply all transforms before rigging
- Mesh: ~500-1000 quads, low-poly, vertex group weighted per bone
- Each bone: deform ticked for base bones, UNTICKED for helper bones
  (Helpers like Bone_fist_L should NOT deform mesh — they are position-only)
- Pose: A-pose or T-pose (fighters in A-pose, hands slightly forward)
- Export as GLTF: .glb or .gltf with +Y up, embedded textures
```

### Godot Import
```
Import .glb → Godot creates:
  - .tscn with Skeleton3D + MeshInstance3D
  - AnimationPlayer with all actions
  - Bone names preserved exactly

Post-import:
  1. Delete the auto-generated AnimationPlayer if present (we create our own)
  2. Add Capsule_* children under HitboxContainer (script-driven creation)
  3. Add Hurtbox_* children under HurtboxContainer
  4. Assign each capsule to parent bone via Skeleton3D bone attachment
  5. Register with LimbTracker autoload
```

### Low-Poly Specifics
| Feature | Virtua Fighter style | Your target |
|---------|---------------------|-------------|
| Poly count | ~800-1200 tris | 500-800 tris |
| Texture | Gouraud shading, flat colors | Vertex colors + simple flat shader |
| Silhouette | Readable, exaggerated | Clear limb separation, slightly oversized hands/feet |
| Skeleton bones | ~15-20 | 23 (23) including helpers |

---

## 9. Cross-Genre Modularity

The same skeleton + hitbox system adapts to different genres by enabling/disabling layers:

| Genre | Hitbox Zones Used | Hurtboxes Used | Changes |
|-------|------------------|----------------|---------|
| **MMA** | All 12 zones | All 8 hurtboxes | Full system |
| **Beat-em-up** | HEAD, TORSO, L_ARM, R_ARM | Bone_fist_L/R, Bone_toe_L/R | Simplify: merge L_LEG/R_LEG → TORSO, remove elbow/knee hurtboxes |
| **Fighting Game** | HEAD, TORSO, L_ARM, R_ARM | Bone_fist_L/R | Remove leg zones entirely, standing/crouching hitbox swap |
| **Action RPG** | HEAD, TORSO, L_ARM, R_ARM, L_LEG, R_LEG | Bone_fist_L/R + weapon bone | Add weapon bone (sword tip) as additional hurtbox |

---

## 10. Marketplace Packaging

| Package | Contents | Price |
|---------|----------|-------|
| `fighter-skeleton-base` | 23-bone skeleton + setup script | $8 |
| `fighter-hitbox-mma` | 12-zone capsule setup + LimbTracker + hurtbox system | $12 |
| `fighter-hitbox-brawler` | 4-zone simplified hitbox for beat-em-up/fighting games | $6 |
| `fighter-skeleton-complete` | Skeleton + MMA hitbox + hurtboxes + Blender export guide + 3 poses | $18 |

---

## 11. Procedural Physics-Driven Animation System

> **Core philosophy:** No pre-baked keyframe animation clips. Every strike, movement, and transition is procedurally generated from state machine + stats + physics. Animation IS the output of the combat math.

### 11.1 Why Procedural Over Keyframe

| Aspect | Traditional Keyframe | Procedural (This Game) |
|--------|--------------------|----------------------|
| Strike speed | Fixed per animation clip | Computed from SPD stat, modulated by stamina |
| Strike reach | Fixed by animator's keyframe | Computed from range to opponent + lunge distance from StyleData |
| Recovery frames | Fixed in animation data | Computed from stamina drain + limb damage |
| Gassed state | Separate "slow" animation clips | Same procedural system, slower speed + shorter reach automatically |
| Limb damage | Separate animation set | Same system — shorter reach, lower velocity automatically |
| Grapple transitions | Blended animation | IK-based position blending, speed from clinch_offense vs clinch_defense |
| Memory cost | N animation clips × N fighters | Zero clip storage — pure math |

### 11.2 Architecture

```
Fighter Animation Pipeline (per physics tick):

State Machine → "throw cross to head"
       │
       ▼
StrikePlanner.gd
  ├── Reads: SPD stat → strike_speed_mult
  ├── Reads: STR stat → follow_through_power
  ├── Reads: Limb status → effective power/speed mult
  ├── Reads: Stamina → speed penalty if gassed
  ├── Reads: Style → lunge_distance, ideal_range
  └── Computes: target position (opponent head + range compensation)
       │
       ▼
LimbSolver.gd (FABRIK IK solver)
  ├── Input: start_pos (current fist position)
  ├── Input: target_pos (opponent hit zone + lead/lag)
  ├── Input: arc_trajectory (punch path: straight, hook arc, uppercut vertical)
  ├── Input: speed (strike_speed_mult × base_speed × limb_status)
  ├── Input: chain_length (shoulder → elbow → fist)
  └── Output: per-bone rotation for upperarm, forearm, hand
       │
       ▼
ContactDetector.gd
  ├── Tracks: distance from fist to target each frame
  ├── On contact: fires hit resolution (ImpactCalculator)
  └── On miss: continues to full extension, then recovery
       │
       ▼
RecoveryPlanner.gd
  ├── Reads: stamina → recovery speed
  ├── Reads: Limb damage → recovery speed penalty
  ├── Reads: Combo count → recovery penalty (chain fatigue)
  └── Returns limb to guard position at computed speed
```

### 11.3 Strike Trajectory Definitions (No Animation Data Required)

Each strike type is defined as a trajectory function, not a keyframe list:

```gdscript
# Each strike type defines a 3D path from guard to impact
# The path is a parametric curve: position = f(t) where t ∈ [0, 1]

func jab_trajectory(t: float, fighter_data) -> Vector3:
	# Linear forward extension from lead fist position
	var forward_dist = t * (0.8 + fighter_data.reach_inches * 0.005)
	var lateral_jitter = sin(t * PI) * 0.02  # slight natural variance
	return Vector3(lateral_jitter, 0, -forward_dist)

func hook_trajectory(t: float, fighter_data) -> Vector3:
	# Wide horizontal arc
	var angle = t * PI * 0.85  # 0 to ~153 degrees
	var radius = 0.3 + t * 0.15  # slight forward shift
	return Vector3(
		-sin(angle) * radius,
		sin(t * PI * 0.5) * 0.05,  # slight rise
		-cos(angle) * radius - 0.1
	)

func roundhouse_trajectory(t: float, fighter_data) -> Vector3:
	# Circular rising arc (rear leg)
	var angle = t * PI * 0.9
	var height = sin(angle) * 0.5
	return Vector3(
		sin(angle) * 0.6,
		height * 0.6,
		-cos(angle) * 0.5
	)

func front_kick_trajectory(t: float, fighter_data) -> Vector3:
	# Linear forward, slight rise at end
	var fwd = t * (1.0 + fighter_data.reach_inches * 0.006)
	var rise = t * t * 0.15  # slight upward trajectory at extension
	return Vector3(0, rise, -fwd)
```

**Each trajectory is modulated by:**
- `t` → time compression/expansion based on SPD stat (SPD 90 = 0.6× time, SPD 20 = 1.6× time)
- `range_falloff` → if target is at 0.5m but jab reaches 1.2m, strike is cut short
- `stamina_mod` → gassed = trajectory shortens by 15%
- `limb_damage_mod` → compromised arm = trajectory shortens by 30%, drops 5°

### 11.4 IK Solver — FABRIK (Forward And Backward Reaching Inverse Kinematics)

Lightweight IK solver designed for 2-bone chain (shoulder → elbow → fist). Runs in under 0.01ms per chain.

```gdscript
# LimbSolver.gd — FABRIK for 2-bone arm/leg chains
# Input: start (shoulder), target (hit point), elbow_hint (bow direction)
# Output: rotation for upperarm and forearm bones

static func solve_two_bone(
	start: Vector3,       # shoulder global position
	target: Vector3,      # desired fist position
	elbow_hint: Vector3,  # direction elbow should bow (for realistic arcs)
	upper_len: float,     # Bone_upperarm length (from skeleton rest pose)
	forearm_len: float,   # Bone_forearm length
	weight: float = 1.0   # 0-1 blend toward target
) -> Dictionary:
	# Step 1: Clamp target to reachable range
	var total_len = upper_len + forearm_len
	var dir_to_target = target - start
	var dist = dir_to_target.length()
	
	if dist > total_len:
		# Target out of range — reach as far as possible toward target
		target = start + dir_to_target.normalized() * total_len
		dist = total_len
	
	if dist < abs(upper_len - forearm_len):
		# Too close — push target away
		target = start + dir_to_target.normalized() * abs(upper_len - forearm_len)
		dist = abs(upper_len - forearm_len)
	
	# Step 2: Law of cosines for elbow angle
	var a = upper_len
	var b = forearm_len
	var c = dist
	
	# Clamp to avoid floating point errors
	var cos_angle = clampf((a*a + c*c - b*b) / (2.0 * a * c), -1.0, 1.0)
	var elbow_angle = acos(cos_angle)
	
	# Step 3: Calculate elbow position (bow outward)
	var shoulder_to_target = (target - start).normalized()
	var perp = shoulder_to_target.cross(elbow_hint.normalized()).normalized()
	var elbow_dir = shoulder_to_target.rotated(perp, elbow_angle * 0.5 * weight)
	var elbow_pos = start + elbow_dir * upper_len
	
	# Step 4: Convert to bone rotations
	return {
		"elbow_position": elbow_pos,
		"shoulder_rotation": _look_rotation(start, elbow_pos),
		"elbow_rotation": _look_rotation(elbow_pos, target),
	}

static func _look_rotation(from: Vector3, to: Vector3) -> Quaternion:
	# Returns quaternion that rotates +X (bone default) to point from→to
	var dir = (to - from).normalized()
	var up = Vector3.UP
	var right = up.cross(dir).normalized()
	up = dir.cross(right).normalized()
	return Quaternion(Basis(right, up, dir))
```

### 11.5 What Requires Keyframes vs. What's Procedural

| Movement | Method | Why |
|----------|--------|-----|
| **Strikes** | Fully procedural | Trajectory function + IK — no keyframes needed |
| **Footwork** | Fully procedural | SPD-based step distance, IK foot placement |
| **Idle stance** | Single 1-frame pose read from StyleData | Just guard_height, stance_width values |
| **Clinch position** | Procedural position blend | Based on clinch_offense vs clinch_defense (who controls) |
| **Takedown entry** | Procedural level change + drive | SPD-based drop speed, STR-based drive distance |
| **Ground transitions** | Procedural blend | Between guard/side/mount base positions |
| **Submissions** | Single hold pose + procedural shake | Arm bar / choke shapes are fixed, struggle is procedural |
| **Knockdown** | Ragdoll override | Physics-driven fall, modified by TGH for recovery speed |
| **Getup** | Single 10-frame base + speed mod | Base getup keyframe, speed modulated by SPD |
| **KO state** | Ragdoll + timer | Full physics, TGH modifies recovery |

**Total keyframe data needed:** ~5-8 short poses and 1 getup animation. Everything else is math.

### 11.6 Visual Style: Virtua Fighter Low-Poly Spec

| Element | Spec |
|---------|------|
| Mesh budget | 300-600 vertices per fighter (VF1 territory) |
| Textures | NONE — vertex colors only |
| Shading | Unlit vertex color, flat shading (no smooth) |
| Polygon style | Quads preferred, visible edges, no bevels |
| Silhouette | Clean, readable body part separation |
| Color palette | 4-6 vertex colors per fighter: skin, shorts, gloves, hair, trim, shoes |
| Shadow | Hard shadow blob on ground plane (no realtime shadow maps) |
| Environment | Minimal arena geometry, flat floor with grid lines |
| Animation quality | 10-15 poses keyframed total (everything else procedural) |

### 11.7 Performance Budget

Per physics tick (60fps) for 2 fighters:

| System | Calc Cost | Notes |
|--------|-----------|-------|
| LimbTracker (velocity capture) | 12 helper bones × 2 fighters | O(24) vector subtractions |
| StrikePlanner | Called once per strike | O(1) formula lookup |
| IK solver (FABRIK) | 2 chains × 2 iterations | ~0.01ms total |
| Hitbox overlap check | 12 zones × 8 hurtboxes (worst case) | Capsule-capsule SAT, O(96) |
| ImpactCalculator | Called per hit | Pure float math, no allocations |
| Hitstop | Single Timer check | Negligible |
| Total | ~0.05ms per frame on modern CPU | ~0.3% of frame budget |

No animation memory overhead (zero clips loaded). No blend tree computation. No bone compression. The procedural system is faster, lighter, and more responsive than a traditional animation system.

### 11.8 State-to-Physics Pipeline (Complete Flow)

```
Input → ControlMap → InputBuffer → FighterStateMachine
                                         │
                                    (state + action)
                                         ▼
                                   action_type?
                              ┌────────┴────────┐
                              │                  │
                         "strike"           "grapple"
                              │                  │
                              ▼                  ▼
                    StrikePlanner       GrapplePlanner
                     ├─ trajectory       ├─ control calc
                     ├─ target_pos       └─ blend weight
                     └─ limb_assign           │
                              │               │
                              ▼               ▼
                    LimbSolver (IK)    PositionBlender
                     └─ bone rotations  └─ bone rotations
                              │               │
                              └───────┬───────┘
                                      ▼
                           Skeleton3D.set_bone_pose()
                                      │
                                      ▼
                           ContactDetector
                            ├─ hurtbox active?
                            ├─ overlap with hitbox?
                            └─ yes → ImpactCalculator
                                      │
                                      ▼
                           FighterStateMachine
                            ├─ apply damage
                            ├─ spend stamina
                            ├─ check stun/KO
                            └─ emit signals
                                      │
                                      ▼
                           Visual layer
                            ├─ Hitstop
                            ├─ Camera shake
                            ├─ Damage flash (mesh tint)
                            └─ Blood particle (vertex-colored quad, no texture)
```
