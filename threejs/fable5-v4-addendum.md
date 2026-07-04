# V4 Prompt — Strike Queue, Cancels & Feints (ADDITION to previous V4)

> **Build on top of:** Your previous V3 prototype + the 4 architectural changes from the previous V4 prompt (per-limb AttackState, phase vulnerability, phase-aware blocking, MoveData unification).
> **Context:** The current prototype has a single `this.buffered` slot. Replace it with a full strike queue system that also handles feints (windup cancels) and recovery cancels (combo links).

---

## Change 5: StrikeQueue — Replace `this.buffered`

**Remove** the single `this.buffered` field from the Sim class.

**Add** a `strikeQueue` array to each Sim:

```javascript
this.strikeQueue = [];          // Array of { moveId, targetZone, timestamp, limb }
this.maxQueue = 3;              // SPD/15 + 2 (set on fighter creation)
this.dispatchHistory = [];      // Array of moveId strings — for combo detection
```

**Replace the buffered input logic:**

OLD (V3):
```javascript
if (inp.attack){
  if (this.canAct() && this.stun<=2 && !this.block) this.startMove(inp.attack, foe);
  else if (this.phase==='recovery' && this.pf<=8) this.buffered=inp.attack;
}
```

NEW:
```javascript
if (inp.attack && this.stun <= 2) {
  this.queueMove(inp.attack, 'head', {});
}
```

### Queue Operations

```javascript
queueMove(moveId, targetZone, modifiers) {
  const m = MOVES[moveId];
  if (!m) return false;
  // Don't queue same limb twice in a row
  if (this.strikeQueue.length > 0 &&
      this.strikeQueue[this.strikeQueue.length-1].limb === m.limb)
    return false;
  if (this.strikeQueue.length >= this.maxQueue) return false;
  this.strikeQueue.push({ moveId, targetZone, modifiers:modifiers||{},
    timestamp: performance.now()/1000, limb: m.limb });
  return true;
}

dequeueNext() {
  if (this.strikeQueue.length === 0) return null;
  const entry = this.strikeQueue[0];
  // TTL check: 0.8s
  if (performance.now()/1000 - entry.timestamp > 0.8) {
    this.strikeQueue.shift();
    return this.dequeueNext();  // try next
  }
  // Check limb availability
  const ls = this.limbs[entry.limb];
  if (!ls || ls.phase === 'idle') {
    this.strikeQueue.shift();
    return entry;
  }
  // ★ RECOVERY CANCEL: if limb is in recovery and within cancel window
  if (ls.phase === 'recovery') {
    const cancelFrames = ls.pfMax * 0.6;  // first 60% of recovery
    if (ls.pf > ls.pfMax - cancelFrames) {
      // Interrupt recovery, start new move
      this.interruptLimb(entry.limb);
      this.strikeQueue.shift();
      entry._cancelSurcharge = 0.3;
      return entry;
    }
  }
  return null;  // limb busy, wait
}
```

### Queue Integration Into the Move Phase Machine

In `update()`, after advancing the phase machine:

```javascript
// Try to dequeue next move
if (this.state === 'idle' && this.stun <= 2) {
  const next = this.dequeueNext();
  if (next) {
    this.startMove(next.moveId, foe);
    // Track for combo detection
    this.dispatchHistory.push(next.moveId);
    if (this.dispatchHistory.length > 8) this.dispatchHistory.shift();
    // Check combo
    const combo = checkCombo(this.dispatchHistory);
    if (combo) {
      this._activeCombo = combo;
      fx.callout(combo.name, '#f2c14e');
    }
  }
}
```

### Queue Drain Events

```javascript
// In applyStun — drain on tier 3+
if (tier >= 3) { this.strikeQueue = []; this.dispatchHistory = []; }

// In update, when block is pressed:
if (inp.block) { this.strikeQueue = []; this.dispatchHistory = []; }
```

---

## Change 6: Feint (Windup Cancel)

**Feint trigger:** Press block while any limb is in `startup` (not `active` or `recovery`).

```javascript
// In update(), checked at the START before block is applied to defense:
feintLimb: null,
if (inp.block && this.stun <= 1) {
  // Check if any limb is in startup
  for (const [lk, ls] of Object.entries(this.limbs)) {
    if (ls.phase === 'startup') {
      this.executeFeint(lk);
      break;
    }
  }
}

executeFeint(limbKey) {
  const ls = this.limbs[limbKey];
  if (!ls || ls.phase !== 'startup') return;
  // Cost: 40% of the move's stamina
  const move = ls.move;
  const feintCost = (move.stam * 0.4) * (this.gassed() ? 1.3 : 1);
  this.st = Math.max(0, this.st - feintCost);
  // Interrupt the limb
  ls.phase = 'idle'; ls.move = null; ls.pf = 0; ls.pfMax = 0;
  ls.hitDone = false; ls.landed = false;
  // Queue is preserved — next entry executes when limb becomes available
  fx.callout('FEINT!', '#9fe3ff');
}
```

**Key rule:** Feinting interrupts only ONE limb. Other limbs continue. You can have right arm feinting while left arm hooks.

---

## Change 7: Recovery Cancel

Already handled in `dequeueNext()` above. When queuing a move that uses the same limb currently in recovery:

```javascript
// In dequeueNext, if limb is in recovery and within first 60%:
// 1. Interrupt the recovery (limb → idle)
// 2. The returned entry has _cancelSurcharge = 0.3
// 3. In startMove, apply the surcharge:
if (entry._cancelSurcharge) {
  this.st = Math.max(0, this.st - move.stam * entry._cancelSurcharge);
}
// 4. The limb immediately starts the new move's startup
```

---

## Change 8: Combo Detection

```javascript
const COMBOS = {
  '1-2':      { seq:['jab','cross'],          ender:'cross', dmg:0.05, rec:0.05 },
  '2-3':      { seq:['cross','hook'],          ender:'hook',  dmg:0.05, rec:0.05 },
  '1-2-3':    { seq:['jab','cross','hook'],    ender:'hook',  dmg:0.10, rec:0.10 },
  '1-2-4':    { seq:['jab','cross','uppercut'], ender:'uppercut', dmg:0.15, rec:0.10 },
  'low-high': { seq:['leg_kick','roundhouse'],  ender:'roundhouse', dmg:0.10, rec:0.08 },
  'teep-cross':{seq:['front_kick','cross'],     ender:'cross', dmg:0.0,  rec:0.08 },
};

function checkCombo(history) {
  for (const [id, c] of Object.entries(combos)) {
    if (history.length < c.seq.length) continue;
    const start = history.length - c.seq.length;
    let match = true;
    for (let i = 0; i < c.seq.length; i++) {
      if (history[start + i] !== c.seq[i]) { match = false; break; }
    }
    if (match && c.ender === history[history.length-1]) {
      return { id, damageBonus: c.dmg, recoveryReduction: c.rec, ender: c.ender };
    }
  }
  return null;
}
```

On combo detection:
- Set `this._activeCombo = combo` — lasts until the ender's recovery ends
- During the ender's resolveContact: apply `damageBonus` to raw damage
- During the ender's recovery: apply `recoveryReduction` to frame count
- Visual: `fx.callout('COMBO 1-2-3!', '#f2c14e')` with the combo name

---

## What to Change Visually

### Queue HUD
After the status text (`document.getElementById('s1')`), add an inline display:

```javascript
// Next 3 queued moves as small text:
//   NEXT: JAB → CROSS → HOOK
```

### Feint Indicator
When a limb enters startup, show a small "FEINT: BLOCK" hint near the health bar. Only show if the player has stamina >= 40% of the move's cost.

### Cancel Window Bar
When a limb enters recovery, show a small bar that shrinks for the cancel window:
- First 60%: green section (growing red from the right as time passes)
- Last 40%: solid red (can't cancel)

---

## Verification Checklist (Add to Previous V4 List)

| Test | Expected |
|------|----------|
| Queue jab, cross, hook rapidly | All 3 execute as limbs become available — no inputs lost |
| Queue fills (3 entries) | 4th input rejected — visual feedback |
| Block during cross windup | Cross cancels (feint), 40% stamina cost, queue preserved |
| Queue cross during jab recovery | Cross executes immediately via recovery cancel, 30% surcharge |
| Queue same limb twice | Second entry rejected |
| Land jab → cross → hook | Combo 1-2-3 detected, ender (hook) gets +10% damage, -10% recovery |
| Hit while in startup | Feint NOT possible (block pressed late → counts as defense, not feint) |
| Stun tier 3+ | Queue drained completely |

---

## Non-Goals (Keep V3 Behaviors)

- Don't change the FK velocity system
- Don't change the balance economy
- Don't change the cage physics
- Don't change the arena visuals
- Don't change the roster or forge
- Don't change the AI (AI doesn't need to use the queue — it can keep calling startMove directly)
