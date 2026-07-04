# Gladiator Ultra — Three.js Edition

## Concept Overview

**Gladiator Ultra** is a physics-driven MMA simulation rendered in low-poly Virtua-Fighter style, built for the browser with Three.js. Every strike is a calculated velocity × angle × range event. Animations are procedural — the physics drives the visuals, not the other way around.

### Design Pillars
1. **Physics-first combat** — Damage, stun, knockback all computed from velocity vectors, not animation data
2. **Modular architecture** — Every system (combat, progression, AI, camera) is an independent module
3. **Low-poly aesthetic** — 300-600 vertex characters, vertex-colored, unlit flat shading — VF1 era
4. **Data-driven fighters** — All fighter attributes, move properties, and styles are static data tables
5. **Browser-native** — Three.js + TypeScript, no build toolchain heavier than Vite

---

## Architecture

```
src/
├── main.ts                          # Entry point, game loop, scene setup
├── core/
│   ├── GameLoop.ts                  # requestAnimationFrame loop with fixed-step physics
│   ├── InputManager.ts              # Keyboard + Gamepad → action dispatch
│   ├── StateMachine.ts              # Generic FSM base class
│   └── EventBus.ts                  # Decoupled event system
│
├── combat/
│   ├── ImpactCalculator.ts          # Velocity→damage→stun resolution (pure math)
│   ├── HitDetection.ts              # Capsule-vs-capsule, swept-tunnel, zone mapping
│   ├── StrikePlanner.ts             # Strike plan generation from move data
│   ├── KnockbackSolver.ts           # Launch velocity, decay, Directional Influence
│   └── BlockSystem.ts               # Damage mitigation, stamina drain, guard break
│
├── fighter/
│   ├── FighterData.ts               # Stat block, health pools, stamina state
│   ├── FighterStateMachine.ts       # STAND_UP / CLINCH / GROUND / SUBMISSION states
│   ├── FighterFactory.ts            # Creates FighterData from static definitions
│   ├── FighterModel.ts              # Three.js skinned mesh construction
│   └── FighterAnimator.ts           # Procedural animation (IK + bone posing)
│
├── animation/
│   ├── LimbSolver.ts                # FABRIK IK — 2-bone chain, dual-arm, look-at
│   ├── StrikeTrajectories.ts        # 10 parametric strike paths (jab→elbow)
│   ├── RecoveryPlanner.ts           # Stamina/limb/combo-sensitive recovery frames
│   └── HitReaction.ts               # Stun-tier-based bone snapping and ragdoll blend
│
├── match/
│   ├── MatchManager.ts              # Round timer, scoring, fight outcome resolution
│   ├── JudgeScorer.ts               # 10-9 system, damage/KD/control tracking
│   └── RoundTimer.ts                # Countdown with between-round pauses
│
├── camera/
│   └── FightCamera.ts               # Third-person orbital, midpoint tracking, shake
│
├── ai/
│   ├── AIController.ts              # Tactical decision-making per tick
│   └── StyleProfiles.ts             # Behavior weights per fighting style
│
├── progression/
│   ├── MoveVariantData.ts           # Variant definitions (80+)
│   ├── ChallengeData.ts             # Per-move challenges
│   └── ProgressionTracker.ts        # XP → level → prestige → variant purchase
│
├── rendering/
│   ├── ArenaScene.ts                # Octagon, cage, lighting, ground
│   ├── FighterMeshBuilder.ts        # VF1-style low-poly mesh generation
│   ├── TeamColors.ts                # Red/blue tint application
│   ├── DamageVFX.ts                 # Hit sparks, blood, swelling indicators
│   └── HUD.ts                       # Health bars, stamina, round info, timer
│
├── data/                            # Static data tables (one file per domain)
│   ├── fighters.ts                  # 6 fighter definitions
│   ├── moves.ts                     # 60+ move definitions with frame data
│   ├── styles.ts                    # 12 style definitions with modifiers
│   ├── combos.ts                    # Combo trees and chain rules
│   ├── variants.ts                  # 80+ move variant definitions
│   └── challenges.ts                # 25+ challenge definitions
│
└── types/                           # TypeScript type definitions
    ├── combat.ts                    # HitResult, StrikeConfig, DamageProfile
    ├── fighter.ts                   # FighterData, HealthPool, StaminaState
    ├── match.ts                     # MatchState, RoundScore, FightResult
    └── animation.ts                 # IKResult, StrikePlan, RecoveryPlan
```

---

## Game Loop (Fixed-Step Physics)

```typescript
// main.ts — simplified
const FIXED_DT = 1 / 60;
let accumulator = 0;

function gameLoop(timestamp: number) {
  const dt = Math.min((timestamp - lastTime) / 1000, 0.05);
  lastTime = timestamp;
  accumulator += dt;

  while (accumulator >= FIXED_DT) {
    fixedUpdate(FIXED_DT);
    accumulator -= FIXED_DT;
  }

  render(accumulator / FIXED_DT); // interpolation alpha
  requestAnimationFrame(gameLoop);
}

function fixedUpdate(dt: number) {
  inputManager.poll();             // Read keyboard/gamepad → action queue
  aiController.tick(dt, range);   // AI picks actions
  fighter1.fsm.update(dt);        // Process queued actions
  fighter2.fsm.update(dt);
  matchManager.update(dt);        // Round timer, KO check
  fightCamera.update(dt);         // Camera follow
}
```

### Key Design Decision: Fixed-Step vs Variable

**Fixed-step at 60Hz** for ALL combat physics. The visual render interpolates at display refresh rate. This ensures:
- Deterministic combat resolution (no delta-time variance on damage)
- Same results on 60Hz and 144Hz displays
- Easier replay / netcode later

---

## 3D Scene & Rendering

### Scene Setup
```typescript
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1a1a2e);  // Dark arena

// Camera (initial — FightCamera overrides this each frame)
const camera = new THREE.PerspectiveCamera(45, w/h, 0.1, 50);
camera.position.set(0, 2.5, 4);

// Renderer
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(w, h);
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
```

### Low-Poly Fighter (VF1-style)

Each fighter is a skinned mesh with ~300-600 vertices, no textures — vertex colors only:

```typescript
interface FighterMeshConfig {
  vertexCount: number;      // 300-600
  colorPalette: number[];   // [skin, shorts, gloves, shoes]
  flatShading: boolean;     // true
  boneCount: number;        // 16 bones (same hierarchy as Godot version)
}

// Bone hierarchy (identical to Godot Skeleton3D layout):
// Hips → Spine → Chest → Head
//                    → L/R UpperArm → L/R Forearm → L/R Hand
//        → L/R UpperLeg → L/R LowerLeg → L/R Foot
```

**Material:**
```typescript
const material = new THREE.MeshBasicMaterial({
  vertexColors: true,
  flatShading: true,
});
// No lighting — color comes entirely from vertex colors + flat shading
// This IS the Virtua Fighter 1 look
```

**Team Colors:**
- Red corner: torso/shorts tinted `#CC2222`, skin `#E8C8A0`
- Blue corner: torso/shorts tinted `#2244CC`, skin `#E8C8A0`

### Arena / Octagon

```typescript
// Cage: 9m diameter octagon
// Floor: dark grey with sponsor decals (vertex-colored polygons)
// Cage wall: semi-transparent cylinder or 8 fence panels
// Post lights: 4 corner posts with point lights

const cageRadius = 4.5;
const cageSegments = 8;
// Wall height: 1.8m
// Fence: grid of thin cylinders
```

---

## Combat System (Core Math)

### Damage Formula (Mirrors Godot ImpactCalculator)

```typescript
function resolveStrike(
  attacker: FighterData,
  defender: FighterData,
  strikeType: StrikeType,
  targetZone: BodyZone,
  velocity: THREE.Vector3,
  isCounter: boolean,
  rangeAtImpact: number,
  perfectTiming: boolean
): HitResult {
  // 1. Base damage from move config
  let rawDamage = getMoveConfig(strikeType).baseDamage;

  // 2. Strength modifier
  rawDamage *= (1 + attacker.strength * 0.01);

  // 3. Skill accuracy modifier
  const skill = attacker.getSkill(skillForStrike(strikeType));
  rawDamage *= (0.5 + skill / 200);

  // 4. Range falloff
  const optimalRange = getMoveConfig(strikeType).range;
  const rangeError = Math.abs(rangeAtImpact - optimalRange);
  rawDamage *= Math.max(0.2, 1 - rangeError * 0.15);

  // 5. Velocity bonus
  const speed = velocity.length();
  rawDamage *= Math.min(2, Math.max(0.8, 1 + speed * 0.05));

  // 6. Perfect timing ×1.25
  if (perfectTiming) rawDamage *= 1.25;

  // 7. Counter ×1.35
  if (isCounter) rawDamage *= 1.35;

  // 8. Defender mitigation (toughness)
  let mitigated = rawDamage * defender.getDerived('dmgTakenMult');

  // 9. Gassed penalty: +20% damage taken
  if (defender.isGassed()) mitigated *= 1.2;

  // → Result object with damage, stun level, cut, swell
}
```

### Stun Rules (Simplified)

| Condition | Result |
|-----------|--------|
| Any clean hit (mitigated > 0) | **Tier 1 daze minimum** (0.15-0.35s) |
| Counter hit | **Tier 3 stun minimum** (0.8-1.5s) |
| mitigated > chin × 1.0 | Tier 3 stun |
| mitigated > chin × 2.0 | Tier 5 knockdown |
| mitigated > chin × 3.0 | Tier 6 KO |
| Body/leg hits | Daze only (max Tier 1) |

### Block Interaction

| Defense | Mitigation | Stun |
|---------|-----------|------|
| High block | -70% damage | Tier 1 daze only (0.1s) |
| Low block | -50% damage | Tier 1 daze |
| Block broken (stamina = 0) | -30% damage | Full stun + guard break |
| Parry | 0 damage | No stun — attacker recovery penalty |
| Slip/Duck | 0 damage | Counter window opens |

---

## Fighter Data Schema

```typescript
interface FighterData {
  // Identity
  id: string;
  name: string;
  nickname: string;
  weightClass: WeightClass;
  nationality: string;
  age: number;
  reachInches: number;
  height: { ft: number; inches: number };
  stance: Stance; // ORTHODOX | SOUTHPAW | SWITCH

  // 4 Core Stats (0-100)
  strength: number;    // Damage output
  speed: number;       // Strike speed, reaction time
  endurance: number;   // Max stamina, recovery rate
  toughness: number;   // Damage mitigation, chin

  // 18 Combat Skills (0-100)
  boxing: number;
  kickboxing: number;
  muayThai: number;
  headMovement: number;
  footwork: number;
  clinchOffense: number;
  clinchDefense: number;
  clinchTakedown: number;
  tdOffense: number;
  tdDefense: number;
  counterTd: number;
  cageWrestling: number;
  topControl: number;
  bottomControl: number;
  guardPass: number;
  guardRetention: number;
  subOffense: number;
  subDefense: number;

  // Health Profile (0-100)
  chin: number;
  cutResistance: number;
  swellResistance: number;
  bleedResistance: number;
  limbHealth: number;

  // Stamina Profile (0-100)
  maxStaminaRating: number;
  drainRateRating: number;
  recoveryRateRating: number;
  gassedThresholdRating: number;
  cardioDropRating: number;

  // Style
  primaryStyle: StyleId; // 'boxing' | 'wrestling' | 'bjj' | 'muay_thai' | 'karate' | 'generic_mma'

  // Record
  wins: number;
  losses: number;
  kos: number;
  subs: number;
  decisions: number;
}
```

### Derived Stats (computed once)

```typescript
interface DerivedStats {
  maxStamina: number;
  punchBaseDmg: number;
  kickBaseDmg: number;
  strikeSpeedMult: number;
  staminaDrainMult: number;
  koThreshold: number;
  dmgTakenMult: number;
  moveSpeedMult: number;
  accuracyBonus: number;
  reactionFrames: number;
  gnpDamageMult: number;
  clinchPush: number;
  takedownPower: number;
}
```

---

## State Machine (Fight States)

```
┌─────────────┐     clinch_entry     ┌──────────┐
│  STAND_UP   │ ──────────────────→ │  CLINCH  │
│             │ ←────────────────── │          │
│  punches,   │   clinch_break      │ knees,   │
│  kicks,     │                     │ elbows,  │
│  head_move, │                     │ pummel,  │
│  takedown   │                     │ cage_push│
└──────┬──────┘                     └────┬─────┘
       │                                 │
       │ takedown_shot        clinch_td  │
       ▼                                 ▼
┌──────────────┐               ┌──────────────┐
│ GROUND_TOP   │               │ GROUND_BOTTOM│
│              │               │              │
│ GNP, pass,   │ ←── sweep ──→ │ sweeps,      │
│ posture, sub │               │ frames,      │
│              │               │ getup, sub   │
└──────┬───────┘               └──────┬───────┘
       │                              │
       │ sub_attempt_top   sub_bottom │
       ▼                              ▼
┌──────────────┐            ┌──────────────┐
│ SUBMISSION   │            │ SUBMISSION   │
│ (attacker)   │            │ (defender)   │
│ tap_out = WIN│            │ tap_out = LOSS
└──────────────┘            └──────────────┘

KO State — Terminal
  STAND_UP ──→ KO (on chin check failure)
  Any state ──→ KO (if accumulated damage triggers it)
```

### State Availability Matrix

| Action | STAND_UP | CLINCH | GROUND_TOP | GROUND_BOTTOM | SUB |
|--------|----------|--------|------------|---------------|-----|
| Punches | ✓ | ✓ (dirty) | ✓ (GNP) | ✗ | ✗ |
| Kicks | ✓ | ✗ | ✗ | ✗ | ✗ |
| Knees | ✓ (close) | ✓ | ✗ | ✗ | ✗ |
| Elbows | ✓ (close) | ✓ | ✓ (GNP) | ✗ | ✗ |
| Block | ✓ | ✗ | ✗ | ✗ | ✗ |
| Head Movement | ✓ | ✗ | ✗ | ✗ | ✗ |
| Clinch Entry | ✓ | — | — | — | — |
| Clinch Break | — | ✓ | — | — | — |
| Takedown | ✓ | — | — | — | — |
| Sprawl | ✓ | — | — | — | — |
| GNP | — | — | ✓ | ✗ | ✗ |
| Ground Transition | — | — | ✓ | ✓ | ✗ |
| Sweep | — | — | ✗ | ✓ | ✗ |
| Submission | — | — | ✓ | ✓ | ✓ |
| Getup | — | — | ✓ | ✓ | ✗ |

---

## Match Flow

```
1. START MATCH
   ├── Select two fighters
   ├── Set round count (3 or 5)
   └── Weigh-in (confirm weight class match or catchweight)

2. PRE-FIGHT (2s)
   ├── Referee instructions (animation skip)
   └── Fighters touch gloves

3. ROUND ACTIVE (5 min → 3 min for women/early prelims)
   ├── Timer counting down
   ├── Both FighterStateMachines active
   ├── AI or player input driving actions
   ├── Round ends when timer = 0
   └── OR fight ends early (KO/TKO/SUB)

4. BETWEEN ROUNDS (60s)
   ├── Fighters return to corners
   ├── Stamina recovery partial
   ├── Cutman reduces swelling/bleeding
   ├── Coach advice (attribute bonus selection)
   └── Timer counts down to next round

5. POST-FIGHT
   ├── Decision: score cards announced
   ├── KO/TKO: replay of finish
   ├── SUB: replay of submission
   └── Winner celebration
```

### Scoring (10-9 System)

```typescript
interface RoundScore {
  round: number;
  f1: { damageDone: number; knockdowns: number; controlTime: number; stunsInflicted: number };
  f2: { /* same */ };
  score: { f1Score: number; f2Score: number; winner: -1 | 0 | 1 };
}

// Default: 10-10 each
// -1 point per knockdown suffered
// -1 point if opponent did 50%+ more damage
// -1 point for significant control time disparity
// Minimum score: 7 (a 10-7 round is rare but possible)
```

---

## Camera System

```typescript
class FightCamera {
  // Configuration
  baseDistance = 3.5;
  clinchDistance = 2.0;
  groundDistance = 2.8;
  heightOffset = 1.5;
  groundHeightOffset = 2.5;
  orbitSpeed = 3.0;     // rad/s (right stick)
  followLerp = 5.0;
  shakeDecay = 6.0;

  // Per-frame update
  update(dt: number, f1Pos: Vector3, f2Pos: Vector3, fightState: FightState) {
    // 1. Midpoint
    const mid = f1Pos.clone().add(f2Pos).multiplyScalar(0.5);

    // 2. Distance by state
    const targetDist = this.getDistanceForState(fightState);

    // 3. Orbital position
    const dir = new THREE.Vector3(
      Math.sin(this.orbitAngle),
      Math.sin(this.orbitPitch),
      Math.cos(this.orbitAngle)
    ).normalize();
    const desired = mid.clone().add(dir.multiplyScalar(targetDist));

    // 4. Smooth follow
    this.camera.position.lerp(desired, this.followLerp * dt);

    // 5. Look at midpoint
    this.camera.lookAt(mid);

    // 6. Shake
    this.shakeIntensity = Math.max(0, this.shakeIntensity - this.shakeDecay * dt);
    const mag = this.shakeIntensity * 0.15;
    this.camera.position.x += (Math.random() - 0.5) * mag;
    this.camera.position.y += (Math.random() - 0.5) * mag;
  }
}
```

---

## Input System

```typescript
// Keyboard map (UFC5-style)
// WASD = movement / LS
// A = jab (tap) / cross (hold)
// B = hook (tap) / uppercut (hold)
// X = front kick
// Y = roundhouse
// Hold Shift = modifier (high/low target)
// Space = block (hold)
// Q = lunge
// E = clinch entry
// R = takedown
// F = grapple transition
// C = cage push
// Arrow keys = head movement / RS

// Gamepad map (Xbox)
// LS = movement
// RS = head movement / orbit camera
// A = jab, X = front kick, Y = roundhouse, B = hook
// LB = high modifier, RB = low modifier
// LT = perfect timing / power modifier
// RT = block (hold)
// D-pad Up = clinch entry
// D-pad Down = takedown
// D-pad Left = cage push
// D-pad Right = grapple transition
```

---

## AI Controller

```typescript
class AIController {
  tick(dt: number, range: number): AIAction {
    if (this.fsm.isStunned || this.fsm.isKnockedOut) {
      return { action: 'idle' };
    }

    // 1. Defense (react to opponent attack)
    if (this.detectOpponentAttack()) {
      return { action: this.chooseDefense(range) };
    }

    // 2. Retreat when hurt
    if (this.shouldRetreat()) {
      return { action: 'retreat' };
    }

    // 3. Clinch/Takedown at close range (grapplers)
    if (range < 0.8 && this.grappleWeight > 1.0 && Math.random() < 0.3) {
      return { action: Math.random() < 0.5 ? 'clinch' : 'takedown' };
    }

    // 4. Range management
    if (range > this.rangePreference * 1.5) return { action: 'lunge' };
    if (range < this.rangePreference * 0.5) return { action: 'retreat' };

    // 5. Strike selection
    return {
      action: 'strike',
      strikeId: this.chooseStrike(range),
      target: this.chooseTarget(),
    };
  }
}
```

### Style Profiles

| Style | Strike Weight | Grapple Weight | Preferred Range |
|-------|:------------:|:--------------:|:---------------:|
| Boxing | 1.3 | 0.4 | 1.2m |
| Muay Thai | 1.2 | 0.7 | 1.5m |
| Kickboxing | 1.3 | 0.3 | 1.8m |
| Karate | 1.2 | 0.3 | 2.0m |
| Wrestling | 0.5 | 1.5 | 0.8m |
| BJJ | 0.3 | 1.6 | 0.6m |
| Generic MMA | 1.0 | 1.0 | 1.3m |

---

## Progression System

### Strike XP → Level Table

| XP Required | Level | Title |
|:-----------:|:-----:|-------|
| 0 | 1 | Novice |
| 100 | 2 | Competent |
| 300 | 3 | Proficient |
| 600 | 4 | Master |
| 1000 | 5 | Grandmaster |

- At Level 5+ → Prestige available (XP resets, permanent stacking bonus)
- Prestige cycles: damage +1.5%, stamina -0.75%, hit_chance +1.0% per level
- XP is per-strike-type (jab, cross, hook, etc.)

### Variant Purchase Cost

```typescript
cost = Math.floor(strike_xp * 0.3);
// Deducted from the XP pool for that specific strike type
// Does NOT reduce level (level is based on total XP ever earned)
```

---

## Sound & Audio

```typescript
// Using Web Audio API (no external library needed)
// Sound effects are synthesized or short audio sprites:
interface AudioAssets {
  punch_light: AudioBuffer;   // Thud (100ms)
  punch_heavy: AudioBuffer;   // Crack (150ms)
  kick: AudioBuffer;          // Whump (200ms)
  block: AudioBuffer;         // Thump (80ms)
  crowd_ohh: AudioBuffer;    // Reaction (500ms)
  crowd_roar: AudioBuffer;   // Big moment (1.5s)
  bell_round: AudioBuffer;   // Start/end (1s)
  bell_ko: AudioBuffer;      // Fight over (2s)
  hit_stun: AudioBuffer;     // Daze whoosh (300ms)
}
```

---

## Implementation Order (Recommended)

| Phase | What | Why First |
|-------|------|-----------|
| **0** | Project setup (Vite + Three.js + TypeScript) | Foundation |
| **1** | Scene, camera, arena floor | Visual context |
| **2** | FighterData + FighterFactory + data files | Data layer |
| **3** | HitDetection (capsule math) + ImpactCalculator | Core combat math (testable in isolation) |
| **4** | FighterStateMachine + state transitions | Game logic backbone |
| **5** | InputManager → FSM integration | Playable input |
| **6** | Minimal fighter mesh (colored boxes/cylinders) | Visual feedback |
| **7** | MatchManager + RoundTimer + scoring | Match structure |
| **8** | FightCamera | Better view |
| **9** | StrikePlanner + LimbSolver (IK) | Procedural animation |
| **10** | HitReaction + Knockback | Combat feel |
| **11** | BlockSystem | Defense layer |
| **12** | AIController | Solo playable |
| **13** | HUD overlay (health bars, timer, stamina) | Player feedback |
| **14** | DamageVFX (sparks, blood) | Polish |
| **15** | Low-poly fighter meshes | Visual upgrade |
| **16** | Progression system | Long-term engagement |
| **17** | Sound effects | Audio layer |
| **18** | Menu + character select | Full game loop |
