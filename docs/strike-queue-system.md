# Gladiator Ultra — Strike Queue System

> **Core concept:** A FIFO queue of pending attacks that executes moves as limbs become available. Enables combo chaining, input buffering during recovery, and per-limb independent execution.
> **Design rule 1:** The queue is NOT a macro. The player must press each button. The queue just prevents lost inputs during recovery frames.
> **Design rule 2:** Queue is drained on block, stun (tier 3+), or knockdown. No "queuing through hitstun."
> **Design rule 3:** Maximum queue depth = SPD/15 + 2 — speed stat directly limits combo length.
> **Design rule 4:** Any move in WINDUP can be **feinted** (cancelled into idle) by pressing block. Costs 40% of the move's stamina.
> **Design rule 5:** Any move in RECOVERY can be **cancelled** into a new move by queuing during the cancel window (first 60% of recovery). The cancel skips remaining recovery.
> **Design rule 6:** Feints and cancels share the same underlying mechanism: interrupting one phase to start another. The difference is timing and cost.

---

## 1. Architecture

### 1.1 StrikeQueue — New Singleton

```gdscript
# scripts/control/StrikeQueue.gd
# Per-fighter input queue. Stores pending attacks and dispatches them
# to the per-limb AttackState as limbs become available.
extends RefCounted

signal move_queued(move_id: String, position: int)  # position in queue (0 = next)
signal move_dequeued(move_id: String, reason: String)  # dispatched, cancelled, drained
signal combo_detected(combo_id: String)  # a full combo sequence matched

class QueueEntry:
    var move_id: String = ""
    var target_zone: String = "head"     # resolved at queue-time, not execution-time
    var modifiers: Dictionary = {}        # { perfect: false, high: false, low: false }
    var timestamp: float = 0.0            # when it was queued (for timing-based combos)
    var limb: String = ""                 # resolved at queue time from MOVES[move_id].limb

const MAX_QUEUE_DEFAULT: int = 5

var _queue: Array[QueueEntry] = []
var _max_queue: int = MAX_QUEUE_DEFAULT
var _combo_window: float = 0.6           # seconds — max gap between queued entries for combo detection
var _input_buffer_window: float = 0.4    # seconds — how long an input stays valid
```

### 1.2 Queue Operations

```gdscript
# ── Queue a move ──
# Called by ControlMap / humanInput when a strike button is pressed.
# Returns false if the queue is full.
func queue_move(move_id: String, target_zone: String = "head",
                modifiers: Dictionary = {}) -> bool:
    var move_data = _get_move_data(move_id)
    if not move_data:
        return false

    var limb = move_data.limb  # from unified MOVES config: "rightArm", "leftArm", "rightLeg"

    # Don't queue the same limb twice in a row if the first hasn't started
    # (prevents rapid mashing from stacking the same limb)
    if _queue.size() > 0 and _queue[-1].limb == limb:
        return false

    if _queue.size() >= _max_queue:
        return false  # queue full — input is lost

    var entry = QueueEntry.new()
    entry.move_id = move_id
    entry.target_zone = target_zone
    entry.modifiers = modifiers
    entry.timestamp = Time.get_ticks_usec() / 1000000.0
    entry.limb = limb

    _queue.append(entry)
    move_queued.emit(move_id, _queue.size() - 1)
    return true

# ── Dequeue next executable move ──
# Called by FighterStateMachine each tick.
# Returns a QueueEntry if a move can start now, or null if nothing is ready.
func dequeue_next(attack_state: AttackState) -> QueueEntry:
    if _queue.is_empty():
        return null

    var entry = _queue[0]

    # Check if the required limb is available
    if not attack_state.is_limb_available(entry.limb):
        return null  # wait — limb is busy

    # Check if player is in a state that allows starting this move
    # (handled by the caller, but we skip blocked entries)
    _queue.pop_front()
    move_dequeued.emit(entry.move_id, "dispatched")
    return entry

# ── Drain the queue (on block, stun, knockdown) ──
func drain(reason: String = "interrupted") -> void:
    for entry in _queue:
        move_dequeued.emit(entry.move_id, reason)
    _queue.clear()

# ── Query ──
func is_idle() -> bool:
    return _queue.is_empty()

func peek_next() -> String:
    return _queue[0].move_id if _queue.size() > 0 else ""

func queue_size() -> int:
    return _queue.size()

# ── Combo detection ──
# The queue dispatch history is checked against combo tree definitions.
# This is called by FighterStateMachine when a move is dequeued.
func check_combo(dispatch_history: Array[String]) -> Dictionary:
    # dispatch_history = ["jab", "cross", "hook", ...]
    # Check all combo tree patterns that match the end of the history
    for combo_id in _COMBO_TREES:
        var pattern = _COMBO_TREES[combo_id].sequence  # ["jab", "cross"]
        if _matches_suffix(dispatch_history, pattern):
            var timing_valid = _check_combo_timing(dispatch_history, combo_id)
            if timing_valid:
                combo_detected.emit(combo_id)
                return { "id": combo_id, "bonus": _COMBO_TREES[combo_id].bonus }

    return {}

# ── Internal ──
func _matches_suffix(history: Array[String], pattern: Array[String]) -> bool:
    if history.size() < pattern.size():
        return false
    var start = history.size() - pattern.size()
    for i in range(pattern.size()):
        if history[start + i] != pattern[i]:
            return false
    return true

func _check_combo_timing(history: Array[String], combo_id: String) -> bool:
    # Each entry in dispatch_history has a timestamp.
    # Combos require all moves to have been dispatched within the combo window.
    var combo = _COMBO_TREES[combo_id]
    var window = combo.timing_window  # seconds
    # Check time between first and last move in the combo
    # ... implementation depends on how timestamps are stored
    return true  # simplified — full implementation tracks real timestamps
```

---

## 2. Integration With Per-Limb AttackState

### 2.1 FighterStateMachine — Updated Process Loop

```gdscript
# Inside FighterStateMachine.gd
var strike_queue: StrikeQueue = StrikeQueue.new()
var dispatch_history: Array[Dictionary] = []  # [{ move_id, timestamp }]

func _process_combat(delta: float) -> void:
    # 1. Advance per-limb attack phases
    attack_state.advance_all_frames()

    # 2. Try to dequeue the next move
    var next = strike_queue.dequeue_next(attack_state)
    if next:
        _execute_queued_move(next)

    # 3. Update combo state
    _check_combo_state()

    # 4. Clean stale dispatch history (older than 2s)
    var now = Time.get_ticks_usec() / 1000000.0
    while dispatch_history.size() > 0 and \
          (now - dispatch_history[0].timestamp) > 2.0:
        dispatch_history.pop_front()

func _execute_queued_move(entry: QueueEntry) -> void:
    # Record dispatch for combo detection
    dispatch_history.append({
        "move_id": entry.move_id,
        "timestamp": Time.get_ticks_usec() / 1000000.0
    })

    # Check combo
    var combo_result = strike_queue.check_combo(
        dispatch_history.map(func(d): return d.move_id)
    )

    # Build stats mod with combo bonuses
    var stats = _build_stats_mod()
    if combo_result and not combo_result.is_empty():
        var bonus = combo_result.bonus
        stats.combo_penalty = 1.0 - (bonus.recovery_reduction or 0.0)
        stats.damage_mult = 1.0 + (bonus.damage_bonus or 0.0)

    # Plan the move
    var move_data = get_move_data(entry.move_id)
    var plan = StrikePlanner.plan(move_data, stats)

    # Start phase on the correct limb
    attack_state.start_attack(entry.limb, plan)
```

### 2.2 Input Routing — ControlMap / humanInput Update

```gdscript
# Instead of calling startMove() directly, queue the move:

# OLD:
# if (this.canAct() && this.stun<=2 && !this.block) this.startMove(inp.attack, foe);
# else if (this.phase==='recovery' && this.pf<=8) this.buffered=inp.attack;

# NEW:
if inp.attack:
    # Always queue — the queue handles limb availability and buffering
    var queued = strike_queue.queue_move(inp.attack, resolve_target_zone(inp.attack, modifiers), modifiers)
    if not queued:
        # Queue full — input is lost. Could flash a UI indicator.
        pass
```

---

## 3. Combo Integration

### 3.1 Combo Tree Data (from move-data-and-combos.md §5)

```gdscript
const _COMBO_TREES = {
    # Level 1 (2-hit)
    "1-2": {
        "sequence": ["jab", "cross"],
        "timing_window": 0.6,
        "bonus": { "recovery_reduction": 0.05 }
    },
    "2-3": {
        "sequence": ["cross", "hook"],
        "timing_window": 0.5,
        "bonus": { "recovery_reduction": 0.05 }
    },
    # Level 2 (3-hit)
    "1-2-3": {
        "sequence": ["jab", "cross", "hook"],
        "timing_window": 0.6,
        "bonus": { "recovery_reduction": 0.10, "damage_bonus": 0.10, "ender": "hook" }
    },
    "1-2-4": {
        "sequence": ["jab", "cross", "uppercut"],
        "timing_window": 0.5,
        "bonus": { "recovery_reduction": 0.10, "damage_bonus": 0.15, "ender": "uppercut" }
    },
    # Level 3 (4-hit)
    "1-2-3-5": {
        "sequence": ["jab", "cross", "hook", "overhand"],
        "timing_window": 0.6,
        "bonus": { "recovery_reduction": 0.15, "damage_bonus": 0.20, "ender": "overhand" }
    },
    # Kick combos
    "low-high": {
        "sequence": ["leg_kick", "roundhouse"],
        "timing_window": 0.6,
        "bonus": { "hit_chance_bonus": 0.15 }
    },
    "teep-cross": {
        "sequence": ["front_kick", "cross"],
        "timing_window": 0.7,
        "bonus": { "recovery_reduction": 0.08 }
    },
    # Strike → Takedown
    "jab-double": {
        "sequence": ["jab", "double_leg"],
        "timing_window": 0.5,
        "bonus": { "td_detection_penalty": 0.20, "ender": "double_leg" }
    },
}
```

### 3.2 Combo Bonus Application

When a combo is detected, the bonus applies to the **ender** (last move in the sequence):

| Bonus | Effect | Applies To |
|-------|--------|------------|
| `recovery_reduction` | ×(1 - value) recovery frames on ender | Ender's recovery phase |
| `damage_bonus` | ×(1 + value) damage on ender | Ender's active phase |
| `hit_chance_bonus` | +(value) accuracy on ender | Ender's contact check |
| `td_detection_penalty` | -(value) opponent's TD detection chance | Takedown ender only |

### 3.3 Visual Combo Indicator

```gdscript
# Display in HUD when a combo is active:
# - Combo counter: "2", "3", "4" 
# - Combo name: "1-2-3" or "JAB → CROSS → HOOK"
# - Combo progress bar: shows how much time remains in the combo window
# - On completion: flash the combo name + bonus callout ("COMBO BONUS! +20%")
```

---

## 4. Queue Size & Speed Stat

The max queue depth is directly tied to SPD:

```gdscript
# In StrikeQueue._init() or set by FighterData on fighter creation:
func update_max_queue(speed_stat: float) -> void:
    _max_queue = max(2, min(MAX_QUEUE_DEFAULT, int(speed_stat / 15) + 2))
```

| SPD | Max Queue | Combo Length | Feel |
|-----|-----------|--------------|------|
| 0-19 | 2 | Can only buffer 1 follow-up | Slow, labored |
| 20-34 | 3 | Can chain 3 moves | Average |
| 35-49 | 3 | Baseline | Standard |
| 50-64 | 4 | Can chain 4 moves | Snappy |
| 65-79 | 4 | Consistent 4-hit combos | Fast |
| 80-100 | 5 | Full 5-hit chains | Blazing |

**Implied design:** Speed stat isn't just about frame speed — it directly limits how many moves you can chain. A slow fighter can't physically throw 5-punch combos.

---

## 5. Queue Interaction With States

| Fighter State | Queue Behavior | Reason |
|---------------|----------------|--------|
| IDLE | Normal operation | Execute next queued move immediately |
| WINDUP (any limb) | Accepts queue inputs for OTHER limbs + **feint cancel possible** | Right arm winding up → left arm hook can be queued. Press block to feint. |
| ACTIVE (any limb) | Accepts queue inputs | Contact happening, other limbs free. No cancel possible — committed. |
| RECOVERY (any limb) | Accepts queue inputs for ANY limb + **recovery cancel possible** | Buffer window. Queuing a move during first 60% of recovery cancels the rest. |
| Blocking | **Queue is drained instantly** | Blocking resets offensive momentum |
| Feint (block during windup) | Current move cancelled, queue preserved | Feint costs 40% stamina, fighter returns to idle. Next queue entry executes immediately. |
| Stun tier 1-2 | Queue is drained, but can re-queue after stun ends | Dazed but still functional |
| Stun tier 3+ | Queue frozen + drained on entry | Full stun = no offensive capability |
| Stumble | Queue drained | Balance recovery takes priority |
| Down / Getup / KO | Queue drained | Incapacitated |

---

## 6. Cancel & Feint Mechanics

### 6.1 Feint (Windup Cancel)

Trigger: Press **block** while any limb is in WINDUP phase.

```gdscript
# In FighterStateMachine, checked each tick:
func _check_feint_input() -> void:
    if not Input.is_action_just_pressed("action_block"):
        return
    for limb in ["rightArm", "leftArm", "rightLeg", "leftLeg"]:
        if attack_state.get_phase(limb) == CombatGlobals.AttackPhase.WINDUP:
            _execute_feint(limb)
            return  # only feint one limb per frame

func _execute_feint(limb: String) -> void:
    var state = attack_state.get_limb_state(limb)
    var feint_cost = state.strike_plan.stamina_cost * 0.4

    fighter_data.spend_stamina(feint_cost)
    attack_state.interrupt_limb(limb)

    # The feint leaves the fighter in a neutral state on that limb.
    # Other limbs continue unaffected.
    # Visual: the strike snap-back (shoulder jerks back), small dust puff.

    feint_performed.emit(limb, state.move_data.move_id)
```

**Feint effects:**

| Aspect | Effect |
|--------|--------|
| Stamina cost | 40% of the move's base stamina cost |
| Limb state | Interrupted → IDLE |
| Other limbs | Unaffected — can have right arm feinting, left arm attacking |
| Queue | Preserved — next entry still executes when its limb is free |
| Opponent reaction | If opponent was in block/evade startup, they eat the recovery frames of their defense — **feint advantage** |
| Animation | Strike snap-back to guard at 2× speed |
| Sound | Sharp "swish" — fabric/air sound |

### 6.2 Recovery Cancel (Combo Link)

Trigger: Queue a new move during the **cancel window** (first 60% of RECOVERY phase).

```gdscript
# In StrikeQueue, when dequeue checks limb availability:
func dequeue_next(attack_state: AttackState) -> QueueEntry:
    if _queue.is_empty():
        return null

    var entry = _queue[0]

    if not attack_state.is_limb_available(entry.limb):
        # ★ NEW: Check if we can recovery cancel
        var limb_state = attack_state.get_limb_state(entry.limb)
        if limb_state.phase == CombatGlobals.AttackPhase.RECOVERY:
            var cancel_window_frames = limb_state.total_recovery_frames * 0.6
            if limb_state.frame_counter < cancel_window_frames:
                # YES — we can cancel this limb's recovery into the new move
                attack_state.interrupt_limb(entry.limb)
                _queue.pop_front()
                move_dequeued.emit(entry.move_id, "dispatched_via_cancel")
                return entry

        return null  # wait normally

    _queue.pop_front()
    move_dequeued.emit(entry.move_id, "dispatched")
    return entry
```

**Cancel effects:**

| Aspect | Effect |
|--------|--------|
| Stamina cost | Normal move cost + 30% cancel surcharge |
| Limb state | RECOVERY → immediately starts the new move's WINDUP |
| Other limbs | Unaffected |
| Queue | Preserved |
| Frame advantage | Cancelling recovery means you act **frames faster** than letting recovery finish |
| Vulnerability | During the cancel transition (1-2 frames), the limb is in an "interrupted" state — slightly vulnerable (×1.2) |
| Animation | Blended transition: recovery snap cut short, new strike starts from whatever position the limb is in |

### 6.3 Cancel Window vs. Recovery Punish

The cancel window deliberately overlaps with the **opponent's punish window**:

```
RECOVERY PHASE:
├── Cancel Window (60%) ──────┤├── Full Recovery (40%) ─┤
│   • Can cancel into new move  │  • Can't cancel
│   • Opponent can punish       │  • Opponent CAN punish (×1.5 vuln)
│   • ×1.3 vuln (vs ×1.5 full) │
└──────────────────────────────┘└─────────────────────────┘
```

If you cancel early, you get the new move out faster but at ×1.3 vulnerability instead of ×1.5. If you wait, you're more vulnerable but can't cancel. **This is a risk-reward decision.**

### 6.4 Feint Chain (Advanced)

A feint can be followed by a second feint on a different limb:

```
Queue: [jab(feint), cross(feint), hook]

Tick 1:  leftArm WINDUP (jab)
Tick 2:  Block pressed → jab feinted (40% stam cost)
Tick 3:  rightArm WINDUP (cross) — immediately dequeued
Tick 4:  Block pressed → cross feinted (40% stam cost)
Tick 5:  leftArm WINDUP (hook) — left arm is free again
Tick 8:  hook goes ACTIVE → lands
```

This is the "triple feint" — expensive (120% of 3 moves' stamina), flashy, and leaves the opponent guessing. Limited by SPD-based max queue depth and stamina.

### 6.5 Cancel Types Summary

| Type | Trigger | Phase Interrupted | Cost | Advantage |
|------|---------|-------------------|------|-----------|
| **Feint** (windup cancel) | Block during WINDUP | WINDUP → IDLE | 40% move stamina | Opponent may have committed to defense → frame advantage |
| **Recovery cancel** | Queue move during first 60% of RECOVERY | RECOVERY → new WINDUP | 100% move stamina + 30% surcharge | Acts frames earlier than waiting for full recovery |
| **Active cancel** (locked) | N/A — cannot cancel during ACTIVE | — | — | Strikes in flight must resolve. Committed. |

### 6.6 Feint/Cancel HUD Indicators

```gdscript
# When a limb enters WINDUP:
#   A small "FEINT: BLOCK" indicator appears below the health bar
#   Duration: the windup's remaining frames
#   Only shown if the player has enough stamina to feint

# When a limb enters RECOVERY:
#   A "CANCEL WINDOW" bar appears — shrinks as the cancel window closes
#   First 60%: green (cancel available)
#   Last 40%: red (full recovery, can't cancel, vulnerable)
```

---

## 6. Queue Display (HUD)

```gdscript
# Visual indicator showing the next 3 queued moves.
# Displayed as small icons or text below the fighter's health bar:
#
#   NEXT: [JAB] [CROSS] [HOOK]
#        ← 3 frames →
#
# The NEXT indicator shows:
#   - Move name / icon for the next 3 entries
#   - A small bar showing time until the next move executes
#   - Dimmed entries = waiting for limb availability
#
# On combo activation, swap to combo display:
#
#   COMBO: 1-2-3  [+10%]
#   ████████░░░░
```

---

## 7. Implementation Checklist

- [ ] `StrikeQueue.gd` — QueueEntry class, queue/dequeue/drain operations
- [ ] `StrikeQueue.gd` — SPD-based max queue size
- [ ] `StrikeQueue.gd` — Combo detection via dispatch history matching
- [ ] `StrikeQueue.gd` — Recovery cancel detection in dequeue logic
- [ ] `AttackState.gd` — `is_limb_available(limb)` query method
- [ ] `AttackState.gd` — `interrupt_limb(limb)` method (for feint/cancel)
- [ ] `AttackState.gd` — `get_limb_state(limb)` query with frame counter access
- [ ] `FighterStateMachine.gd` — Updated process loop to dequeue each tick
- [ ] `FighterStateMachine.gd` — dispatch_history tracking for combo detection
- [ ] `FighterStateMachine.gd` — Queue drain on stun/block/knockdown
- [ ] `FighterStateMachine.gd` — Feint check (block during any limb's WINDUP)
- [ ] `ControlMap.gd` / `humanInput()` — Route all strike inputs through `queue_move()`
- [ ] `StrikePlanner.gd` — Apply combo bonuses to ender
- [ ] `StrikePlanner.gd` — Apply cancel surcharge to stamina cost
- [ ] HUD — Queue display (next 3 moves)
- [ ] HUD — Combo indicator (name + bonus callout)
- [ ] HUD — Feint indicator ("FEINT: BLOCK" during windup)
- [ ] HUD — Cancel window bar (green/red during recovery)
- [ ] Test: queue accepts inputs during recovery
- [ ] Test: queue drains on block
- [ ] Test: queue drains on stun tier 3+
- [ ] Test: SPD 20 → max queue = 3, SPD 88 → max queue = 5
- [ ] Test: combo detection fires on 1-2-3 sequence
- [ ] Test: different limbs execute independently from queue
- [ ] Test: feint cancels windup, costs 40% stamina, preserves queue
- [ ] Test: recovery cancel skips remaining recovery, costs 30% surcharge
- [ ] Test: same limb feinted twice in a row (block spam) works
- [ ] Test: feint advantage — opponent in block startup takes longer to recover

---

## 8. Edge Cases

| Edge Case | Resolution |
|-----------|------------|
| Same limb queued twice consecutively | Second entry is rejected — single queue entry per limb |
| All 4 limbs busy | Queue holds until a limb frees — no input loss (within max queue size) |
| Queue full, player mashes | Input lost — consider subtle audio cue (muffled thud) or UI flash |
| Player queues then immediately blocks | Queue is drained on block press — block always beats queued attacks |
| Combo detected but ender misses | Combo bonus still applies to the attempt — bonus is about execution, not result |
| SPD changes mid-fight (gassed) | Max queue stays at the higher value — you don't "un-learn" combo length when tired |
| Switch stance mid-combo | Queue is preserved — stance affects which limb is lead, but limb routing is per-move |
