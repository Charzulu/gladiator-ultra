# Gladiator Ultra — Attack Frame System, Controller Layout & State Machine

> **Design goal:** Replace the fragmented frame data and raw `_attack_cooldown` with a unified, phase-driven attack state machine. Every strike moves through **WINDUP → ACTIVE → RECOVERY** phases. Each phase carries its own damage multiplier, vulnerability multiplier, and movement rules. Controller bindings are mapped to the EA SPORTS UFC 6 layout.

> **Source confirmed:** EA SPORTS UFC 6 is a released title (www.ea.com/games/ufc/ufc-6). The standard control layout below reflects the EA UFC series core scheme (consistent since UFC 3) with refinements from UFC 6's "evolved striking and motion systems" as described on the official features page.

---

## 1. Controller Layout (Gamepad Bindings)

Based on EA SPORTS UFC 6 standard layout (the "Fight Your Fight" scheme), adapted for Gladiator Ultra's 12-stance/18-skill system.

### 1.1 Face Buttons — Primary Actions

| Button | Action (Stand-up) | Action (Clinch) | Action (Ground Top) | Action (Ground Bottom) | Action (Submission) |
|--------|-------------------|-----------------|---------------------|------------------------|---------------------|
| **A** (Cross) | Jab / Lead Strike | Knee | GNP Right | Sweep (w/ RS dir) | — |
| **B** (Circle) | Hook / Rear Strike | Elbow | GNP Left | Sub Attempt Bottom | — |
| **X** (Square) | Lead Kick | Body Knee | Sub Attempt Top | Frame / Wrist Control | — |
| **Y** (Triangle) | Rear Kick / Special | Pummel | Posture / Stand | Getup / Wall Walk | — |

### 1.2 Shoulder Buttons — Modifiers & Defense

| Button | Function | Notes |
|--------|----------|-------|
| **LB / L1** | High Target Modifier | Shifts strike target to HEAD zone |
| **RB / R1** | Low Target Modifier | Shifts strike target to BODY/LEG zone |
| **LT / L2** | Perfect Striking / Mod | Tap on contact frame for ×1.25 damage. Hold for takedowns / specials |
| **RT / R2** | Block (hold) | Guard. Stamina-based. High block auto-raises to match incoming strike |

### 1.3 Analog Sticks — Movement & Head Movement

| Input | Function | Details |
|-------|----------|---------|
| **LS** (Left Stick) | Fighter Movement | Walk forward/back/lateral. Lunge on LS→ + A |
| **RS** (Right Stick) | Head Movement / Directional | Slip (←/→), Duck (↓), Weave (↻). Also used for denial directions in grappling |
| **LS Click** | Sprint / Blitz | Burst of speed, consumes stamina |
| **RS Click** | Parry | Timed deflection — 3f startup, 2f active window. Opens 10f counter window |

### 1.4 D-Pad — Contextual

| Input | Function |
|-------|----------|
| **D-Pad Up** | Taunt / Emote |
| **D-Pad Down** | Change Stance (Orthodox ↔ Southpaw, if Switch skill permits) |
| **D-Pad Left/Right** | Coach Commands (career mode) / reserved |

### 1.5 Modifier Combinations

```
LS→ + A         = Lunge (forward burst)
LS→ + A + LT    = Double Leg Takedown (hold)
LS→ + X + LT    = Single Leg Takedown
LS→ + B          = Overhand (power punch)
LS→ + LT + Y     = Question Mark Kick
LS↓ + LT + Y     = Axe Kick

RB + X           = Leg Kick (low modifier + lead kick)
LB + Y           = Head Kick (high modifier + rear kick)
LT + X           = Front Kick (body variant)
LT + Y           = Switch Kick

RT (hold)        = Block
RT + RS↓         = Sprawl (takedown defense)
RT + RS→         = Whizzer Defense (single leg defense)

RS Click (timed) = Parry
RS←/RS→          = Slip left/right
RS↓              = Duck
RS↻              = Weave
```

---

## 2. Unified Frame Data — Single Source of Truth

All frame data moves from ImpactCalculator (StrikeConfig) and StrikePlanner into a **single data resource**. Both systems read from the same definition.

### 2.1 MoveData Resource (new)

```gdscript
# res://scripts/combat/MoveData.gd
# SINGLE SOURCE OF TRUTH for all move frame data.
# ImpactCalculator, StrikePlanner, and FighterStateMachine all read from this.
class_name MoveData
extends Resource

enum MoveCategory { PUNCH, KICK, KNEE, ELBOW, TAKEDOWN, DEFENSE, MOVEMENT, CLINCH, GNP, SUBMISSION }
enum TrajectoryId { JAB_TRAJ, CROSS_TRAJ, HOOK_TRAJ, UPPERCUT_TRAJ, ROUNDHOUSE_TRAJ,
    FRONT_KICK_TRAJ, LEG_KICK_TRAJ, HEAD_KICK_TRAJ, KNEE_TRAJ, ELBOW_TRAJ,
    OVERHAND_TRAJ, SUPERMAN_TRAJ, SWITCH_KICK_TRAJ, QMARK_KICK_TRAJ, AXE_KICK_TRAJ }

@export var move_id: String = ""
@export var display_name: String = ""
@export var category: MoveCategory = MoveCategory.PUNCH

# ── Frame data (BASE values — stat modified at runtime by StrikePlanner) ──
@export_range(1, 60) var base_startup: int = 5
@export_range(1, 30) var base_active: int = 4
@export_range(1, 60) var base_recovery: int = 8
@export var reach_meters: float = 1.0

# ── Combat data ──
@export var base_damage: float = 5.0
@export var stamina_cost: float = 3.0
@export var base_stun_tier: int = 1          # minimum stun tier on clean hit (1-6)
@export var cut_chance: float = 0.0           # 0.0-1.0
@export var blunt_ratio: float = 1.0          # 1.0 = pure blunt, 0.0 = pure sharp

# ── Targeting ──
@export var target_zones: Array[String] = ["head", "body"]
@export var primary_skill: String = "boxing"

# ── Trajectory ──
@export var trajectory_id: TrajectoryId = TrajectoryId.JAB_TRAJ

# ── Availability ──
@export var available_in_states: Array[int] = [0]  # FightState values
```

### 2.2 StrikePlan (updated)

StrikePlan no longer duplicates frame constants. It reads from `MoveData` and applies runtime stat modifiers:

```gdscript
# Inside StrikePlanner.gd — updated plan() function
static func plan(move_data: MoveData, stats: StatsMod) -> StrikePlan:
    var plan = StrikePlan.new()
    plan.move_data = move_data
    
    # Read base frames from move_data (single source of truth)
    var base_startup = move_data.base_startup
    var base_active = move_data.base_active
    var base_recovery = move_data.base_recovery
    
    # Apply stat modifiers
    plan.startup_frames = max(1, int(base_startup * stats.speed_mult * ...
    plan.active_frames = max(1, int(base_active * stats.speed_mult * ...
    plan.recovery_frames = max(1, int(base_recovery * stats.speed_mult * ...
    
    plan.total_duration = (plan.startup_frames + plan.active_frames + plan.recovery_frames) / 60.0
    plan.base_damage = move_data.base_damage * stats.strength_mult * ...
    plan.stamina_cost = move_data.stamina_cost * ...
    
    return plan
```

### 2.3 StrikeConfig (removed from ImpactCalculator)

The `StrikeConfig` class inside `ImpactCalculator.gd` is **deleted**. All frame/combat data comes from `MoveData` resource lookups:

```gdscript
# ImpactCalculator.gd — updated
static func resolve_strike(
    attacker_fighter_data,
    defender_fighter_data,
    move_data: MoveData,           # ← MoveData replaces StrikeConfig
    target_zone: String,
    attacker_velocity: Vector3,
    is_counter: bool,
    range_at_impact: float,
    perfect_timing: bool,
) -> HitResult:
    var result = HitResult.new()
    
    # Read from move_data directly
    var base_damage = move_data.base_damage
    var cut_chance = move_data.cut_chance
    # ... no more StrikeConfig duplication
```

---

## 3. Attack Phase State Machine — WINDUP → ACTIVE → RECOVERY

### 3.1 AttackPhase Enum

```gdscript
# Added to CombatGlobals.gd
enum AttackPhase { IDLE = 0, WINDUP, ACTIVE, RECOVERY, INTERRUPTED }
```

### 3.2 AttackState — Per-Limb Attack Tracker (new)

```gdscript
# scripts/fighter/AttackState.gd
# Tracks the current attack phase for each limb independently.
# Enables simultaneous attack tracking (e.g., left hand winding up while right hand recovers).
extends RefCounted

signal phase_changed(limb: String, old_phase: int, new_phase: int, move_data: MoveData)
signal strike_contact_window(limb: String, is_active: bool)  # true when entering ACTIVE, false when leaving

# ── Per-limb state ──
class LimbAttackState:
    var phase: int = 0                    # AttackPhase.IDLE
    var move_data: MoveData = null        # The move being executed
    var frame_counter: int = 0            # current frame within phase
    var startup_frames: int = 0           # stat-modified
    var active_frames: int = 0
    var recovery_frames: int = 0
    var strike_plan: Object = null        # StrikePlan for trajectory evaluation
    var is_executing: bool = false
    var hit_already_landed: bool = false  # prevents multi-hit on same swing

var _limbs: Dictionary = {}  # "right_arm" → LimbAttackState, "left_arm" → ...

func _init():
    for limb in ["right_arm", "left_arm", "right_leg", "left_leg"]:
        _limbs[limb] = LimbAttackState.new()

func start_attack(limb: String, plan: StrikePlan) -> bool:
    var state = _limbs.get(limb)
    if not state or state.is_executing:
        return false  # limb is busy
    
    state.phase = CombatGlobals.AttackPhase.WINDUP
    state.move_data = plan.move_data
    state.frame_counter = 0
    state.startup_frames = plan.startup_frames
    state.active_frames = plan.active_frames
    state.recovery_frames = plan.recovery_frames
    state.strike_plan = plan
    state.is_executing = true
    state.hit_already_landed = false
    
    phase_changed.emit(limb, CombatGlobals.AttackPhase.IDLE, CombatGlobals.AttackPhase.WINDUP, plan.move_data)
    return true

func advance_frame(limb: String) -> void:
    var state = _limbs.get(limb)
    if not state or not state.is_executing:
        return
    
    state.frame_counter += 1
    var old_phase = state.phase
    
    match state.phase:
        CombatGlobals.AttackPhase.WINDUP:
            if state.frame_counter >= state.startup_frames:
                _enter_phase(limb, state, CombatGlobals.AttackPhase.ACTIVE)
        
        CombatGlobals.AttackPhase.ACTIVE:
            if state.frame_counter >= state.active_frames:
                _enter_phase(limb, state, CombatGlobals.AttackPhase.RECOVERY)
        
        CombatGlobals.AttackPhase.RECOVERY:
            if state.frame_counter >= state.recovery_frames:
                _finish_attack(limb, state)

func _enter_phase(limb: String, state: LimbAttackState, new_phase: int) -> void:
    var old = state.phase
    state.phase = new_phase
    state.frame_counter = 0
    phase_changed.emit(limb, old, new_phase, state.move_data)
    
    if new_phase == CombatGlobals.AttackPhase.ACTIVE:
        strike_contact_window.emit(limb, true)
    elif new_phase == CombatGlobals.AttackPhase.RECOVERY:
        strike_contact_window.emit(limb, false)

func _finish_attack(limb: String, state: LimbAttackState) -> void:
    phase_changed.emit(limb, state.phase, CombatGlobals.AttackPhase.IDLE, state.move_data)
    state.is_executing = false
    state.move_data = null

func is_limb_busy(limb: String) -> bool:
	var state = _limbs.get(limb)
	return state and state.is_executing

func is_limb_available(limb: String) -> bool:
	"""Returns true if the limb is IDLE (can start a new move)."""
	var state = _limbs.get(limb)
	return state != null and not state.is_executing

func get_phase(limb: String) -> int:
	var state = _limbs.get(limb)
	return state.phase if state else CombatGlobals.AttackPhase.IDLE

func get_limb_state(limb: String):
	"""Returns the raw LimbAttackState for querying frame counters, move data, etc."""
	return _limbs.get(limb)

func get_active_limb_count() -> int:
    var count = 0
    for limb in _limbs:
        if _limbs[limb].is_executing:
            count += 1
    return count

func interrupt_all() -> void:
    for limb in _limbs:
        var state = _limbs[limb]
        if state.is_executing:
            var old = state.phase
            state.is_executing = false
            state.phase = CombatGlobals.AttackPhase.IDLE
            phase_changed.emit(limb, old, CombatGlobals.AttackPhase.INTERRUPTED, state.move_data)
            state.move_data = null
```

### 3.3 FighterStateMachine Integration

The `_attack_cooldown` variable is replaced with the `AttackState` per-limb tracker:

```gdscript
# Inside FighterStateMachine.gd
var attack_state: AttackState = AttackState.new()
var current_move_data: MoveData = null  # the most recently planned move, for damage calc

# Called every physics tick
func _process_attack_phases(delta: float) -> void:
    for limb in ["right_arm", "left_arm", "right_leg", "left_leg"]:
        attack_state.advance_frame(limb)

# In _perform_strike():
func _perform_strike(data: Dictionary) -> void:
    if not opponent_state: return
    
    var move_data = _get_move_data(data)  # look up from new MoveData resource
    if not move_data: return
    
    # Determine which limb this move uses
    var limb = _limb_for_move(move_data)
    if attack_state.is_limb_busy(limb):
        return  # limb already attacking (no overriding — commit to the move)
    
    # Build strike plan from move_data
    var stats = _build_stats_mod()
    var plan = StrikePlanner.plan(move_data, stats)
    
    # Start the phase tracker
    attack_state.start_attack(limb, plan)
    current_move_data = move_data
    
    # Deduct stamina upfront
    fighter_data.spend_stamina(plan.stamina_cost)

# Contact detection is checked ONLY during ACTIVE phase
func _check_strike_contact(delta: float) -> void:
    for limb in ["right_arm", "left_arm", "right_leg", "left_leg"]:
        if attack_state.get_phase(limb) != CombatGlobals.AttackPhase.ACTIVE:
            continue
        var state = attack_state._limbs[limb]
        if state.hit_already_landed:
            continue
        
        # Do hit detection using ContactDetector
        var weapon_point = _get_weapon_point(limb)
        var hitboxes = _build_opponent_hitboxes()
        var contact = ContactDetector.check_contact(weapon_point, velocity, hitboxes, prev_point)
        
        if contact.hit:
            state.hit_already_landed = true
            _resolve_contact(contact, limb, state)
```

---

## 4. Phase-Based Damage & Vulnerability Modifiers

### 4.1 Per-Phase Modifier Table

Each phase of an attack carries intrinsic modifiers that affect **both the attacker and defender**:

| Phase | Attacker Damage Mult | Attacker Vulnerability Mult | Attacker Movement | Notes |
|-------|---------------------|---------------------------|-------------------|-------|
| **IDLE** | — | ×1.0 (baseline) | Full speed | Neutral state |
| **WINDUP** | ×0.0 (no damage yet) | **×1.3** (more vulnerable) | Reduced speed (×0.6) | Telegraph phase — opponent can interrupt |
| **ACTIVE** | ×1.0 (full damage) | ×1.0 (normal) | Movement locked | Contact window — this is where hits land |
| **RECOVERY** | ×0.0 (damage done) | **×1.5** (highly vulnerable) | Can't move or block | Punish window — this is where counters land |
| **INTERRUPTED** | ×0.0 | ×1.2 | Reduced speed | Forcibly stopped (parried, hit during windup) |

### 4.2 How Vulnerability Affects Damage Taken

When calculating `resolve_strike()` in ImpactCalculator, the defender's current attack phase modifies damage taken:

```gdscript
# In ImpactCalculator.resolve_strike()
var defender_phase = defender_state.attack_state.get_phase(limb)
var vuln_mult = CombatGlobals.PHASE_VULNERABILITY.get(defender_phase, 1.0)
mitigated *= vuln_mult

# Bonus: if defender is in WINDUP when hit = interrupt (counter)
if defender_phase == CombatGlobals.AttackPhase.WINDUP:
    result.is_counter = true
    # Hitting an opponent in their windup is a clean interrupt
    
# Bonus: if defender is in RECOVERY when hit = hard punish
elif defender_phase == CombatGlobals.AttackPhase.RECOVERY:
    result.is_counter = true
    result.stun_level = max(result.stun_level, 2)  # minimum heavy daze on recovery punish
```

### 4.3 Phase Vulnerability Table (CombatGlobals)

```gdscript
# Added to CombatGlobals.gd
const PHASE_VULNERABILITY: Dictionary = {
    AttackPhase.IDLE: 1.0,
    AttackPhase.WINDUP: 1.3,
    AttackPhase.ACTIVE: 1.0,
    AttackPhase.RECOVERY: 1.5,
    AttackPhase.INTERRUPTED: 1.2,
}

# Counter trigger thresholds
const PHASE_COUNTER_THRESHOLD: Dictionary = {
    AttackPhase.WINDUP: true,    # hitting opponent in windup = counter
    AttackPhase.RECOVERY: true,  # hitting opponent in recovery = counter
    AttackPhase.IDLE: false,
    AttackPhase.ACTIVE: false,
}

# Minimum stun tier on recovery punish
const RECOVERY_PUNISH_MIN_STUN: int = 2  # Heavy Daze minimum
```

---

## 5. Block Integration with Attack Phases

Blocking is now phase-aware:

```gdscript
# BlockSystem.gd — updated
# Block during ACTIVE phase = partial block (late reaction)
# Block during WINDUP = if timed right, parry-like deflection
# Block during RECOVERY = standard block (defender can't block in recovery!)

func get_block_effectiveness(defender_phase: int, block_held: bool) -> Dictionary:
    if not block_held:
        return { "mitigation": 0.0, "type": "none" }
    
    match defender_phase:
        CombatGlobals.AttackPhase.IDLE:
            return { "mitigation": 0.7, "type": "full" }       # -70%
        CombatGlobals.AttackPhase.WINDUP:
            return { "mitigation": 0.4, "type": "partial" }    # -40%, stamina heavy
        CombatGlobals.AttackPhase.ACTIVE:
            return { "mitigation": 0.3, "type": "partial" }    # -30%, can't fully protect while throwing
        CombatGlobals.AttackPhase.RECOVERY:
            return { "mitigation": 0.0, "type": "none" }       # can't block while recovering
        _:
            return { "mitigation": 0.0, "type": "none" }
```

---

## 6. Implementation Checklist

### Phase 1 — Controller Bindings
- [ ] Add gamepad input actions in `InputSetup.gd` (Xbox/PS button mappings)
- [ ] Verify `ControlMap.gd` action names match gamepad input actions
- [ ] Test: all strikes trigger via controller

### Phase 2 — MoveData Resource
- [ ] Create `MoveData.gd` class (new)
- [ ] Create `.tres` files for all 18+ stand-up strikes (from docs/move-data-and-combos.md)
- [ ] Create `.tres` files for clinch, GNP, takedown, defense moves
- [ ] Create a `MoveDatabase` singleton to load and query all moves by ID
- [ ] Update `StrikePlanner.plan()` to accept `MoveData` instead of strike_type int

### Phase 3 — AttackState
- [ ] Create `AttackState.gd` (new)
- [ ] Integrate into `FighterStateMachine` (replace `_attack_cooldown`)
- [ ] Wire `process_action()` to route through `AttackState.start_attack()`
- [ ] Wire `_update_*()` state functions to call `AttackState.advance_frame()`
- [ ] Wire contact detection to check only during ACTIVE phase

### Phase 4 — Phase Modifiers
- [ ] Add `PHASE_VULNERABILITY` and `PHASE_COUNTER_THRESHOLD` to `CombatGlobals.gd`
- [ ] Update `ImpactCalculator.resolve_strike()` to read defender phase
- [ ] Update `BlockSystem.gd` for phase-aware blocking
- [ ] Update `FighterStateMachine._apply_strike_result()` to factor phase-based counter detection

### Phase 5 — StrikingController (new abstraction)
- [ ] Create `StrikingController.gd` — orchestrates the plan → start → advance → contact pipeline
- [ ] Move limb-to-move mapping out of `FighterStateMachine` into `StrikingController`

### Phase 6 — Cleanup
- [ ] Delete `StrikeConfig` class from `ImpactCalculator.gd`
- [ ] Delete all `_plan_*()` functions from `StrikePlanner.gd` (replaced by MoveData + trajectory functions)
- [ ] Update all tests (test_fighter_data.gd, test_fighter_character.gd, etc.)
- [ ] Run full test suite: `105/105` must still pass

---

## 7. Key Design Rules (Summary)

1. **One limb, one attack at a time** — No overriding. You commit to the strike phase cycle.
2. **Contact only during ACTIVE frames** — The `hit_already_landed` flag prevents double-hit.
3. **Windup = most vulnerable to counter** — Getting hit while winding up is a counter and interrupts your attack.
4. **Recovery = most vulnerable to punishment** — Can't block, ×1.5 damage taken.
5. **Counter detection is phase-based** — No separate "counter flag" logic. If the defender is in WINDUP or RECOVERY when hit, it's a counter.
6. **Block effectiveness depends on phase** — Full block only from IDLE. Reduced during WINDUP/ACTIVE. Impossible during RECOVERY.
7. **Per-limb tracking** — Left and right arms/legs are independent. You can have right arm recovering while left arm starts winding up.

---

## Appendix A: MoveData Migration (from old StrikePlanner constants)

| Move ID | Startup | Active | Recovery | Reach | Base Dmg | Stamina | Stun | Trajectory |
|---------|---------|--------|----------|-------|----------|---------|------|------------|
| jab | 3 | 3 | 5 | 1.2 | 5 | 2.0 | 1 | JAB_TRAJ |
| cross | 5 | 4 | 7 | 1.3 | 9 | 3.5 | 1 | CROSS_TRAJ |
| hook | 7 | 4 | 9 | 1.0 | 12 | 4.0 | 2 | HOOK_TRAJ |
| uppercut | 6 | 4 | 8 | 0.8 | 11 | 4.0 | 1 | UPPERCUT_TRAJ |
| overhand | 9 | 5 | 12 | 1.1 | 14 | 5.0 | 3 | OVERHAND_TRAJ |
| front_kick | 7 | 4 | 8 | 1.6 | 8 | 3.0 | 1 | FRONT_KICK_TRAJ |
| roundhouse | 10 | 5 | 14 | 1.8 | 14 | 5.5 | 2 | ROUNDHOUSE_TRAJ |
| leg_kick | 7 | 4 | 8 | 1.5 | 7 | 3.5 | 0 | LEG_KICK_TRAJ |
| head_kick | 13 | 5 | 18 | 1.8 | 18 | 7.0 | 3 | HEAD_KICK_TRAJ |
| switch_kick | 14 | 5 | 16 | 1.8 | 15 | 6.5 | 2 | SWITCH_KICK_TRAJ |
| knee | 4 | 3 | 6 | 0.6 | 10 | 3.0 | 2 | KNEE_TRAJ |
| elbow | 5 | 3 | 8 | 0.5 | 13 | 3.5 | 2 | ELBOW_TRAJ |

> Note: These values are carried forward from `docs/move-data-and-combos.md` (the authoritative source), resolving the discrepancy where `ImpactCalculator` had jab recovery=4 while `docs/move-data-and-combos.md` and `threejs/data-tables.md` both say recovery=5. The document is the source of truth.

## Appendix B: UFC 6 Controller Reference

For reference, this maps directly to EA SPORTS UFC 6's **Standard** control layout:

| UFC 6 Action | GU Button | Notes |
|-------------|-----------|-------|
| Lead Hand | A / Cross | Same |
| Rear Hand | B / Circle | Same |
| Lead Kick | X / Square | Same |
| Rear Kick | Y / Triangle | Same |
| Head Movement | RS | Same |
| Block | RT / R2 | Same |
| High Mod | LB / L1 | Same |
| Low Mod | RB / R1 | Same |
| Perfect/Lunge | LT / L2 | Same (UFC 6 uses this for lunges and special strikes) |
| Parry | RS Click | Same |
| Takedown (LS→ + A + LT) | LS→ + A + LT | Same |
| Clinch Entry (LS→ + A + RB) | LS→ + A + RB | Same |
| Sprawl (RT + RS↓) | RT + RS↓ | Same |
