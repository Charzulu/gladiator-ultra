# Gladiator Ultra — Complete Data Tables

> All data is designed for direct translation to TypeScript `const` arrays.
> Frame baseline: 60fps (1 frame = 16.67ms)
> Stat baseline: SPD=50, STR=50, all skills=50 (no modifiers)

---

## 1. Fighter Definitions

```typescript
// ── data/fighters.ts ──

export interface FighterDef {
  id: string;
  name: string;
  nickname: string;
  weightClass: number; // 0=Straw,1=Fly,2=Bantam,3=Feather,4=Light,
                        // 5=Welter,6=Middle,7=LHW,8=HW
  nationality: string;
  age: number;
  reachInches: number;
  heightFT: number;
  heightIN: number;
  stance: number; // 0=Orthodox,1=Southpaw,2=Switch
  // Core stats
  STR: number; SPD: number; END: number; TGH: number;
  // Combat skills
  boxing: number; kickboxing: number; muayThai: number;
  headMovement: number; footwork: number;
  clinchOffense: number; clinchDefense: number; clinchTakedown: number;
  tdOffense: number; tdDefense: number; counterTD: number;
  cageWrestling: number;
  topControl: number; bottomControl: number;
  guardPass: number; guardRetention: number;
  subOffense: number; subDefense: number;
  // Health
  chin: number; cutResistance: number; swellResistance: number;
  bleedResistance: number; limbHealth: number;
  // Stamina
  maxStaminaRating: number; drainRateRating: number;
  recoveryRateRating: number; gassedThresholdRating: number;
  cardioDropRating: number;
  // Record
  wins: number; losses: number; kos: number; subs: number;
  // Style
  primaryStyle: StyleId;
}

export const FIGHTERS: FighterDef[] = [
  // ─────────────────────────────────────────────
  // 1. IVAN DRAKOV — Heavyweight Power Puncher
  // Style: Boxing. Elite KO power, weak cardio, terrible ground game.
  // ─────────────────────────────────────────────
  {
    id: 'ivan_drakov',
    name: 'Ivan Drakov', nickname: 'The Hammer',
    weightClass: 8, nationality: 'Russia', age: 28,
    reachInches: 78, heightFT: 6, heightIN: 4, stance: 0,
    STR: 92, SPD: 38, END: 55, TGH: 85,
    boxing: 82, kickboxing: 35, muayThai: 25,
    headMovement: 38, footwork: 35,
    clinchOffense: 45, clinchDefense: 50, clinchTakedown: 15,
    tdOffense: 25, tdDefense: 60, counterTD: 20, cageWrestling: 30,
    topControl: 35, bottomControl: 15,
    guardPass: 20, guardRetention: 25,
    subOffense: 10, subDefense: 20,
    chin: 88, cutResistance: 65, swellResistance: 70,
    bleedResistance: 60, limbHealth: 75,
    maxStaminaRating: 45, drainRateRating: 40,
    recoveryRateRating: 40, gassedThresholdRating: 35, cardioDropRating: 30,
    wins: 18, losses: 2, kos: 16, subs: 0,
    primaryStyle: 'boxing',
  },

  // ─────────────────────────────────────────────
  // 2. KENJI TAKESHI — Lightweight Grappler
  // Style: Wrestling. Elite TDs, suffocating top game, suspect chin.
  // ─────────────────────────────────────────────
  {
    id: 'kenji_takeshi',
    name: 'Kenji Takeshi', nickname: 'The Octopus',
    weightClass: 4, nationality: 'Japan', age: 26,
    reachInches: 70, heightFT: 5, heightIN: 9, stance: 0,
    STR: 60, SPD: 72, END: 82, TGH: 65,
    boxing: 45, kickboxing: 30, muayThai: 45,
    headMovement: 50, footwork: 55,
    clinchOffense: 78, clinchDefense: 72, clinchTakedown: 85,
    tdOffense: 88, tdDefense: 68, counterTD: 55, cageWrestling: 65,
    topControl: 82, bottomControl: 72,
    guardPass: 68, guardRetention: 78,
    subOffense: 72, subDefense: 80,
    chin: 60, cutResistance: 50, swellResistance: 45,
    bleedResistance: 55, limbHealth: 65,
    maxStaminaRating: 85, drainRateRating: 90,
    recoveryRateRating: 88, gassedThresholdRating: 85, cardioDropRating: 90,
    wins: 14, losses: 3, kos: 0, subs: 9,
    primaryStyle: 'wrestling',
  },

  // ─────────────────────────────────────────────
  // 3. DAMIEN CRUZ — Welterweight Striker
  // Style: Karate. Elite kicks, footwork, terrible grappling.
  // ─────────────────────────────────────────────
  {
    id: 'damien_cruz',
    name: 'Damien Cruz', nickname: 'The Phantom',
    weightClass: 5, nationality: 'Brazil', age: 30,
    reachInches: 74, heightFT: 6, heightIN: 0, stance: 1,
    STR: 68, SPD: 88, END: 72, TGH: 58,
    boxing: 62, kickboxing: 92, muayThai: 75,
    headMovement: 68, footwork: 92,
    clinchOffense: 50, clinchDefense: 58, clinchTakedown: 35,
    tdOffense: 30, tdDefense: 62, counterTD: 72, cageWrestling: 35,
    topControl: 25, bottomControl: 30,
    guardPass: 22, guardRetention: 28,
    subOffense: 18, subDefense: 28,
    chin: 52, cutResistance: 55, swellResistance: 42,
    bleedResistance: 50, limbHealth: 48,
    maxStaminaRating: 75, drainRateRating: 80,
    recoveryRateRating: 78, gassedThresholdRating: 72, cardioDropRating: 75,
    wins: 22, losses: 4, kos: 11, subs: 0,
    primaryStyle: 'karate',
  },

  // ─────────────────────────────────────────────
  // 4. MARCUS STEELE — Middleweight Balanced
  // Style: Generic MMA. No elite skill, no critical weakness.
  // ─────────────────────────────────────────────
  {
    id: 'marcus_steele',
    name: 'Marcus Steele', nickname: 'The All-Around',
    weightClass: 6, nationality: 'USA', age: 29,
    reachInches: 73, heightFT: 5, heightIN: 11, stance: 0,
    STR: 65, SPD: 68, END: 72, TGH: 62,
    boxing: 65, kickboxing: 60, muayThai: 55,
    headMovement: 58, footwork: 62,
    clinchOffense: 58, clinchDefense: 60, clinchTakedown: 55,
    tdOffense: 60, tdDefense: 65, counterTD: 55, cageWrestling: 58,
    topControl: 60, bottomControl: 55,
    guardPass: 52, guardRetention: 58,
    subOffense: 50, subDefense: 55,
    chin: 60, cutResistance: 55, swellResistance: 55,
    bleedResistance: 58, limbHealth: 60,
    maxStaminaRating: 70, drainRateRating: 65,
    recoveryRateRating: 68, gassedThresholdRating: 65, cardioDropRating: 68,
    wins: 12, losses: 1, kos: 4, subs: 3,
    primaryStyle: 'generic_mma',
  },

  // ─────────────────────────────────────────────
  // 5. HIRO TANAKA — Featherweight BJJ Specialist
  // Style: BJJ. Elite submissions, terrible stand-up.
  // ─────────────────────────────────────────────
  {
    id: 'hiro_tanaka',
    name: 'Hiro Tanaka', nickname: 'The Cobra',
    weightClass: 3, nationality: 'Japan', age: 27,
    reachInches: 69, heightFT: 5, heightIN: 7, stance: 0,
    STR: 48, SPD: 75, END: 78, TGH: 55,
    boxing: 38, kickboxing: 35, muayThai: 40,
    headMovement: 55, footwork: 60,
    clinchOffense: 65, clinchDefense: 70, clinchTakedown: 72,
    tdOffense: 68, tdDefense: 55, counterTD: 65, cageWrestling: 48,
    topControl: 75, bottomControl: 92,
    guardPass: 70, guardRetention: 88,
    subOffense: 95, subDefense: 85,
    chin: 45, cutResistance: 50, swellResistance: 48,
    bleedResistance: 52, limbHealth: 50,
    maxStaminaRating: 80, drainRateRating: 82,
    recoveryRateRating: 85, gassedThresholdRating: 80, cardioDropRating: 85,
    wins: 16, losses: 5, kos: 0, subs: 14,
    primaryStyle: 'bjj',
  },

  // ─────────────────────────────────────────────
  // 6. LUCIANA SANTOS — Strawweight Muay Thai
  // Style: Muay Thai. Volume striking, elite clinch, suspect TDD.
  // ─────────────────────────────────────────────
  {
    id: 'luciana_santos',
    name: 'Luciana Santos', nickname: 'The Hurricane',
    weightClass: 0, nationality: 'Brazil', age: 25,
    reachInches: 65, heightFT: 5, heightIN: 4, stance: 1,
    STR: 55, SPD: 88, END: 85, TGH: 48,
    boxing: 55, kickboxing: 78, muayThai: 88,
    headMovement: 62, footwork: 72,
    clinchOffense: 85, clinchDefense: 72, clinchTakedown: 60,
    tdOffense: 35, tdDefense: 45, counterTD: 50, cageWrestling: 30,
    topControl: 35, bottomControl: 42,
    guardPass: 28, guardRetention: 45,
    subOffense: 25, subDefense: 40,
    chin: 42, cutResistance: 55, swellResistance: 40,
    bleedResistance: 50, limbHealth: 45,
    maxStaminaRating: 90, drainRateRating: 88,
    recoveryRateRating: 92, gassedThresholdRating: 88, cardioDropRating: 92,
    wins: 10, losses: 1, kos: 3, subs: 0,
    primaryStyle: 'muay_thai',
  },
];
```

---

## 2. Move Data (Stand-up Strikes)

```typescript
// ── data/moves.ts ──

export interface MoveDef {
  id: string;                    // Unique ID (S01-S14, etc.)
  name: string;                  // Display name
  input: string;                 // Input description
  type: 'punch' | 'kick' | 'knee' | 'elbow' | 'takedown' | 'defense' | 'movement' | 'clinch' | 'gnp' | 'submission';
  startup: number;               // Base startup frames
  active: number;                // Base active frames
  recovery: number;              // Base recovery frames
  reach: number;                 // Reach in meters
  baseDamage: number;            // Base raw damage
  staminaCost: number;           // Base stamina cost
  stunLevel: StunTier;           // Default stun tier on clean hit (1=daze…6=KO)
  targetZones: BodyZone[];       // Valid target zones
  primarySkill: SkillId;         // Governing combat skill
  trajectory: TrajectoryId;      // Reference to parametric curve
  availableStates: FightState[]; // Which states this move works in
  cutChance: number;             // 0.0-1.0
  bluntRatio: number;            // 1.0=pure blunt, 0.0=pure sharp
}

export const MOVES: MoveDef[] = [
  // ── PUNCHES ──
  { id:'jab', name:'Jab', input:'A(tap)', type:'punch',
    startup:3, active:3, recovery:5, reach:1.2, baseDamage:5,
    staminaCost:2, stunLevel:1, targetZones:['head','body'],
    primarySkill:'boxing', trajectory:'JAB_TRAJ',
    availableStates:['STAND_UP','CLINCH'], cutChance:0.05, bluntRatio:1.0 },

  { id:'cross', name:'Cross', input:'A(hold)', type:'punch',
    startup:5, active:4, recovery:7, reach:1.3, baseDamage:9,
    staminaCost:3.5, stunLevel:1, targetZones:['head','body'],
    primarySkill:'boxing', trajectory:'CROSS_TRAJ',
    availableStates:['STAND_UP','CLINCH'], cutChance:0.08, bluntRatio:1.0 },

  { id:'hook', name:'Hook', input:'B(tap)', type:'punch',
    startup:7, active:4, recovery:9, reach:1.0, baseDamage:12,
    staminaCost:4, stunLevel:2, targetZones:['head','body'],
    primarySkill:'boxing', trajectory:'HOOK_TRAJ',
    availableStates:['STAND_UP'], cutChance:0.10, bluntRatio:1.0 },

  { id:'uppercut', name:'Uppercut', input:'B(hold)', type:'punch',
    startup:6, active:4, recovery:8, reach:0.8, baseDamage:11,
    staminaCost:4, stunLevel:1, targetZones:['head','body'],
    primarySkill:'boxing', trajectory:'UPPERCUT_TRAJ',
    availableStates:['STAND_UP'], cutChance:0.08, bluntRatio:1.0 },

  { id:'overhand', name:'Overhand', input:'LS→+B', type:'punch',
    startup:9, active:5, recovery:12, reach:1.1, baseDamage:14,
    staminaCost:5, stunLevel:3, targetZones:['head'],
    primarySkill:'boxing', trajectory:'OVERHAND_TRAJ',
    availableStates:['STAND_UP'], cutChance:0.12, bluntRatio:1.0 },

  { id:'superman_punch', name:'Superman Punch', input:'LS→+A+LT', type:'punch',
    startup:12, active:4, recovery:14, reach:1.6, baseDamage:13,
    staminaCost:6, stunLevel:2, targetZones:['head'],
    primarySkill:'boxing', trajectory:'SUPERMAN_TRAJ',
    availableStates:['STAND_UP'], cutChance:0.08, bluntRatio:1.0 },

  // ── KICKS ──
  { id:'front_kick', name:'Front Kick (Teep)', input:'X(tap)', type:'kick',
    startup:7, active:4, recovery:8, reach:1.6, baseDamage:8,
    staminaCost:3, stunLevel:1, targetZones:['body'],
    primarySkill:'kickboxing', trajectory:'FRONT_KICK_TRAJ',
    availableStates:['STAND_UP'], cutChance:0.0, bluntRatio:1.0 },

  { id:'roundhouse', name:'Roundhouse', input:'Y(tap)', type:'kick',
    startup:10, active:5, recovery:14, reach:1.8, baseDamage:14,
    staminaCost:5.5, stunLevel:2, targetZones:['body','head'],
    primarySkill:'kickboxing', trajectory:'ROUNDHOUSE_TRAJ',
    availableStates:['STAND_UP'], cutChance:0.02, bluntRatio:1.0 },

  { id:'leg_kick', name:'Leg Kick', input:'RB+X', type:'kick',
    startup:7, active:4, recovery:8, reach:1.5, baseDamage:7,
    staminaCost:3.5, stunLevel:0, targetZones:['left_leg','right_leg'],
    primarySkill:'kickboxing', trajectory:'LEG_KICK_TRAJ',
    availableStates:['STAND_UP'], cutChance:0.01, bluntRatio:0.8 },

  { id:'head_kick', name:'Head Kick', input:'LB+Y', type:'kick',
    startup:13, active:5, recovery:18, reach:1.8, baseDamage:18,
    staminaCost:7, stunLevel:3, targetZones:['head'],
    primarySkill:'kickboxing', trajectory:'HEAD_KICK_TRAJ',
    availableStates:['STAND_UP'], cutChance:0.03, bluntRatio:1.0 },

  { id:'switch_kick', name:'Switch Kick', input:'LT+Y', type:'kick',
    startup:14, active:5, recovery:16, reach:1.8, baseDamage:15,
    staminaCost:6.5, stunLevel:2, targetZones:['body','head'],
    primarySkill:'kickboxing', trajectory:'SWITCH_KICK_TRAJ',
    availableStates:['STAND_UP'], cutChance:0.02, bluntRatio:1.0 },

  { id:'front_kick_body', name:'Front Kick (Body)', input:'LT+X', type:'kick',
    startup:8, active:4, recovery:9, reach:1.6, baseDamage:9,
    staminaCost:3.5, stunLevel:1, targetZones:['body'],
    primarySkill:'kickboxing', trajectory:'FRONT_KICK_TRAJ',
    availableStates:['STAND_UP'], cutChance:0.0, bluntRatio:1.0 },

  { id:'question_mark_kick', name:'Question Mark Kick', input:'LS→+LT+Y', type:'kick',
    startup:15, active:5, recovery:20, reach:1.9, baseDamage:17,
    staminaCost:7.5, stunLevel:4, targetZones:['head'],
    primarySkill:'kickboxing', trajectory:'QMARK_KICK_TRAJ',
    availableStates:['STAND_UP'], cutChance:0.04, bluntRatio:1.0 },

  { id:'axe_kick', name:'Axe Kick', input:'LS↓+LT+Y', type:'kick',
    startup:16, active:5, recovery:18, reach:1.7, baseDamage:16,
    staminaCost:7, stunLevel:3, targetZones:['head'],
    primarySkill:'kickboxing', trajectory:'AXE_KICK_TRAJ',
    availableStates:['STAND_UP'], cutChance:0.05, bluntRatio:1.0 },

  // ── CLOSE-RANGE / CLINCH ──
  { id:'knee', name:'Knee', input:'LB+A(clinch)', type:'knee',
    startup:4, active:3, recovery:6, reach:0.6, baseDamage:10,
    staminaCost:3, stunLevel:2, targetZones:['body','head'],
    primarySkill:'muay_thai', trajectory:'KNEE_TRAJ',
    availableStates:['STAND_UP','CLINCH'], cutChance:0.01, bluntRatio:1.0 },

  { id:'elbow', name:'Elbow', input:'LB+B(clinch)', type:'elbow',
    startup:5, active:3, recovery:8, reach:0.5, baseDamage:13,
    staminaCost:3.5, stunLevel:2, targetZones:['head'],
    primarySkill:'muay_thai', trajectory:'ELBOW_TRAJ',
    availableStates:['STAND_UP','CLINCH'], cutChance:0.35, bluntRatio:0.4 },

  { id:'body_knee', name:'Body Knee', input:'X(clinch)', type:'knee',
    startup:4, active:3, recovery:6, reach:0.6, baseDamage:9,
    staminaCost:3, stunLevel:1, targetZones:['body'],
    primarySkill:'muay_thai', trajectory:'KNEE_TRAJ',
    availableStates:['CLINCH'], cutChance:0.0, bluntRatio:1.0 },

  { id:'foot_stomp', name:'Foot Stomp', input:'LS↓+A(clinch)', type:'knee',
    startup:3, active:2, recovery:4, reach:0.3, baseDamage:3,
    staminaCost:1, stunLevel:0, targetZones:['left_leg','right_leg'],
    primarySkill:'clinch_offense', trajectory:'NONE',
    availableStates:['CLINCH'], cutChance:0.02, bluntRatio:1.0 },
];
```

---

## 3. Takedown & Clinch Data

```typescript
// ── data/takedowns.ts ──

export interface TakedownDef {
  id: string;
  name: string;
  input: string;
  type: 'shot' | 'clinch_td' | 'trip' | 'throw' | 'reactive';
  startup: number;
  active: number;
  recovery: number;
  reach: number;
  baseChance: number;    // Base success probability (0-1)
  staminaCost: number;
  primarySkill: SkillId;
}

export const TAKEDOWNS: TakedownDef[] = [
  { id:'double_leg', name:'Double Leg', input:'LS→+A+LT(hold)',
    type:'shot', startup:6, active:8, recovery:12, reach:1.8,
    baseChance:0.40, staminaCost:8, primarySkill:'td_offense' },

  { id:'single_leg', name:'Single Leg', input:'LS→+X+LT',
    type:'shot', startup:8, active:6, recovery:10, reach:1.6,
    baseChance:0.35, staminaCost:7, primarySkill:'td_offense' },

  { id:'level_change_feint', name:'Level Change Feint', input:'LS↓+LT+A(tap)',
    type:'shot', startup:4, active:0, recovery:6, reach:0,
    baseChance:0, staminaCost:2, primarySkill:'td_offense' }, // Sets up strike

  { id:'body_lock_td', name:'Body Lock TD', input:'LS→+A(clinch)',
    type:'clinch_td', startup:4, active:5, recovery:8, reach:0,
    baseChance:0.45, staminaCost:6, primarySkill:'clinch_takedown' },

  { id:'trip', name:'Trip', input:'LS→+B(clinch)',
    type:'trip', startup:5, active:4, recovery:8, reach:0,
    baseChance:0.40, staminaCost:6, primarySkill:'clinch_takedown' },

  { id:'hip_throw', name:'Hip Throw', input:'LS↓+LT+B(clinch)',
    type:'throw', startup:6, active:4, recovery:10, reach:0,
    baseChance:0.35, staminaCost:7, primarySkill:'clinch_takedown' },

  { id:'ankle_pick', name:'Ankle Pick', input:'LS↓+A(clinch_low)',
    type:'clinch_td', startup:5, active:5, recovery:8, reach:0,
    baseChance:0.30, staminaCost:5, primarySkill:'clinch_takedown' },

  { id:'reactive_shot', name:'Reactive Shot', input:'LT+LS→+A(after_caught_kick)',
    type:'reactive', startup:3, active:5, recovery:8, reach:0,
    baseChance:0.50, staminaCost:5, primarySkill:'counter_td' },
];
```

---

## 4. Clinch Actions

```typescript
export interface ClinchActionDef {
  id: string;
  name: string;
  input: string;
  staminaCost: number;
  effect: string;
  primarySkill: SkillId;
}

export const CLINCH_ACTIONS: ClinchActionDef[] = [
  { id:'clinch_entry', name:'Clinch Entry', input:'LS→+A+RB',
    staminaCost:4, effect:'Enters clinch state (0.3-0.6m)', primarySkill:'clinch_offense' },
  { id:'clinch_break', name:'Clinch Break', input:'Y(escape)',
    staminaCost:3, effect:'Returns to stand-up (contested)', primarySkill:'clinch_defense' },
  { id:'pummel', name:'Pummel Win', input:'Y(pummel)',
    staminaCost:2, effect:'Control advantage (+20% next clinch action)', primarySkill:'clinch_offense' },
  { id:'cage_push', name:'Cage Push', input:'RS→+RT',
    staminaCost:3, effect:'Move opponent toward cage wall', primarySkill:'cage_wrestling' },
  { id:'wall_walk', name:'Wall Walk', input:'LS↑(cage_bottom)',
    staminaCost:5, effect:'Stand up using cage (ground only)', primarySkill:'bottom_control' },
  { id:'dirty_boxing', name:'Dirty Boxing', input:'A→B→A(rapid)',
    staminaCost:2, effect:'Close-range flurries', primarySkill:'boxing' },
];
```

---

## 5. Defensive Actions

```typescript
export interface DefenseDef {
  id: string;
  name: string;
  input: string;
  startup: number;       // Frames to activate
  activeWindow: number;  // Frames the defense is active
  recovery: number;      // Recovery frames
  staminaCost: number;
  effect: string;
}

export const DEFENSES: DefenseDef[] = [
  { id:'block', name:'Block', input:'Hold RT',
    startup:1, activeWindow:-1, recovery:3, staminaCost:1.5,
    effect:'Reduces damage 60-80%, stamina damage passes through' },
  { id:'parry', name:'Parry', input:'RS Click(timed)',
    startup:3, activeWindow:2, recovery:0, staminaCost:2,
    effect:'Deflects strike, opens 10-frame counter window' },
  { id:'slip_left', name:'Slip (Left)', input:'RS←',
    startup:1, activeWindow:4, recovery:3, staminaCost:1,
    effect:'Evades straight punches, head moves off-center' },
  { id:'slip_right', name:'Slip (Right)', input:'RS→',
    startup:1, activeWindow:4, recovery:3, staminaCost:1,
    effect:'Evades straight punches' },
  { id:'duck', name:'Duck', input:'RS↓',
    startup:2, activeWindow:5, recovery:4, staminaCost:1.5,
    effect:'Evades hooks/head kicks, vulnerable to knees/uppercuts' },
  { id:'weave', name:'Weave', input:'RS↻',
    startup:3, activeWindow:6, recovery:4, staminaCost:2,
    effect:'Circular head movement, evades combos' },
  { id:'pull_counter', name:'Pull Counter', input:'LS↓+A(timed)',
    startup:3, activeWindow:3, recovery:6, staminaCost:2.5,
    effect:'Step back + cross counter, +35% damage' },
  { id:'sprawl', name:'Sprawl', input:'RT+RS↓',
    startup:2, activeWindow:6, recovery:6, staminaCost:4,
    effect:'Defends takedown shot, chains to front headlock' },
  { id:'whizzer', name:'Whizzer Defense', input:'RT+RS→',
    startup:2, activeWindow:5, recovery:5, staminaCost:3,
    effect:'Defends single leg, chains to takedown' },
  { id:'guillotine_attempt', name:'Guillotine Attempt', input:'LT+RS↓(on_TD_shot)',
    startup:4, activeWindow:6, recovery:8, staminaCost:5,
    effect:'Sub attempt from sprawl position' },
];
```

---

## 6. Ground Position Chain & Transitions

```typescript
export const GROUND_POSITIONS = [
  'OPEN_GUARD', 'HALF_GUARD', 'SIDE_CONTROL',
  'MOUNT', 'BACK_MOUNT', 'KNEE_ON_BELLY',
  'SCRAMBLE', 'BUTTERFLY_GUARD', 'NORTH_SOUTH',
] as const;

// Forward progress (top fighter advancing):
// OPEN_GUARD → HALF_GUARD → SIDE_CONTROL → MOUNT → BACK_MOUNT

// Sweep reverses: bottom fighter takes the equivalent top position

export interface GroundTransition {
  from: string;
  to: string;
  requiredBy: 'top' | 'bottom';
  skill: [string, string];        // [attacker_skill, defender_skill]
  baseProgressRate: number;        // Per-second at 10 skill advantage
  staminaCost: number;
}

export const GROUND_TRANSITIONS: GroundTransition[] = [
  { from:'OPEN_GUARD', to:'HALF_GUARD', requiredBy:'top',
    skill:['guard_pass','guard_retention'], baseProgressRate:0.03, staminaCost:6 },
  { from:'HALF_GUARD', to:'SIDE_CONTROL', requiredBy:'top',
    skill:['guard_pass','guard_retention'], baseProgressRate:0.025, staminaCost:5 },
  { from:'SIDE_CONTROL', to:'MOUNT', requiredBy:'top',
    skill:['top_control','bottom_control'], baseProgressRate:0.04, staminaCost:5 },
  { from:'MOUNT', to:'BACK_MOUNT', requiredBy:'top',
    skill:['top_control','bottom_control'], baseProgressRate:0.035, staminaCost:4 },
  { from:'GUARD', to:'STAND_UP', requiredBy:'bottom',
    skill:['bottom_control','top_control'], baseProgressRate:0.025, staminaCost:5 },
  { from:'HALF_GUARD', to:'OPEN_GUARD', requiredBy:'bottom', // deep half sweep
    skill:['guard_retention','guard_pass'], baseProgressRate:0.03, staminaCost:2 },
];
```

---

## 7. Submission Moves

```typescript
export interface SubmissionDef {
  id: string;
  name: string;
  position: string;          // Required position
  startup: number;
  lockSpeed: number;         // Attacker progress per second (0-1 scale)
  escapeSpeed: number;       // Defender progress per second (0-1 scale)
  staminaCostAtk: number;    // Per second
  staminaCostDef: number;    // Per second
  primarySkill: SkillId;
}

export const SUBMISSIONS: SubmissionDef[] = [
  { id:'rear_naked_choke', name:'Rear Naked Choke', position:'BACK_MOUNT',
    startup:3, lockSpeed:0.4, escapeSpeed:0.2, staminaCostAtk:3, staminaCostDef:2,
    primarySkill:'sub_offense' },
  { id:'armbar', name:'Armbar', position:'MOUNT/GUARD',
    startup:4, lockSpeed:0.3, escapeSpeed:0.25, staminaCostAtk:3, staminaCostDef:2,
    primarySkill:'sub_offense' },
  { id:'triangle', name:'Triangle Choke', position:'GUARD(bottom)',
    startup:5, lockSpeed:0.35, escapeSpeed:0.2, staminaCostAtk:3.5, staminaCostDef:2,
    primarySkill:'sub_offense' },
  { id:'kimura', name:'Kimura', position:'SIDE_CONTROL',
    startup:4, lockSpeed:0.3, escapeSpeed:0.3, staminaCostAtk:3, staminaCostDef:2.5,
    primarySkill:'sub_offense' },
  { id:'guillotine', name:'Guillotine', position:'FRONT_HEADLOCK/SPRAWL',
    startup:3, lockSpeed:0.4, escapeSpeed:0.25, staminaCostAtk:3.5, staminaCostDef:2,
    primarySkill:'sub_offense' },
  { id:'arm_triangle', name:'Arm Triangle', position:'SIDE/MOUNT',
    startup:5, lockSpeed:0.3, escapeSpeed:0.2, staminaCostAtk:3, staminaCostDef:2,
    primarySkill:'sub_offense' },
  { id:'omoplata', name:'Omoplata', position:'GUARD(bottom)',
    startup:6, lockSpeed:0.25, escapeSpeed:0.3, staminaCostAtk:3.5, staminaCostDef:2.5,
    primarySkill:'sub_offense' },
  { id:'heel_hook', name:'Heel Hook', position:'50-50/LEG_ENTANGLE',
    startup:4, lockSpeed:0.5, escapeSpeed:0.15, staminaCostAtk:4, staminaCostDef:2,
    primarySkill:'sub_offense' },
];
```

---

## 8. Move Variants (80+)

```typescript
// ── data/variants.ts ──

export interface MoveVariantDef {
  variantId: string;
  baseMoveId: string;       // Which move this is a variant of
  name: string;
  description: string;
  // Multipliers (1.0 = unchanged)
  startupMult: number;
  recoveryMult: number;
  damageMult: number;
  staminaCostMult: number;
  reachMult: number;
  hitChanceMult: number;
  cutChanceAdd: number;     // Flat addition to cut chance
  // Requirements
  requiredStrikeLevel: number; // Minimum level in base move
  requiredSkills: [SkillId, number][]; // [skill, min_value][]
  // Cost to purchase
  xpCostMultiplier: number; // xpCost = max(10, baseXP * this)
}

// ── JAB VARIANTS (8) ──
export const JAB_VARIANTS: MoveVariantDef[] = [
  { variantId:'jab_heavy', baseMoveId:'jab', name:'Heavy Jab',
    description:'Slower but punches through guards',
    startupMult:1.3, recoveryMult:1.2, damageMult:1.5, staminaCostMult:1.6,
    reachMult:1.0, hitChanceMult:0.9, cutChanceAdd:0.03,
    requiredStrikeLevel:2, requiredSkills:[['boxing',30]], xpCostMultiplier:1 },

  { variantId:'jab_snap_boxing', baseMoveId:'jab', name:'Snap Jab (Boxing)',
    description:'Boxing-style snap — faster, shorter',
    startupMult:0.8, recoveryMult:0.7, damageMult:0.85, staminaCostMult:0.8,
    reachMult:0.9, hitChanceMult:1.1, cutChanceAdd:0.01,
    requiredStrikeLevel:3, requiredSkills:[['boxing',40]], xpCostMultiplier:1.5 },

  { variantId:'jab_fast', baseMoveId:'jab', name:'Fast Jab',
    description:'Ultra-fast, low damage',
    startupMult:0.6, recoveryMult:0.6, damageMult:0.7, staminaCostMult:0.7,
    reachMult:0.95, hitChanceMult:1.15, cutChanceAdd:0,
    requiredStrikeLevel:2, requiredSkills:[['boxing',25]], xpCostMultiplier:0.8 },

  { variantId:'jab_thai', baseMoveId:'jab', name:'Thai Jab',
    description:'Stepping jab with more body commitment',
    startupMult:0.9, recoveryMult:1.0, damageMult:1.1, staminaCostMult:1.2,
    reachMult:1.05, hitChanceMult:1.0, cutChanceAdd:0.0,
    requiredStrikeLevel:2, requiredSkills:[['muay_thai',30]], xpCostMultiplier:1 },

  { variantId:'jab_karate_snap', baseMoveId:'jab', name:'Karate Snap Jab',
    description:'Snappy, long-range jab from bladed stance',
    startupMult:0.7, recoveryMult:0.8, damageMult:0.8, staminaCostMult:0.75,
    reachMult:1.15, hitChanceMult:1.05, cutChanceAdd:0.01,
    requiredStrikeLevel:3, requiredSkills:[['kickboxing',40]], xpCostMultiplier:1.5 },

  { variantId:'jab_efficient', baseMoveId:'jab', name:'Efficient Jab',
    description:'Conserves energy, sets up combos',
    startupMult:1.0, recoveryMult:0.85, damageMult:0.9, staminaCostMult:0.6,
    reachMult:1.0, hitChanceMult:1.0, cutChanceAdd:0,
    requiredStrikeLevel:2, requiredSkills:[['endurance',40]], xpCostMultiplier:0.8 },

  { variantId:'jab_power_shot', baseMoveId:'jab', name:'Power Jab',
    description:'Shifts weight fully into the jab',
    startupMult:1.5, recoveryMult:1.4, damageMult:1.8, staminaCostMult:2.0,
    reachMult:1.0, hitChanceMult:0.8, cutChanceAdd:0.05,
    requiredStrikeLevel:4, requiredSkills:[['boxing',60],['strength',70]],
    xpCostMultiplier:2.5 },

  { variantId:'jab_check_hook', baseMoveId:'jab', name:'Check Jab → Hook',
    description:'Jab that transitions to a hook if opponent rushes in',
    startupMult:1.1, recoveryMult:1.3, damageMult:1.2, staminaCostMult:1.3,
    reachMult:1.0, hitChanceMult:0.85, cutChanceAdd:0.02,
    requiredStrikeLevel:4, requiredSkills:[['boxing',50],['speed',60]],
    xpCostMultiplier:2 },
];

// ── CROSS VARIANTS (8) ──
export const CROSS_VARIANTS: MoveVariantDef[] = [
  { variantId:'cross_heavy', baseMoveId:'cross', name:'Heavy Cross',
    startupMult:1.4, recoveryMult:1.3, damageMult:1.6, staminaCostMult:1.7,
    reachMult:1.0, hitChanceMult:0.85, cutChanceAdd:0.04,
    requiredStrikeLevel:2, requiredSkills:[['boxing',30]], xpCostMultiplier:1 },

  { variantId:'cross_power_boxing', baseMoveId:'cross', name:'Power Cross (Boxing)',
    startupMult:1.2, recoveryMult:1.2, damageMult:1.7, staminaCostMult:1.8,
    reachMult:1.0, hitChanceMult:0.9, cutChanceAdd:0.04,
    requiredStrikeLevel:3, requiredSkills:[['boxing',50]], xpCostMultiplier:1.5 },

  { variantId:'cross_fast', baseMoveId:'cross', name:'Fast Cross',
    startupMult:0.7, recoveryMult:0.7, damageMult:0.8, staminaCostMult:0.8,
    reachMult:1.0, hitChanceMult:1.1, cutChanceAdd:0.01,
    requiredStrikeLevel:2, requiredSkills:[['boxing',25]], xpCostMultiplier:0.8 },

  { variantId:'cross_reverse_karate', baseMoveId:'cross', name:'Reverse Cross (Karate)',
    startupMult:0.8, recoveryMult:0.9, damageMult:1.1, staminaCostMult:1.0,
    reachMult:1.2, hitChanceMult:1.05, cutChanceAdd:0.02,
    requiredStrikeLevel:3, requiredSkills:[['kickboxing',40]], xpCostMultiplier:1.5 },

  { variantId:'cross_efficient', baseMoveId:'cross', name:'Efficient Cross',
    startupMult:1.0, recoveryMult:0.85, damageMult:0.9, staminaCostMult:0.65,
    reachMult:1.0, hitChanceMult:1.0, cutChanceAdd:0,
    requiredStrikeLevel:2, requiredSkills:[['endurance',35]], xpCostMultiplier:0.8 },

  { variantId:'cross_overhand_hybrid', baseMoveId:'cross', name:'Overhand Cross',
    startupMult:1.3, recoveryMult:1.3, damageMult:1.4, staminaCostMult:1.4,
    reachMult:1.1, hitChanceMult:0.8, cutChanceAdd:0.03,
    requiredStrikeLevel:4, requiredSkills:[['boxing',55]], xpCostMultiplier:2 },
];

// ── Additional variant sets exist for: hook, uppercut, front_kick,
//     roundhouse, leg_kick, head_kick, knee, elbow
//     Each has 6-10 variants following the same schema pattern.
// Total: ~80+ variants across 10 strike types.
```

---

## 9. Combo Trees

```typescript
// ── data/combos.ts ──

export interface ComboLink {
  fromStrikeId: string;
  toStrikeId: string;
  comboWindowExtension: number;    // Seconds added to the input window
  finalDamageMultiplier: number;   // Applied to the LAST strike in chain
}

// Combos are stored as a directed graph:
// Level 1 → Level 2 → Level 3 → Level 4

// PUNCH COMBOS
export const PUNCH_COMBOS: ComboLink[] = [
  // Level 2 (2-hit)
  { fromStrikeId:'jab', toStrikeId:'cross', comboWindowExtension:0.2, finalDamageMultiplier:1.0 },
  { fromStrikeId:'cross', toStrikeId:'hook', comboWindowExtension:0.15, finalDamageMultiplier:1.0 },
  { fromStrikeId:'hook', toStrikeId:'uppercut', comboWindowExtension:0.1, finalDamageMultiplier:1.0 },

  // Level 3 (3-hit) — final strike gets damage bonus
  { fromStrikeId:'cross', toStrikeId:'hook', comboWindowExtension:0.15, finalDamageMultiplier:1.1 },  // 1-2-3
  { fromStrikeId:'cross', toStrikeId:'uppercut', comboWindowExtension:0.1, finalDamageMultiplier:1.15 }, // 1-2-4
  { fromStrikeId:'hook', toStrikeId:'cross', comboWindowExtension:0.15, finalDamageMultiplier:1.1 },  // 1-3-2
  { fromStrikeId:'hook', toStrikeId:'uppercut', comboWindowExtension:0.1, finalDamageMultiplier:1.15 }, // 2-3-4

  // Level 4 (4-hit)
  { fromStrikeId:'hook', toStrikeId:'overhand', comboWindowExtension:0.1, finalDamageMultiplier:1.2 }, // 1-2-3-5
  { fromStrikeId:'hook', toStrikeId:'uppercut', comboWindowExtension:0.1, finalDamageMultiplier:1.15 }, // 1-2-3-4
];

// KICK → STRIKE
export const KICK_COMBOS: ComboLink[] = [
  { fromStrikeId:'front_kick', toStrikeId:'cross', comboWindowExtension:0.15, finalDamageMultiplier:1.0 },
  { fromStrikeId:'leg_kick', toStrikeId:'cross', comboWindowExtension:0.15, finalDamageMultiplier:1.0 },
  { fromStrikeId:'leg_kick', toStrikeId:'roundhouse', comboWindowExtension:0.15, finalDamageMultiplier:1.15 },
  { fromStrikeId:'roundhouse', toStrikeId:'hook', comboWindowExtension:0.1, finalDamageMultiplier:1.0 },
  { fromStrikeId:'front_kick', toStrikeId:'head_kick', comboWindowExtension:0.0, finalDamageMultiplier:1.0 },
];

// STRIKE → TAKEDOWN
export const STRIKE_TO_TD_COMBOS: ComboLink[] = [
  { fromStrikeId:'jab', toStrikeId:'double_leg', comboWindowExtension:0.2, finalDamageMultiplier:1.0 },
  { fromStrikeId:'cross', toStrikeId:'single_leg', comboWindowExtension:0.15, finalDamageMultiplier:1.0 },
  { fromStrikeId:'hook', toStrikeId:'body_lock_td', comboWindowExtension:0.15, finalDamageMultiplier:1.0 },
  { fromStrikeId:'front_kick', toStrikeId:'reactive_shot', comboWindowExtension:0.0, finalDamageMultiplier:1.0 },
];

// Combo Rules (enforced in code):
// - Each strike in chain: -5% recovery per link (combo_chain_bonus)
// - Each strike beyond 3rd: -5% accuracy
// - Miss resets the combo chain
// - Chain resets after 0.8s of no strikes
// - Max chain length: Math.floor(SPD / 15) + 2 (SPD 50 = 5, SPD 90 = 8)
```

---

## 10. Frame Data Modifier Formulas

```typescript
// ── core/frameMath.ts ──

export function calcStartupFrames(baseStartup: number, fighter: FighterData): number {
  return Math.max(1, Math.floor(
    baseStartup * getSPDMultiplier(fighter.SPD) *
    getGassedMultiplier(fighter) /
    getLimbSpeedMultiplier(fighter, strikeType)
  ));
}

export function calcDamage(baseDamage: number, fighter: FighterData, defender: FighterData,
                           variant: MoveVariantDef | null, isCounter: boolean,
                           isPerfect: boolean, range: number): number {
  let dmg = baseDamage * (1 + fighter.STR * 0.01);
  dmg *= getSkillMultiplier(fighter, strikeType);
  dmg *= getRangeFalloff(range, optimalRange);
  dmg *= getLimbPowerMultiplier(fighter, strikeType);
  if (variant) dmg *= variant.damageMult;
  if (isCounter) dmg *= 1.35;
  if (isPerfect) dmg *= 1.25;
  dmg *= defender.getDerived('dmgTakenMult');
  return dmg;
}

// Modifier Tables:
const SPD_MULT: Record<number, number> = {
  0: 1.8,  // Slowest
  50: 1.0, // Baseline
  100: 0.6, // Fastest
};

export function getSPDMultiplier(spd: number): number {
  if (spd <= 0) return 1.8;
  if (spd >= 100) return 0.6;
  return 1.8 - (spd * 0.012); // Linear interpolation
}

// Gassed penalty
export function isGassed(stamina: number, maxStamina: number, gassedThreshold: number): boolean {
  return (stamina / maxStamina) < (gassedThreshold / 100);
}
// When gassed: startup ×1.3, recovery ×1.5, reach ×0.85, damage ×0.7

// Stamina cost (after modifiers)
export function calcStaminaCost(baseCost: number, fighter: FighterData,
                                variant: MoveVariantDef | null): number {
  let cost = baseCost * fighter.getDerived('staminaDrainMult');
  if (variant) cost *= variant.staminaCostMult;
  if (isGassed(fighter)) cost *= 1.3;
  return cost;
}
```

---

## 11. Style Definitions

```typescript
export type StyleId = 'boxing' | 'muay_thai' | 'kickboxing' | 'karate'
                    | 'wrestling' | 'bjj' | 'generic_mma' | 'judo' | 'sambo'
                    | 'taekwondo' | 'capoeira' | 'savate';

export interface StyleDef {
  id: StyleId;
  name: string;
  statModifiers: Partial<Record<string, number>>; // +- to specific skills
  preferredRange: number;                          // Ideal combat range
  stanceBonus: string;
  specialMechanic: string;                         // Unique perk
}

export const STYLES: Record<StyleId, StyleDef> = {
  boxing: {
    id:'boxing', name:'Boxing',
    statModifiers: { boxing:+12, kickboxing:-8, muayThai:-5, footwork:+5 },
    preferredRange: 1.2,
    stanceBonus: '+5% punch damage, +10% head movement speed',
    specialMechanic: 'Check Hook — jab feint into hook on rush',
  },
  muay_thai: {
    id:'muay_thai', name:'Muay Thai',
    statModifiers: { muayThai:+12, kickboxing:+5, clinch_offense:+8, boxing:-5 },
    preferredRange: 1.5,
    stanceBonus: '+10% elbow/knee damage, +15% clinch power',
    specialMechanic: 'Thai Clinch — extended clinch control, free knee chain',
  },
  kickboxing: {
    id:'kickboxing', name:'Kickboxing',
    statModifiers: { kickboxing:+12, muayThai:+3, boxing:-3, footwork:+5 },
    preferredRange: 1.8,
    stanceBonus: '+10% kick damage, +5% kick speed',
    specialMechanic: 'Switch Kick — resets to opposite stance after kick',
  },
  karate: {
    id:'karate', name:'Karate',
    statModifiers: { kickboxing:+10, footwork:+10, head_movement:+3, clinch_offense:-8, td_offense:-8 },
    preferredRange: 2.0,
    stanceBonus: '+15% kick reach, +10% counter window',
    specialMechanic: 'Bladed Stance — reduced body hitbox, longer reach',
  },
  wrestling: {
    id:'wrestling', name:'Wrestling',
    statModifiers: { td_offense:+12, td_defense:+8, top_control:+10,
                     clinch_takedown:+8, boxing:-8, kickboxing:-10 },
    preferredRange: 0.8,
    stanceBonus: '+15% takedown success, +10% top control speed',
    specialMechanic: 'Chain Wrestling — transition chain costs -2 stamina per link',
  },
  bjj: {
    id:'bjj', name:'Brazilian Jiu-Jitsu',
    statModifiers: { sub_offense:+15, sub_defense:+10, bottom_control:+12,
                     guard_retention:+10, boxing:-10, kickboxing:-8 },
    preferredRange: 0.6,
    stanceBonus: '+15% submission speed, +10% guard retention',
    specialMechanic: 'Invisible Jiu-Jitsu — +5 frame submission setup window',
  },
  generic_mma: {
    id:'generic_mma', name:'Generic MMA',
    statModifiers: { boxing:+5, kickboxing:+5, wrestling:+5, bjj:+5 },
    preferredRange: 1.3,
    stanceBonus: 'No penalties, no bonuses',
    specialMechanic: 'Adaptable — combo chains cost -1 stamina per link',
  },
  // Additional styles (future):
  judo: { id:'judo', name:'Judo', /* hip throws, trips, +clinch throws */ },
  sambo: { id:'sambo', name:'Sambo', /* leg locks, reaping, +heel hooks */ },
  taekwondo: { id:'taekwondo', name:'Taekwondo', /* high kicks, spinning, +head kick speed */ },
  capoeira: { id:'capoeira', name:'Capoeira', /* evasive, unpredictable, +dodge frames */ },
  savate: { id:'savate', name:'Savate', /* French kickboxing, feet only, +front kick damage */ },
};
```

---

## 12. Hit Reaction / Stun Table

```typescript
export enum StunTier {
  NONE = 0,
  DAZE = 1,
  HEAVY_DAZE = 2,
  STUN = 3,
  HEAVY_STUN = 4,
  KNOCKDOWN = 5,
  KO = 6,
}

export interface StunEffect {
  duration: [number, number];  // min-max seconds
  canBlock: boolean;
  canMove: boolean;
  canStrike: boolean;
  canClinch: boolean;
  visual: string;  // Description of procedural animation override
}

export const STUN_EFFECTS: Record<StunTier, StunEffect> = {
  0: { duration:[0,0], canBlock:true, canMove:true, canStrike:true, canClinch:true,
       visual:'Normal' },
  1: { duration:[0.15,0.35], canBlock:true, canMove:true, canStrike:true, canClinch:true,
       visual:'Head snap -15° pitch, 0.1s reach, 0.05s recover' },
  2: { duration:[0.35,0.5], canBlock:true, canMove:false, canStrike:true, canClinch:true,
       visual:'Head -25° pitch, arms drop 10°, 0.15s recover' },
  3: { duration:[0.8,1.5], canBlock:false, canMove:false, canStrike:false, canClinch:true,
       visual:'Full upper body back, arms wide, legs wobble' },
  4: { duration:[1.5,2.5], canBlock:false, canMove:false, canStrike:false, canClinch:false,
       visual:'Stumble backward 0.5m, 40% ragdoll blend' },
  5: { duration:[3.0,5.0], canBlock:false, canMove:false, canStrike:false, canClinch:false,
       visual:'Full ragdoll 0.3s, then getup attempt at 60% duration' },
  6: { duration:[999,999], canBlock:false, canMove:false, canStrike:false, canClinch:false,
       visual:'Permanent ragdoll, fight over' },
};
```

---

## 13. Enums & Shared Types

```typescript
// ── types/combat.ts ──

export enum FightState {
  STAND_UP = 0,
  CLINCH = 1,
  GROUND_TOP = 2,
  GROUND_BOTTOM = 3,
  SUBMISSION_TOP = 4,
  SUBMISSION_BOTTOM = 5,
  KO = 6,
  TKO = 7,
}

export enum BodyZone {
  HEAD = 'head',
  TORSO = 'torso',
  LEFT_ARM = 'left_arm',
  RIGHT_ARM = 'right_arm',
  LEFT_LEG = 'left_leg',
  RIGHT_LEG = 'right_leg',
}

export enum StrikeType {
  JAB, CROSS, HOOK, UPPERCUT, ROUNDHOUSE,
  FRONT_KICK, LEG_KICK, HEAD_KICK, KNEE, ELBOW,
  SWITCH_KICK, FRONT_KICK_BODY,
}

export enum WeightClass {
  STRAW, FLY, BANTAM, FEATHER, LIGHT,
  WELTER, MIDDLE, LHW, HW,
}

export enum DamageType {
  BLUNT = 0,
  SHARP = 1,
  SUBMISSION = 2,
  ACCUMULATED = 3,
}

export type SkillId =
  | 'boxing' | 'kickboxing' | 'muay_thai' | 'head_movement' | 'footwork'
  | 'clinch_offense' | 'clinch_defense' | 'clinch_takedown'
  | 'td_offense' | 'td_defense' | 'counter_td' | 'cage_wrestling'
  | 'top_control' | 'bottom_control' | 'guard_pass' | 'guard_retention'
  | 'sub_offense' | 'sub_defense';

export type TrajectoryId =
  | 'JAB_TRAJ' | 'CROSS_TRAJ' | 'HOOK_TRAJ' | 'UPPERCUT_TRAJ'
  | 'OVERHAND_TRAJ' | 'SUPERMAN_TRAJ'
  | 'FRONT_KICK_TRAJ' | 'ROUNDHOUSE_TRAJ' | 'LEG_KICK_TRAJ'
  | 'HEAD_KICK_TRAJ' | 'SWITCH_KICK_TRAJ' | 'QMARK_KICK_TRAJ'
  | 'AXE_KICK_TRAJ' | 'KNEE_TRAJ' | 'ELBOW_TRAJ' | 'NONE';
```

---

## 14. Derived Stats Formulas

```typescript
export function calcDerived(f: FighterData): DerivedStats {
  return {
    maxStamina: 100 + f.endurance * 0.5,
    punchBaseDmg: 5 + f.strength * 0.12,
    kickBaseDmg: 8 + f.strength * 0.10,
    strikeSpeedMult: 1.8 - f.speed * 0.012,
    staminaDrainMult: 1.6 - f.endurance * 0.011,
    koThreshold: 30 + f.toughness * 0.7,
    dmgTakenMult: 1 - f.toughness * 0.0035,  // 0.65 at TGH 100
    moveSpeedMult: 0.8 + f.speed * 0.008,    // 1.6 at SPD 100
    accuracyBonus: 0.6 + f.speed * 0.005,     // 1.1 at SPD 100
    reactionFrames: 18 - f.speed * 0.12,      // 6 at SPD 100
    gnpDamageMult: 0.3 + f.strength * 0.005,  // 0.8 at STR 100
    clinchPush: 0.2 + f.strength * 0.004,     // 0.6 at STR 100
    takedownPower: 0.7 + f.strength * 0.004,  // 1.1 at STR 100
  };
}
```

---

## 15. Project Scaffold (package.json)

```json
{
  "name": "gladiator-ultra",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest run"
  },
  "dependencies": {
    "three": "^0.170.0"
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "vite": "^5.4.0",
    "vitest": "^2.0.0",
    "@types/three": "^0.170.0"
  }
}
```

---

> **For FAble 5:** Start with `src/data/fighters.ts`, `src/data/moves.ts`, and `src/core/ImpactCalculator.ts` — these are pure math with no visual dependencies. Test them with `vitest` before building any 3D content. Then add `src/fighter/FighterStateMachine.ts` and wire in keyboard input. The 3D visuals (`FighterModel.ts`, `ArenaScene.ts`) come last once the combat math is verified.
