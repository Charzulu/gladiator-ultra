# V5 — Strike Queue + Feint + Cancel System

Add a strike queue to replace `this.buffered`. This is self-contained — no new classes, no architectural refactors, no per-limb tracking. Everything goes in the existing `Sim` class.

---

## 1. Add These Fields to the Sim Constructor

```javascript
// Remove this:
this.buffered = null;

// Add these:
this.strikeQueue = [];          // FIFO queue of pending attacks
this.maxQueue = 3;              // SPD/15 + 2, set per fighter at creation
this.dispatchHistory = [];      // last 8 move IDs for combo detection
this._feintedThisFrame = false; // prevent double-feint
```

Set `maxQueue` per fighter after constructor:
```javascript
// Call this after new Sim():
sim.maxQueue = Math.max(2, Math.min(5, Math.floor(sim.def.SPD / 15) + 2));
```

---

## 2. Queue Methods (Add to Sim Prototype)

```javascript
queueMove(moveId) {
  const m = MOVES[moveId];
  if (!m) return false;
  // Don't queue same limb twice in a row (prevents mashing the same punch)
  if (this.strikeQueue.length > 0) {
    const last = MOVES[this.strikeQueue[this.strikeQueue.length-1]];
    if (last && last.limb === m.limb) return false;
  }
  if (this.strikeQueue.length >= this.maxQueue) return false;
  this.strikeQueue.push(moveId);
  return true;
}

dequeueNext() {
  if (this.strikeQueue.length === 0) return null;
  const moveId = this.strikeQueue[0];
  const m = MOVES[moveId];
  if (!m) { this.strikeQueue.shift(); return this.dequeueNext(); }

  // Check if this move's limb is free
  // limb 'lead' = free when phase==='none'
  // limb 'rear' = free when phase==='none'
  // limb 'legRear' = free when phase==='none'
  const limbFree = (this.phase === 'none');

  if (limbFree) {
    this.strikeQueue.shift();
    return moveId;
  }

  // ★ RECOVERY CANCEL: if currently in recovery and within cancel window
  if (this.phase === 'recovery') {
    const cancelFrames = this.pfMax * 0.6;  // first 60% of recovery
    if (this.pf > this.pfMax - cancelFrames) {
      // Cancel recovery into the new move
      this.move = null;
      this.phase = 'none';
      this.pf = 0;
      this.strikeQueue.shift();
      return { moveId: moveId, isCancel: true };  // signal to caller
    }
  }

  return null;  // busy, wait
}

drainQueue() {
  this.strikeQueue = [];
  this.dispatchHistory = [];
}

getQueueDisplay() {
  // Returns next up to 3 move names for HUD
  return this.strikeQueue.slice(0, 3);
}
```

---

## 3. Feint — Windup Cancel

Replace the block-trigger section at the top of `update()`. Currently block is only defensive. Now it also checks for feint:

```javascript
// ── FEINT CHECK: Block during startup cancels the move ──
this._feintedThisFrame = false;
if (inp.block && this.phase === 'startup' && this.move && this.stun <= 1) {
  // Feint: cancel startup, pay 40% stamina
  const feintCost = this.move.stam * 0.4 * (this.gassed() ? 1.3 : 1);
  this.st = Math.max(0, this.st - feintCost);
  this.move = null;
  this.phase = 'none';
  this.pf = 0;
  this.state = 'idle';
  this._feintedThisFrame = true;
  fx.callout('FEINT!', '#9fe3ff');
  snd(220, 0.03, 0.08);
}
// ── Only apply defensive block if NOT feinting ──
if (!this._feintedThisFrame) {
  this.block = !!inp.block && this.canDefend();
}
```

---

## 4. Recovery Cancel — Queue Integration

In `update()`, replace the attack input section:

```javascript
// OLD:
// if (inp.attack) {
//   if (this.canAct() && this.stun<=2 && !this.block) this.startMove(inp.attack, foe);
//   else if (this.phase==='recovery' && this.pf<=8) this.buffered=inp.attack;
// }

// NEW:
if (inp.attack && this.stun <= 2) {
  this.queueMove(inp.attack);
}
```

Then, after the move phase machine advances, add a queue dequeue attempt:

```javascript
// ── Move phase machine (existing code) ──
// ... keep all existing phase logic ...

// ── NEW: Try to dequeue next move ──
if (this.state === 'idle' || this.phase === 'none') {
  const next = this.dequeueNext();
  if (next) {
    let cancelSurcharge = 0;
    let moveId = next;
    if (typeof next === 'object' && next.isCancel) {
      moveId = next.moveId;
      cancelSurcharge = 0.3;
      snd(380, 0.02, 0.06);  // cancel whoosh
    }
    this.startMove(moveId, foe);
    if (cancelSurcharge > 0) {
      this.st = Math.max(0, this.st - MOVES[moveId].stam * cancelSurcharge);
    }
    // Track for combo detection
    this.dispatchHistory.push(moveId);
    if (this.dispatchHistory.length > 8) this.dispatchHistory.shift();
    this._checkCombo();
  }
}
```

---

## 5. Combo Detection

```javascript
// Add to Sim prototype:
_checkCombo() {
  const combos = {
    '1-2':      [['jab','cross'], 0.05],
    '2-3':      [['cross','hook'], 0.05],
    '1-2-3':    [['jab','cross','hook'], 0.10],
    '1-2-4':    [['jab','cross','uppercut'], 0.10],
    'low-high': [['leg_kick','roundhouse'], 0.08],
    'teep-cross':[['front_kick','cross'], 0.05],
  };
  for (const [name, [seq, dmgBonus]] of Object.entries(combos)) {
    if (this.dispatchHistory.length < seq.length) continue;
    const start = this.dispatchHistory.length - seq.length;
    let match = true;
    for (let i = 0; i < seq.length; i++) {
      if (this.dispatchHistory[start + i] !== seq[i]) { match = false; break; }
    }
    if (match) {
      this._comboActive = { name, dmgBonus, ender: seq[seq.length-1] };
      fx.callout('COMBO ' + name + '!', '#f2c14e');
      return;
    }
  }
}
```

Then in `resolveContact()`, when the attacker has an active combo and the strike matches the ender:
```javascript
if (att._comboActive && att.move && att.move.n === MOVES[att._comboActive.ender]?.n) {
  raw *= (1 + att._comboActive.dmgBonus);
  att._comboActive = null;  // one-time bonus
}
```

---

## 6. Queue Drain Events

In `applyStun()`:
```javascript
if (tier >= 3) {
  this.interrupt();
  this.drainQueue();  // ★ ADD
  // ... existing code ...
}
```

In `update()`, when block is held and NOT feinting:
```javascript
if (this.block && !this._feintedThisFrame) {
  this.drainQueue();  // ★ ADD — blocking drains offense queue
}
```

---

## 7. HUD — Queue Display

In `hud()`, add after the status text:

```javascript
// Queue display
for (const [f, prefix] of [[F1,'q1'],[F2,'q2']]) {
  const queue = f.getQueueDisplay();
  const el = document.getElementById(prefix);
  if (el) {
    el.textContent = queue.length ? 'NEXT: ' + queue.map(id => MOVES[id]?.n||id).join(' → ') : '';
  }
}
```

Add two HTML elements in the HUD section:
```html
<div id="q1" class="queue" style="font-size:9px;letter-spacing:1px;margin-top:2px;color:var(--gold)"></div>
<div id="q2" class="queue" style="font-size:9px;letter-spacing:1px;margin-top:2px;color:var(--gold);text-align:right"></div>
```

---

## 8. How to Verify It Works

| Test | How | Expected |
|------|-----|----------|
| Queue accumulates | Press J, K, U rapidly | All 3 queue up, execute in order |
| No same-limb spam | Press J (jab=lead), J again | Second J rejected (same limb) |
| Buffer during recovery | Throw a hook, press K during recovery | Cross queues, executes when idle |
| Recovery cancel | Queue cross during first 60% of hook's recovery | Cross starts immediately, 30% stam surcharge |
| Feint | Press block during jab's startup | Jab cancelled, 40% stam cost, FEINT callout |
| Feint doesn't block | Same frame — feint wins, block doesn't activate | No defensive block |
| Queue drains on stun | Get hit during queue | Queue empties |
| Queue drains on block | Hold block | Queue empties |
| Combo 1-2-3 | Jab → Cross → Hook in sequence | COMBO 1-2-3 callout, +10% damage on hook |
| Max queue = SPD | Ivan Drakov SPD 38 → maxQueue = 3, Damien Cruz SPD 88 → 5 | Different combo lengths per fighter |
| SPD bounds | SPD 15 → maxQueue = 2, SPD 100 → maxQueue = 5 | Floor 2, ceiling 5 |

---

## 9. What NOT to Change

- Don't change the Sim constructor's `phase`/`move`/`pf` fields — the queue wraps around them
- Don't change `resolveContact()`, `strikeVelocity()`, or any damage math
- Don't change the AI (AI doesn't use the queue — it calls `startMove` directly)
- Don't change the renderer, IK, arena, camera, or any visual code
- Don't change the roster, forge, or menu system

Total additions: ~80 lines of new code, ~15 lines changed.
