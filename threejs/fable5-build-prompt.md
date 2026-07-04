# Gladiator Ultra — Fable 5 Build Prompt V2

> **Target:** An enhanced playable Three.js prototype that incorporates the full attack frame system, phase-based modifiers, controller mapping, and expanded combat from the design brief at `docs/attack-frame-system-and-controller.md`. See V1 reference at `threejs/prototype.html`.

---

## 1. What V1 Gets Right (Keep These)

- **60Hz fixed-step sim** with accumulator pattern, seeded RNG
- **FK strike-tip velocity → damage** — arc-length integrated tip velocity through the strike path. Stamina organically reduces velocity (longer frames → lower speed → less damage). Do NOT replace this with a flat multiplier.
- **Sumotori balance economy** — `drainBalance()` on whiff, clean hit, blocked hit (scaled). Empty = stumble state (windmill arms, vulnerable, comic fall on any touch)
- **Per-limb zone pools** — head, body, armL, armR, legL, legR with independent maxHP
- **Block = instant (0-frame) flag** — defense wins ties
- **Guard break** — block stamina depleted → guard broken, damage ×0.7
- **3-KD TKO rule** — three knockdowns = TKO
- **Hitstop** — freezes sim on contact, particles continue
- **Two-bone analytic IK** — all limbs posed through closed-form IK
- **Height-derived reach** — `reachMult` scales all strike ranges
- **AI style profiles** — range preference, weighted menus, startup-reactive blocking
- **Gamepad support** — LS move, RS head movement, LT block, face buttons strikes
- **Per-limb zone damage → stamina/health cap degradation** — body work burns the gas tank permanently; head shots cause permanent damage
- **Character forge** — 300-point pool, style templates, sliders

---

## 2. Architectural Changes Required

### 2.1 Per-Limb AttackState (Replace Single `phase` Field)

**Current (V1):** `Sim.phase` = one of 'none' | 'startup' | 'active' | 'recovery' — tracked per fighter, not per limb.

**Required (V2):** Replace with a **PerLimbAttackState** that tracks 4 limbs independently:

```
limbState = {
  rightArm:  { phase: 'idle'|'windup'|'active'|'recovery', moveKey: null, frameCounter: 0,
               windupFrames: 0, activeFrames: 0, recoveryFrames: 0, hitLanded: false,
               strikePlan: null },
  leftArm:   { ... },
  rightLeg:  { ... },
  leftLeg:   { ... },
}
```

**Rules:**
- Each limb runs independently. Right arm can be in recovery (after a cross) while left arm starts winding up a hook.
- `hitLanded` flag per limb prevents multi-hit on the same swing.
- `canAct(limb)` checks that specific limb is idle.
- `startMove(id, foe)` returns false if the required limb is busy.
- Limb routing: jab→leftArm, cross→rightArm, front_kick→rightLeg, etc.

### 2.2 Phase-Based Vulnerability & Counter Detection

**Current (V1):** No vulnerability modifiers per phase. Counter flag is set separately via `att.counterWin > 0`.

**Required (V2):** Every fighter carries phase-based damage multipliers that `resolveContact()` reads from the **defender**:

```javascript
const PHASE_VULN = {
  idle:     1.0,
  windup:   1.3,   // more vulnerable during telegraph
  active:   1.0,   // normal vulnerability
  recovery: 1.5,   // highly vulnerable — punish window
  interrupted: 1.2,
};
```

**In `resolveContact()`:** Instead of a `isCounter` flag:

```javascript
// Read defender's phase from the limb being hit
const defLimb = limbForZone(move.zone);  // head hits → check closest arm
const defPhase = def.limbState[defLimb].phase;
let isCounter = (defPhase === 'windup' || defPhase === 'recovery');

// Apply phase vulnerability
mit *= PHASE_VULN[defPhase] || 1.0;

// Counter guarantees minimum stun tier 3
if (isCounter) tier = Math.max(tier, 3);
```

### 2.3 Phase-Aware Blocking

**Current (V1):** Block is a simple flag — always effective if held.

**Required (V2):** Block effectiveness depends on the **defender's** current limb phase:

| Defender Phase | Block Mitigation | Stamina Cost | Notes |
|----------------|-----------------|-------------|-------|
| IDLE | -70% | normal | Full guard |
| WINDUP | -40% | ×1.5 | Can't fully protect while loading a strike |
| ACTIVE | -30% | ×2.0 | Committed to the strike — poor defense |
| RECOVERY | **0% (can't block)** | — | Recovery is the punish window; block is disabled |

**Implementation:** `canAct(limb)` and `canBlock()` are separate. Recovery phase sets `block = false` regardless of input.

### 2.4 MoveData as a Uniform Data Structure

**Current (V1):** Moves are a flat `const MOVES = { key: {n, st, ac, rc, ...} }` with per-strike config scattered through `strikeJoints()`, `PATH_CFG`, `STYLE_AI`, etc.

**Required (V2):** Unify into a single `MoveDef` interface that the sim, renderer, and AI all read from:

```javascript
const MOVES = {
  jab: {
    id: 'jab', name: 'JAB', category: 'punch',
    // Frame data (BASE — SPD/stamina scaled at runtime)
    startup: 3, active: 3, recovery: 5,
    // Combat
    baseDamage: 5, staminaCost: 2, baseStunTier: 1,
    cutChance: 0.05, bluntRatio: 1.0,
    // Targeting
    targetZones: ['head', 'body'],
    primarySkill: 'boxing',
    // Trajectory identity
    kind: 'straight', limb: 'leftArm',
    // Arc config for IK bezier path
    arc: { cx: 0.00, cy: 0.04 },
    // Evasion
    evadeType: 'slip',
    // Availability
    availableIn: ['standUp', 'clinch'],
    // Reach
    reach: 1.2,
  },
  // ... all 18+ moves
}
```

**Add missing moves** to reach the full set:
| Added Moves | Category | Kind | Startup | Active | Recovery | Damage |
|-------------|----------|------|---------|--------|----------|--------|
| superman_punch | punch | straight | 12 | 4 | 14 | 13 |
| front_kick_body | kick | push | 8 | 4 | 9 | 9 |
| switch_kick | kick | round | 14 | 5 | 16 | 15 |
| question_mark_kick | kick | high | 15 | 5 | 20 | 17 |
| axe_kick | kick | over | 16 | 5 | 18 | 16 |
| knee | knee | straight | 4 | 3 | 6 | 10 |
| elbow | elbow | hook | 5 | 3 | 8 | 13 |
| body_knee | knee | straight | 4 | 3 | 6 | 9 |

### 2.5 Expanded Strike Menu for AI

**Current (V1):** 6 style profiles with weighted menus.

**Required (V2):** Update all 12 style profiles to include the new moves and a consistent 10-12 move menu each, with weights that reflect the style's identity:

```
boxing:     [jab, cross, hook, uppercut, overhand, superman_punch, body_knee, leg_kick, elbow, knee]
muay_thai:  [jab, cross, hook, elbow, knee, roundhouse, leg_kick, head_kick, front_kick, body_knee]
karate:     [front_kick, roundhouse, head_kick, switch_kick, question_mark_kick, axe_kick, jab, cross, leg_kick, front_kick_body]
mma:        [jab, cross, hook, leg_kick, roundhouse, front_kick, head_kick, uppercut, knee, elbow]
wrestling:  [jab, cross, hook, uppercut, leg_kick, knee, front_kick, body_knee, elbow, overhand]
bjj:        [jab, cross, hook, front_kick, leg_kick, knee, uppercut, body_knee, elbow, roundhouse]
sambo:      [jab, cross, hook, leg_kick, knee, uppercut, overhand, front_kick, elbow, body_knee]
judo:       [jab, cross, hook, uppercut, knee, elbow, body_knee, leg_kick, front_kick, overhand]
taekwondo:  [roundhouse, head_kick, switch_kick, axe_kick, question_mark_kick, front_kick, leg_kick, front_kick_body, jab, cross]
catch_wrestling: [jab, cross, hook, uppercut, knee, elbow, leg_kick, body_knee, overhand, front_kick]
hapkido:    [front_kick, roundhouse, leg_kick, jab, cross, hook, head_kick, knee, elbow, uppercut]
generic_mma: [jab, cross, hook, uppercut, front_kick, roundhouse, leg_kick, head_kick, knee, elbow]
```

---

## 3. New Features to Add

### 3.1 12 Fighting Styles (Full Set)

Add the 6 missing styles to `STYLE_AI`, `STYLE.roster`, `STYLE_AI[style]`, and the Character Forge dropdown:

```
sambo, judo, taekwondo, catch_wrestling, hapkido, generic_mma
```

Each needs:
- Style profile in `STYLE_AI` (range, aggr, weighted move menu)
- At least one fighter in the roster (create placeholder fighters for the new 6)
- Template in the Forge's `SKILL_TEMPLATES`
- Modifiers: each style gets `guardHeight`, `stanceWidth`, `idealRangeMin/Max`, `lungeDistance`

### 3.2 Move Variant System

Add a lightweight variant system to the Forge that lets players customize individual moves:

```javascript
// Each variant mutates a move's properties
const VARIANTS = {
  snap_jab:  { baseMove: 'jab', startupMult: 0.85, dmgMult: 0.90, stamMult: 0.80, unlockCost: 150, desc: 'Faster, weaker jab' },
  power_jab: { baseMove: 'jab', startupMult: 1.3, dmgMult: 1.25, stamMult: 1.3, unlockCost: 200, desc: 'Loading the hip into it' },
  // ... 10+ variants covering key moves
}
```

In the Forge, after base stats are set, show a "MOVE VARIANTS" section where the player spends variant points (earned through fights or allocated from forge pool) to customize individual strike properties.

### 3.3 Hit Reaction Animation Layer

**Current (V1):** Hit reactions are just bone pose overrides in `poseRig()` — head snap, arm drop, body lean.

**Required (V2):** Add a **spring-damper hit reaction layer** that's physically reactive and independent of the strike IK:

```javascript
// Each fighter has a hitReaction state:
hitReaction: {
  active: false,          // is a reaction playing
  tier: 0,                // 1-6
  elapsed: 0,             // seconds into reaction
  duration: 0,            // total duration
  impactDir: {x:0, y:0, z:0},  // world-space impact direction
  impactMag: 0,           // magnitude
}

// In poseRig(), this layer OVERRIDES certain bones during the first
// 30% of the reaction (hit frame), then blends back to guard over
// the remaining 70%.
const REACTION_POSES = {
  1: { headPitch: -15, headRoll: 0, chestPitch: 0, armsOut: 0, kneeBuckle: 0 },  // flinch
  2: { headPitch: -25, headRoll: 5, chestPitch: -10, armsOut: 15, kneeBuckle: 5 },
  3: { headPitch: -40, headRoll: 12, chestPitch: -20, armsOut: 30, kneeBuckle: 12 },
  4: { headPitch: -55, headRoll: 18, chestPitch: -30, armsOut: 45, kneeBuckle: 20 },
  5: { headPitch: -70, headRoll: 25, chestPitch: -40, armsOut: 60, kneeBuckle: 35 },
}
```

### 3.4 Fight Recording / Replay System

Add a circular buffer that records both fighters' state every tick:

```javascript
const replayBuffer = [];  // ring buffer, 5 seconds × 60fps = 300 entries
let replayHead = 0;
function recordTick(f1, f2){
  replayBuffer[replayHead] = structuredClone({ px:f1.px, pz:f1.pz, yaw:f1.yaw, phase:f1.phase,
    move:f1.move?.id||null, state:f1.state, hp:f1.hp, st:f1.st, ... });
  replayHead = (replayHead + 1) % 300;
}
```

On KO/KD, auto-save the last 3 seconds as a replay. Press a key to watch replays in slow-motion.

---

## 4. Refinements to Existing Systems

### 4.1 Controller Mapping — Full UFC 6 Layout

**Current (V1):** X=jab, Y=cross, A=hook, B=uppercut, RB=leg kick, RT=roundhouse, LB=modifier.

**Required (V2):** Match the standard EA SPORTS UFC 6 layout:

| Button | Action (Stand-up) | With LB Modifier |
|--------|-------------------|------------------|
| A (Xbox A) | Jab | Teep (front_kick) |
| B (Xbox B) | Cross | Overhand |
| X (Xbox X) | Hook | Front Kick (body) |
| Y (Xbox Y) | Uppercut | Head Kick |
| RB (RB) | Leg Kick | Switch Kick |
| RT (RT) | Roundhouse | Question Mark Kick |
| LT (hold) | Block | — |
| LB (tap) | Modifier for next strike | — |
| LS | Movement | — |
| RS | Head Movement (slip/duck) | — |
| RS Click | Parry | — |
| D-Pad Up | Taunt | — |
| D-Pad Down | Change Stance | — |
| START | Rematch (when match over) | — |

Update the help text overlay and the `padInput()` function.

### 4.2 Parry Mechanic

Add a parry action (RS Click) with:
- 3f startup, 2f active window
- On successful parry (active window overlaps opponent's active frames):
  - Attacker enters `interrupted` state → skips remaining active/recovery → forced into brief stun (tier 1, 0.3s)
  - Parryer opens a 10-frame counter window (`counterWin = 10`)

### 4.3 Improved Camera

**Current (V1):** Camera stays perpendicular to the fight line, smooth follow.

**Required (V2):** Add fight-state-aware camera:
- **Stand-up, neutral:** distance 3.4m + range-based scaling
- **Close range (<1m):** distance 2.0m, slightly lower angle
- **Clinch (future):** distance 1.8m, side angle
- **Knockdown:** zoom in on the falling fighter, then zoom back out
- **KO:** slow-motion drift toward the downed fighter
- **Between rounds:** orbit to show both corners

### 4.4 Round Scoring Display

**Current (V1):** No visible round scoring.

**Required (V2):** Add a round score graphic at the end of each round showing:
- Damage differential (bar comparison)
- Knockdowns (number icons)
- Winner indicator (highlight name)

---

## 5. Implementation Constraints

1. **Single HTML file** — No build step, no npm, no TypeScript. Three.js r128 from CDN.
2. **No external CSS** — All styles inline in `<style>` tag.
3. **Deterministic sim** — Seeded RNG (`rnd()`), fixed-step 60Hz.
4. **UI via DOM** — Not canvas UI. All HUD, select screens, forge via HTML elements overlaid on the WebGL canvas.
5. **Audio via WebAudio** — `OscillatorNode` + `GainNode` only (no audio files).
6. **Gamepad via Navigator.getGamepads()** — Polling, not events.
7. **Total file < 200KB** — Keep it lean.

---

## 6. Non-Goals (For This Prototype)

These belong in the Godot 4 version, not the Three.js prototype:

- Clinch / Ground / Submission state machines
- Full 6-fight-state FSM (STAND_UP, CLINCH, GROUND_TOP, GROUND_BOTTOM, SUBMISSION, KO)
- Career mode, progression, XP, prestige
- Online multiplayer / netcode
- .tres resource serialization
- Proper asset pipeline
- UI art pass beyond arcade-hacker aesthetic

---

## 7. Quickstart / Testing

```javascript
// After loading the HTML in a browser:
// 1. Click a fighter card to select P1
// 2. Click another to start the fight
// 3. Keyboard: A/D = move in/out, arrows = circle, Space = block
//    Q/E = slip, S = duck, J=Jab, K=Cross, U=Hook, I=Uppercut
//    O=Overhand, V=Teep, N=Leg Kick, M=Roundhouse, Comma=Head Kick
// 4. Gamepad: LS=move, RS=head movement, LT=block, X/A/Y/B=strikes
//    LB+face=power variant, RB=leg kick, RT=roundhouse
// 5. Press R to rematch, T to toggle CPU control, H to toggle help
// 6. ESC to return to fighter select
// 7. Click "+ CREATE FIGHTER" to open the Character Forge
```
