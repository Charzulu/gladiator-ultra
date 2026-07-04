# Fighter Attribute & Control System — Design Document v2

> **Genre target:** MMA simulation (primary), beat-em-up (compatible), fighting game (compatible)
> **Control target:** Mirror EA UFC5 control scheme — stand-up striking, clinch, ground grappling, transition denial
> **Design principles:** Physics-first combat, data-driven fighters, modular stat schema, control-accurate state machine
> **Influences:** EA UFC5 (controls + damage + ground game), UFC Undisputed 3 (skill depth + career), Virtua Fighter (clean data + low poly)

---

## 1. Stat Architecture Overview

Two-tier attribute system:

```
FighterData (Resource)
  ├── Identity         — name, weight class, nationality, record, age, reach
  ├── Core Stats       — 4 universal physical attributes (0-100)
  ├── Combat Skills    — 18 position/range-specific skills (0-100)
  ├── Health Profile   — 7 durability + injury attributes (0-100)
  ├── Stamina Profile  — 5 energy system attributes (0-100)
  ├── Style Data       — fighting style + modifier table + animation set reference
  └── Progression      — career state (experience points, training camp, injury recovery)
```

**Rating scale:**

| Range | Label | Meaning |
|-------|-------|---------|
| 0-19 | Poor | Exploitable weakness |
| 20-39 | Below Avg | Journeyman level |
| 40-59 | Average | Professional competence |
| 60-74 | Good | Contender caliber |
| 75-89 | Elite | Championship level |
| 90-100 | World-class | GOAT tier |

---

## 2. Core Stats (4 universal attributes)

Every genre uses these. They form the "genotype" from which all derived combat math values are computed.

### STR — Strength

Controls the raw power behind every action. Affects damage output, grapple control, and takedown drive.

| Value | Effect | Gameplay Feel |
|-------|--------|---------------|
| 0-19 | Base damage ×0.5, takedown power ×0.4 | Feather-fisted, can't hold takedowns |
| 20-39 | Base damage ×0.7, takedown power ×0.7 | Weak punches, easily reversed |
| 40-59 | Base damage ×1.0, takedown power ×1.0 | Baseline — average fighter |
| 60-74 | Base damage ×1.2, takedown power ×1.3 | Noticeable pop on punches, drives through shots |
| 75-89 | Base damage ×1.4, takedown power ×1.6 | Fighters feel the impact; strong clinch control |
| 90-100 | Base damage ×1.6, takedown power ×2.0 | Devastating power; one-punch KO threat |

**Derived values from STR:**
```
base_punch_damage = 5 + (STR × 0.12)            // range: 5-17
base_kick_damage  = 8 + (STR × 0.10)            // range: 8-18
takedown_power    = 0.4 + (STR × 0.006)          // range: 0.4-1.0 (multiplier)
clinch_push_power = 0.3 + (STR × 0.005)          // range: 0.3-0.8
gnp_damage_mult   = 0.5 + (STR × 0.005)          // range: 0.5-1.0 (ground-and-pound)
```

### SPD — Speed

Controls how fast the fighter executes everything. Attack startup frames, movement speed, reaction window for denials, combo linking speed, and accuracy through hand speed.

| Value | Effect | Gameplay Feel |
|-------|--------|---------------|
| 0-19 | Strike frames ×1.8, move speed ×0.6, reaction time +6 frames | Sluggish, throws look telegraphed |
| 20-39 | Strike frames ×1.4, move speed ×0.8, reaction time +3 frames | Heavy-footed, slow combinations |
| 40-59 | Strike frames ×1.0, move speed ×1.0, reaction time baseline | Average — everything baseline |
| 60-74 | Strike frames ×0.85, move speed ×1.15, reaction time -2 frames | Snappy punches, quicker on the trigger |
| 75-89 | Strike frames ×0.75, move speed ×1.3, reaction time -5 frames | Fast hands, sharp movement |
| 90-100 | Strike frames ×0.6, move speed ×1.5, reaction time -8 frames | Blinding speed, can chain 4+ strike combos |

**Derived values from SPD:**
```
strike_speed_mult = 1.8 - (SPD × 0.012)                       // range: 1.8-0.6
move_speed_mult   = 0.6 + (SPD × 0.009)                       // range: 0.6-1.5
reaction_frames   = 15 - (SPD × 0.14)                         // range: 15-1 (denial/block window)
combo_link_window = 0.3 + (SPD × 0.005)                       // range: 0.3-0.8 seconds
accuracy_bonus    = 0.8 + (SPD × 0.002)                       // range: 0.8-1.0 (hit chance mult)
```

### END — Endurance

Controls stamina economy. High END means slow stamina drain, fast recovery, late gassing. Low END means the fighter is compromised by round 2.

| Value | Effect | Gameplay Feel |
|-------|--------|---------------|
| 0-19 | Stamina pool ×0.6, drain ×1.6, recovery 1/s, gas at 35% | Gassed by mid-round 1, constant heavy breathing |
| 20-39 | Stamina pool ×0.8, drain ×1.3, recovery 2/s, gas at 30% | Gassed by round 2, heavy penalties early |
| 40-59 | Stamina pool ×1.0, drain ×1.0, recovery 4/s, gas at 25% | Baseline — normal pacing |
| 60-74 | Stamina pool ×1.15, drain ×0.85, recovery 5/s, gas at 20% | Strong gas tank, can maintain output |
| 75-89 | Stamina pool ×1.3, drain ×0.7, recovery 7/s, gas at 15% | Excellent cardio, still strong in round 5 |
| 90-100 | Stamina pool ×1.5, drain ×0.5, recovery 10/s, gas at 10% | Never seems to tire, fights same pace all fight |

**Derived values from END:**
```
max_stamina       = 100 + (END × 0.5)                          // range: 100-150
stamina_drain     = 1.6 - (END × 0.011)                        // range: 1.6-0.5
stamina_recovery  = 1.0 + (END × 0.09)                         // range: 1-10 / second
gassed_threshold  = 0.35 - (END × 0.0025)                      // range: 35%-10% of max
cardio_drop_round = 5 - (END × 0.04)                           // range: 5-1 (which round drain starts accelerating)
```

### TGH — Toughness

Controls damage mitigation, KO resistance, limb break resistance, and recovery from damage. The stat that keeps a fighter in the fight.

| Value | Effect | Gameplay Feel |
|-------|--------|---------------|
| 0-19 | Damage taken ×1.5, KO threshold 30, limb HP 50 | Glass jaw, breaks easily |
| 20-39 | Damage taken ×1.3, KO threshold 40, limb HP 65 | Fragile, one clean shot can end it |
| 40-59 | Damage taken ×1.0, KO threshold 50, limb HP 80 | Baseline — typical durability |
| 60-74 | Damage taken ×0.85, KO threshold 65, limb HP 95 | Absorbs punishment, tough to finish |
| 75-89 | Damage taken ×0.7, KO threshold 80, limb HP 110 | Iron chin, walks through shots |
| 90-100 | Damage taken ×0.5, KO threshold 100, limb HP 130 | Almost impossible to KO, relentless |

**Derived values from TGH:**
```
damage_taken_mult = 1.5 - (TGH × 0.01)                         // range: 1.5-0.5
ko_threshold      = 30 + (TGH × 0.7)                            // range: 30-100 (damage to trigger KO check)
limb_hp           = 50 + (TGH × 0.8)                            // range: 50-130
torso_hp          = 100 + (TGH × 1.0)                           // range: 100-200
recovery_mult     = 0.3 + (TGH × 0.005)                         // range: 0.3-0.8 (between-round HP recovery)
```

---

## 3. Combat Skills (18 skills across 5 ranges)

Each skill is 0-100 and represents technical proficiency in that domain. These are the MMA-specific layer. Skills interact with Core Stats multiplicatively — a fighter with 90 Boxing and 20 STR throws weak but technically perfect punches.

### 3.1 Stand-up Striking (ranges: Long → Mid → Close)

| Skill | What It Governs | Math Application |
|-------|----------------|------------------|
| **Boxing** (0-100) | Jab, cross, hook, uppercut accuracy + damage scaling + combo speed | `hit_chance = (Boxing/100) × accuracy_bonus × (1 - stamina_penalty)` |
| **Kickboxing** (0-100) | Roundhouse, front, side, switch kick accuracy + speed + recovery on miss | `kick_range = 1.0 + (Kickboxing × 0.01)` (meters) |
| **Muay Thai** (0-100) | Knee, elbow, teep, leg kick precision + cut chance + clinch strike speed | `cut_chance_mult = MuayThai / 100` |
| **Head Movement** (0-100) | Slip, duck, weave, pull counter effectiveness | `evasion_chance = (HeadMovement/100) × reaction_frames/15` |
| **Footwork** (0-100) | Lateral speed, pivot rate, stance transitions, lunges | `move_mult = 0.7 + (Footwork × 0.005)` (mult on base SPD speed) |

**Striking control map (stand-up):**

```
Left Stick (LS)       → Movement (8-dir)
Right Stick (RS)      → Head movement (slip up/duck down/slip left/slip right)
                        Click RS → Parry

Face Buttons:
┌────────┬────────┐
│   Y    │   RB   │  ← FACE BUTTONS (context-sensitive)
│  Rear  │  High  │
│  Kick  │ Mod    │
├────────┼────────┤
│   X    │   B    │
│  Lead  │  Rear  │
│  Kick  │  Hook  │
├────────┼────────┤
│        │   A    │
│        │  Lead  │
│        │  Hand  │
└────────┴────────┘

Shoulder/Trigger Modifiers:
  LB (L1)  → High target (aim head) — held while pressing face buttons
  RB (R1)  → Low target (aim body/legs)
  LT (L2)  → Perfect striking window — tap for damage bonus on next landed strike
  RT (R2)  → Block (hold to guard)

Directional + Face Button Combos (Stand-up):
  LS Forward + A       → Lunge jab / step-in cross
  LS Back + A          → Step-back jab / pull counter
  LS Lateral + A       → Pivot hook
  LS Down + A          → Body jab (if LB held) / Leg jab kick (if RB held)

  A → A                → Jab → Cross (1-2 combo)
  A → A → B            → Jab → Cross → Hook (1-2-3)
  X → A                → Lead kick → Cross
  B (hold) + LS dir    → Lunging hook / stepping uppercut
```

### 3.2 Clinch (range: Tie-up — 0.3m-0.6m)

| Skill | What It Governs | Math Application |
|-------|----------------|------------------|
| **Clinch Offense** (0-100) | Initiating clinch, pummel wins, dirty boxing control | `clinch_entry_success = (ClinchOff/100) × (SPD/100) × 0.5 + 0.3` |
| **Clinch Defense** (0-100) | Escaping clinch, framing, cage push, pummel defense | `escape_chance = (ClinchDef/100) × reaction_frames/15` |
| **Clinch Takedown** (0-100) | Takedowns from clinch (body lock, inside trip, whizzer kick) | `clinch_td_success = (ClinchTD/100) × (STR/100)` |

**Clinch control map:**
```
Entering Clinch:
  LS Toward Opponent + A (RB/R1 held)  → Clinch entry attempt (if in range)

Inside Clinch (Offense — controlling):
  A                  → Knee strike (body)
  B                  → Elbow strike (head)
  X                  → Foot stomp / body knee
  Y                  → Pummel position (push opponent, gain control advantage)
  LS Hold + A         → Body lock takedown attempt
  LS Hold + B         → Hip toss / trip attempt
  RS Direction + RT   → Cage push (move opponent to cage)

Inside Clinch (Defense — controlled):
  A                  → Block knee (check)
  B                  → Frame / push off
  X                  → Pummel defense (fight for underhooks)
  Y                  → Whip escape / spin out
  RS Direction       → Head placement / posture
  RS Down + Y        → Whizzer defense / drop to single leg
```

**Denial in clinch:**
Opponent attempts pummel or takedown → Direction+Button prompt appears → Match the prompt direction + tap RT(R2) to deny.

### 3.3 Takedowns (entry from stand-up)

| Skill | What It Governs | Math Application |
|-------|----------------|------------------|
| **TD Offense** (0-100) | Double/single leg penetration, level change speed, recovery on miss | `td_reach_bonus = 0.2 + (TDOff/100) × 0.3` (extra drive meters) |
| **TD Defense** (0-100) | Sprawl timing, underhook strength, whizzer, balance recovery | `sprawl_success = (TDDef/100) × (TGH/100)` |
| **Counter TD** (0-100) | Catch kicks → takedown, re-shots on sprawls, snap down | `counter_window = 0.1 + (CounterTD/100) × 0.2` (seconds window) |
| **Cage Wrestling** (0-100) | Cage takedown probability, wall walk speed, cage control | `cage_td_mult = 0.5 + (CageWrestling/100) × 0.5` |

**Takedown control map:**
```
Stand-up Takedown Entry:
  LS Toward Opponent + A (hold)  → Double leg shot (standard)
  LS Toward + LT(L2) + A         → Single leg (duck under)
  LS Back + LT(L2) + A           → Level change feint → shot
  LS Lateral + LT(L2) + B        → Body lock (to fence walk)

Defending Takedowns:
  RT(R2) + RS Down               → Sprawl (default)
  RT(R2) + RS Lateral            → Whizzer / underhook
  LT(L2) + RS Down               → Guillotine attempt on shot
  LT(L2) + RS Lateral            → Kimura trap on shot (advanced)

After Failed Shot:
  A (immediately)                → Re-shot attempt
  Y                              → Stand up immediately
  LS Direction + B               → Transition to single/crab ride
```

### 3.4 Ground — Top (dominant position)

| Skill | What It Governs | Math Application |
|-------|----------------|------------------|
| **Top Control** (0-100) | GNP damage multiplier, posture maintenance, position retention | `gnp_damage = (TopControl/100) × base_gnp × (STR/100)` |
| **Guard Passing** (0-100) | Passing to mount/side-control/crucifix speed and success | `pass_progress_rate = 0.01 + (GuardPass/100) × 0.04` (per second) |
| **Submission from Top** (0-100) | Sub attempt success from mount/side-control/north-south | `sub_attempt_speed = 0.5 + (SubFromTop/100) × 0.5` (seconds to lock) |

**Ground (Top) control map:**
```
┌────────────────────────────────────────────┐
│ GROUND — TOP POSITION CONTROLS            │
│                                            │
│ Left Stick: Posture (up/down)              │
│   LS Up   → Postured up (powerful GNP)     │
│   LS Down → Smother (tire opponent)        │
│                                            │
│ Right Stick: Transition direction          │
│   RS Up    → Mount attempt                 │
│   RS Down  → Knee-on-belly / back step     │
│   RS Left  → Side control advance          │
│   RS Right → North-south / crucifix        │
│                                            │
│ Face Buttons:                              │
│   A          → Right hand GNP (straight)   │
│   B          → Left hand GNP (hook)        │
│   X          → Submission attempt           │
│   Y          → Posture up (stand base)      │
│                                            │
│ LT(L2) Modifier:                           │
│   LT + A     → Hammer fist                 │
│   LT + B     → Elbow (if postured)         │
│   LT + X     → Transition fake             │
│                                            │
│ Denial:                                    │
│   RS Direction + RT(R2) → Deny opponent    │
│     transition (must match direction)      │
│                                            │
│ Ground-and-pound flow:                     │
│   A → B → A → B                           │
│   (Alternating hands, faster combos)       │
│   LT + A → B (heavy combo, more stamina)   │
└────────────────────────────────────────────┘
```

**Ground (Top) — Position transitions:**

```
Full Guard ──→ Half Guard ──→ Side Control ──→ Mount ──→ Back Mount
  │               │               │              │          │
  │               │               │              │          │
  └→ Scramble ────┴→ Scramble ────┴→ Scramble ───┴──→ Scramble
                     │                           
                     └→ Knee-on-Belly ──→ Back
```

Transition requirements:
```
Pass Guard (top):  GuardPass skill vs GuardRetention skill
  3 seconds at 50 GuardPass vs 50 GuardRetention
  Winner declared when progress bar fills
  
  GuardPass 80 vs GuardRetention 40  →  2.2 seconds
  GuardPass 40 vs GuardRetention 80  →  progress stalls, can't pass
  
Mount → Back Mount: TopControl skill vs BottomControl skill
  Progress rate: 0.015 × (TopControl - BottomControl + 50) / 50
  Minimum threshold: TopControl must be > BottomControl - 20
```

### 3.5 Ground — Bottom (reversal position)

| Skill | What It Governs | Math Application |
|-------|----------------|------------------|
| **Bottom Control** (0-100) | Sweep chance, escape timing, submission defense from guard | `sweep_chance = (BottomControl/100) × (AGI/100)` — wait, AGI was removed. Let me use: `sweep_chance = (BottomControl/100) × (SPD/100) × 0.5` |
| **Guard Retention** (0-100) | Retaining guard, butterfly/half guard recovery, preventing pass | `retention_strength = (GuardRetention/100) × (TGH/100) × 0.5` |
| **Submission from Bottom** (0-100) | Triangle, armbar, omoplata from guard | `sub_lock_chance = (SubFromBottom/100) × 0.3` (per attempt from guard) |

**Ground (Bottom) control map:**
```
┌────────────────────────────────────────────┐
│ GROUND — BOTTOM POSITION CONTROLS         │
│                                            │
│ Left Stick: Hip movement (shift base)      │
│   LS Direction  → Shift hips (creates      │
│                    opening for sweeps)      │
│                                            │
│ Right Stick: Transition direction          │
│   RS Up    → Stand-up attempt (getup)      │
│   RS Down  → Pull guard / butterfly        │
│   RS Left  → Sweep direction A             │
│   RS Right → Sweep direction B             │
│                                            │
│ Face Buttons:                              │
│   A          → Sweep attempt               │
│   B          → Submission attempt (TI,      │
│                 armbar, omoplata)           │
│   X          → Wrist control / frame        │
│   Y          → Stand-up / getup attempt     │
│                                            │
│ LT(L2) Modifier:                           │
│   LT + A     → Scramble / push off         │
│   LT + B     → Kimura sweep attempt        │
│   LT + X     → Arm drag to back            │
│   LT + Y     → Wall walk (if near cage)    │
│                                            │
│ Denial:                                    │
│   RS Direction + RT(R2) → Deny opponent's  │
│     GNP / transition / pass attempt        │
│                                            │
│ Getup timing:                              │
│   Tap Y twice → Quick getup (vulnerable)   │
│   Hold Y      → Technical getup (safer)    │
│   Y → RS Up   → Push off → stand up        │
└────────────────────────────────────────────┘
```

**Ground (Bottom) — defensive sweep paths:**

```
Full Guard (bottom) ──→ Reversal to Top Guard
            ├──→ Butterfly → Single leg (stand up)
            ├──→ X-guard → Sweep to top
            ├──→ Rubber guard → Triangle attempt
            └──→ Half guard → Deep half → Sweep

Half Guard (bottom) ──→ Reversal to Top Half Guard
            ├──→ Underhook → Dogfight → Takedown
            ├──→ Deep half → Sweep to top half
            ├──→ Lockdown → Electric chair sweep
            └──→ Butterfly half → Stand up
```

### 3.6 Submissions (universal)

| Skill | What It Governs | Math Application |
|-------|----------------|------------------|
| **Sub Offense** (0-100) | Finishing speed from locked position, chain submission speed | `finish_speed = 0.5 + (SubOff/100) × 0.5` (seconds to fill sub bar) |
| **Sub Defense** (0-100) | Escape speed when caught, survival time, reactivity | `escape_speed = 0.3 + (SubDef/100) × 0.7` (seconds to drain opponent's sub bar) |
| **Sub Awareness** (0-100) | Pre-sub avoidance, detecting setups, positional safety | `early_detect_chance = SubAwareness / 100` |

**Submission control map:**
```
When locked in a submission attempt:
  Defending:
    RS Rotate (clock or counter)  → Escape direction (prompt shown)
    Tap A rapidly                 → Burst escape (uses more stamina)
    LT (hold)                     → Grimace / tough it out (slow bar drain)
    
  Attacking:
    RS Rotate (match direction)   → Advance sub
    Tap A rapidly                 → Burst finish attempt
    LT (hold) + direction         → Chain to different sub

  Submission Bar:
    0% ──────────────────────────100%
    [← Defending         Attacking →]
    Bar moves toward attacker when they input correctly
    Bar moves toward defender when they deny
    Bar hits 100% → TAP OUT (defender loses)
    
  Chain submissions (attacker):
    If attacker has high SubOff and defending fighter has low SubAwareness:
    Armbar → fails → Transition to Triangle → fails → Transition to Omoplata
    Each chain has a window cost (stamina); chain cost = 15 stamina per link
```

---

## 4. Health Profile (7 durability attributes)

Persistent health data that changes during a fight AND carries between fights for career mode. All values are 0-100 with higher = better.

| # | Attribute | What It Governs | Math |
|---|-----------|----------------|------|
| 1 | **Chin/KO Resistance** (0-100) | How much head trauma before KO/daze/stun | `ko_damage_required = ko_threshold_base × (1 + Chin/200)` |
| 2 | **Cut Resistance** (0-100) | Probability of laceration per sharp impact | `cut_chance = weapon_cut_chance × (100 - CutResist)/100` |
| 3 | **Swelling Resistance** (0-100) | Swelling severity per blunt face hit | `swell_amount = blunt_damage × (100 - SwellResist)/100` |
| 4 | **Bleeding Resistance** (0-100) | Blood flow rate from cuts (affects vision loss) | `bleed_rate = 1.0 - (BleedResist/100) × 0.8` (0.2-1.0 droplets/sec) |
| 5 | **Limb Health per arm** (0-100) | Arm damage capacity; below 50% HP → strike power halved | `arm_hp = limb_hp_base × (1 + LimbHealth/200)` |
| 6 | **Limb Health per leg** (0-100) | Leg damage capacity; below 50% → mobility ×0.4, kick power ×0.3 | `leg_hp = limb_hp_base × (1.2 + LimbHealth/200)` |
| 7 | **Injury Recovery** (0-100) | Healing speed between fights in career mode | `heal_per_day = base_heal × (1 + InjuryRecov/100)` |

**Per-zone HP pools and thresholds:**

| Zone | Base HP | HP Derivation | KO Threshold | Notes |
|------|---------|---------------|--------------|-------|
| Head | 100 + (Chin × 0.5) | Max 150 | Damage > Chin-derived threshold → stun check | Swelling accumulates up to 50, each 10 = -10% vision |
| Torso | 100 + (TGH × 1.0) | Max 200 | HP < 30% → stamina recovery halved | Body damage = stamina drain multiplier |
| L Arm | (50 + TGH×0.8) × (1 + LimbHealth/200) | 50-195 | HP < 50% → punch power ×0.5, can't extend fully | Arm damage reduces reach by 50% below 30% |
| R Arm | Same formula | Same | Same | Dominant hand (orthodox/southpaw matters) |
| L Leg | (50 + TGH×0.8) × (1.2 + LimbHealth/200) | 60-234 | HP < 50% → move speed ×0.4, kick power ×0.3 | Leads to compromised stance |
| R Leg | Same formula | Same | Same | Rear leg check can shin break |

**Damage types and effects:**

| Type | Sources | Effect | Heals Between Rounds |
|------|---------|--------|---------------------|
| Blunt | Punch, kick, knee, GNP | Reduces zone HP, causes swelling, chances of stun/KO | 20% of missing HP |
| Sharp | Elbow, split punch, cage scrape | Causes cuts, open wounds, bleeding | 0% (requires doctor) |
| Submission | Joint locks, chokes | Does NOT reduce HP — fills submission bar | Resets between rounds |
| Accumulated | Body of punishment over full fight | Hidden "fight fatigue" stat — raises stun chance | Resets between fights |

---

## 5. Stamina Profile (5 energy attributes)

Values 0-100, with 100 being ideal.

| # | Attribute | Effect | Range at 0 | Range at 100 |
|---|-----------|--------|------------|--------------|
| 1 | **Max Stamina** | Total energy pool | 100 | 150 |
| 2 | **Drain Rate** | Multiplier on every action stamina cost | ×1.5 | ×0.6 |
| 3 | **Recovery Rate** | Passive stamina regen (per second in neutral) | 1/sec | 10/sec |
| 4 | **Gassed Threshold** | % of max stamina where penalties kick in | 35% | 10% |
| 5 | **Cardio Drop-off** | Which round stamina drain starts accelerating | Round 2 | Round 5 |

**Stamina cost table (base values, modified by Drain Rate):**

| Action | Base Stamina Cost | Notes |
|--------|------------------|-------|
| Jab | 2 | Lowest cost strike |
| Cross | 3.5 | Power punch |
| Hook | 4 | Wide, high commitment |
| Uppercut | 4 | Close range, high power |
| Front kick | 3 | Low commitment, range finder |
| Roundhouse | 5.5 | High power, slow recovery |
| Leg kick | 3.5 | Mid commitment, stacks damage |
| Head kick | 7 | High risk/reward, slowest recovery |
| Knee (clinch) | 3 | Short, damaging, close range |
| Elbow (clinch) | 3.5 | Cut chance, close range |
| Takedown shot | 8 | Highest stamina cost action |
| Sprawl | 4 | Reactive, moderate cost |
| Clinch entry | 4 | Depends on distance |
| Clinch pummel | 2 | Per pummel attempt |
| Guard pass attempt | 6 | Per progress cycle |
| Sweep attempt | 5 | Bottom position escape |
| Sub attempt (locked) | 3/sec | Per second of submission |
| Sub defense (locked) | 2/sec | Per second of defense |
| Ground strike | 2 | Single GNP strike |
| Block (per strike) | 1.5 | Stamina damage through block |
| Head movement | 1 | Per slip/duck |
| Lunge | 2.5 | Explosive forward movement |

**Stamina state penalties:**

```
Stamina > Gassed Threshold:  Normal operation

Stamina < Gassed Threshold (GASSED):  
  - All strike damage: ×0.7
  - All strike speed: ×0.75 (slower animations)
  - Movement speed: ×0.65
  - Block strength: ×0.5 (more stamina damage through block)
  - Takedown power: ×0.5
  - Takedown/sprawl speed: ×0.6
  - Submission effectiveness: ×0.5
  - Reaction window for denials: ÷1.5
  - Stamina COST of all actions: ×1.3 (death spiral)
  - Recovery rate when gassed: ×0.0 (cannot recover below threshold)
  
Between rounds:
  - Recovery rate per round
  - Base: 30% of max stamina restored (modified by Injury Recovery)
  - If fighter ended round gassed: only 20% restored
  - If fighter ended round rocked/stunned: only 15% restored
```

---

## 6. Fighting Styles (12 styles)

Styles are NOT skills. They are modifier collections applied at FighterData build time. They push a fighter toward a specific gameplan. Style also references animation sets (`StyleData.tres` resource).

Style modifiers are applied ONCE when the fighter is created (in `build_stats()`), permanently adjusting skill values. The base skill values stored in the fighter's data record are their "raw talent" — style pushes their effective ratings up in some areas, down in others.

### Style Modifier Table

| Style | +Bonus Skills | -Penalty Skills | Archetype |
|-------|--------------|----------------|-----------|
| **Boxing** | Boxing +12, Head Movement +8, Footwork +5 | Kickboxing -8, ClinchOff -5, ClinchDef -3, SubOff -5 | Stand-up boxer, weak on ground |
| **Muay Thai** | MuayThai +12, ClinchOff +10, ClinchDef +5 | Footwork -5, TDDef -8, SubDef -5 | Clinch striker, vulnerable to TDs |
| **Wrestling** | TDOff +15, TDDef +15, TopControl +12, CageWrestling +10 | Kickboxing -8, SubOff -8, SubAware -5 | Smothering top game, minimal subs |
| **BJJ** | SubOff +15, SubDef +12, GuardRetention +10, BottomControl +10 | Boxing -10, TDOff -10, Kickboxing -8 | Dangerous guard, weak stand-up |
| **Kickboxing** | Kickboxing +15, Footwork +10, MuayThai +5 | ClinchOff -8, TDDef -8, ClinchDef -5 | Long range striker, vulnerable in clinch |
| **Sambo** | TDOff +8, TDDef +8, SubOff +8, ClinchTD +8, CounterTD +8 | Boxing -3, Kickboxing -3 | Balanced grappler, slight striking weakness |
| **Judo** | ClinchTD +15, ClinchOff +12, TopControl +8, SubOff +5 | Kickboxing -8, HeadMovement -5, Boxing -3 | Throw-heavy grappler, linear striking |
| **Karate** | Kickboxing +12, Footwork +15, HeadMovement +8 | ClinchOff -10, SubDef -5, TDDef -5 | Movement-based striker, weak in close |
| **Taekwondo** | Kickboxing +15 (kicks only), Footwork +10, SubAware +3 | Boxing -10, ClinchOff -10, TDDef -10 | Specialized kicker, poor TDD |
| **Catch Wrestling** | TDDef +12, TopControl +10, SubOff +10, SubDef +5 | Boxing -5, Kickboxing -5 | Submission grappler with striking base |
| **Hapkido** | CounterTD +12, ClinchDef +10, SubAware +10 | Boxing -8, TopControl -5, TDOff -5 | Defensive specialist, counter-fighter |
| **Generic MMA** | +2 to all combat skills (360 total bonus distributed evenly) | None | Jack of all trades, master of none |

**How style modifiers apply:**
```gdscript
# Example: Wrestling style applied to a base fighter
var fighter = FighterData.new()
fighter.boxing = 55       # raw talent
fighter.TDOff = 50        # raw talent

# After build_stats() applies Wrestling style:
fighter.boxing == 55       # boxing not in Wrestling's bonus/penalty
fighter.TDOff == 65        # 50 + 15
fighter.kickboxing == 42   # 50 - 8 (penalty)
```

---

## 7. FighterData Godot Resource Definition

Full schema for `res://data/fighter/FighterData.gd`:

```gdscript
# res://data/fighter/FighterData.gd
extends RefCounted  # No class_name — use preload()

# ─────────────────────────────────────
# 1. IDENTITY
# ─────────────────────────────────────
var fighter_name: String = "Unnamed"
var nickname: String = ""
var weight_class: int = 0
var nationality: String = "USA"
var age: int = 25
var reach_inches: float = 72.0
var height_ft: int = 5
var height_in: int = 10
var record: Dictionary = {
    "wins": 0, "losses": 0, "draws": 0,
    "kos": 0, "subs": 0, "decisions": 0
}
var stance: int = 0  # enum: ORTHODOX=0, SOUTHPAW=1, SWITCH=2

# ─────────────────────────────────────
# 2. CORE STATS (0-100)
# ─────────────────────────────────────
var strength: float = 50.0
var speed: float = 50.0
var endurance: float = 50.0
var toughness: float = 50.0

# ─────────────────────────────────────
# 3. COMBAT SKILLS (0-100)
# ─────────────────────────────────────
var boxing: float = 50.0
var kickboxing: float = 50.0
var muay_thai: float = 50.0
var head_movement: float = 50.0
var footwork: float = 50.0
var clinch_offense: float = 50.0
var clinch_defense: float = 50.0
var clinch_takedown: float = 50.0
var td_offense: float = 50.0
var td_defense: float = 50.0
var counter_td: float = 50.0
var cage_wrestling: float = 50.0
var top_control: float = 50.0
var bottom_control: float = 50.0
var guard_pass: float = 50.0
var guard_retention: float = 50.0
var sub_offense: float = 50.0
var sub_defense: float = 50.0
var sub_awareness: float = 50.0

# ─────────────────────────────────────
# 4. HEALTH PROFILE (0-100)
# ─────────────────────────────────────
var chin: float = 50.0
var cut_resistance: float = 50.0
var swell_resistance: float = 50.0
var bleed_resistance: float = 50.0
var limb_health: float = 50.0
var injury_recovery: float = 50.0

# ─────────────────────────────────────
# 5. STAMINA PROFILE (0-100, used to derive actual values)
# ─────────────────────────────────────
var max_stamina_rating: float = 50.0
var drain_rate_rating: float = 50.0      # Inverted: higher = lower drain
var recovery_rate_rating: float = 50.0
var gassed_threshold_rating: float = 50.0  # Inverted: higher = lower threshold
var cardio_drop_rating: float = 50.0

# ─────────────────────────────────────
# 6. STYLE
# ─────────────────────────────────────
var primary_style: String = "generic_mma"

# ─────────────────────────────────────
# 7. DERIVED VALUES (computed once)
# ─────────────────────────────────────
var derived: Dictionary = {}
var health_pools: Dictionary = {}
var stamina_state: Dictionary = {}

# ─────────────────────────────────────
# METHODS
# ─────────────────────────────────────

func _init() -> void:
    build_stats()

func build_stats() -> void:
    _apply_style_modifiers()
    _compute_derived()
    reset_health()
    reset_stamina()

# ── Core stat access ──
func get_skill(name: String) -> float:
    return get(name) if name in self else 50.0

# ── Health pool access ──
func get_health(zone: String) -> float:
    return health_pools.get(zone, 100.0)

func apply_damage(zone: String, amount: float) -> void:
    if health_pools.has(zone):
        health_pools[zone] = max(0.0, health_pools[zone] - amount)
        _apply_damage_effects(zone, amount)

func reset_health() -> void:
    var d = derived
    health_pools = {
        "head":    100.0 + (chin * 0.5),
        "torso":   100.0 + (toughness * 1.0),
        "left_arm":   d.limb_hp,
        "right_arm":  d.limb_hp,
        "left_leg":   d.limb_hp_leg,
        "right_leg":  d.limb_hp_leg,
    }

func reset_stamina() -> void:
    stamina_state = {
        "current": derived.max_stamina,
        "is_gassed": false,
    }

# ── Derived value accessors ──
func get_d(key: String, default = 0.0):
    return derived.get(key, default)

# ─────────────────────────────────────
# INTERNAL — Build derived values from stats
# ─────────────────────────────────────

func _compute_derived() -> void:
    derived = {
        # ── STRENGTH ──
        "punch_base_dmg":     5.0 + (strength * 0.12),
        "kick_base_dmg":      8.0 + (strength * 0.10),
        "takedown_power":     0.4 + (strength * 0.006),
        "clinch_push":        0.3 + (strength * 0.005),
        "gnp_damage_mult":    0.5 + (strength * 0.005),

        # ── SPEED ──
        "strike_speed_mult":  1.8 - (speed * 0.012),
        "move_speed_mult":    0.6 + (speed * 0.009),
        "reaction_frames":    15.0 - (speed * 0.14),
        "combo_window":       0.3 + (speed * 0.005),
        "accuracy_bonus":     0.8 + (speed * 0.002),

        # ── ENDURANCE ──
        "max_stamina":        100.0 + (endurance * 0.5),
        "stamina_drain":      1.6 - (endurance * 0.011),
        "stamina_recovery":   1.0 + (endurance * 0.09),
        "gassed_pct":         0.35 - (endurance * 0.0025),
        "cardio_drop_round":  5 - int(endurance * 0.04),

        # ── TOUGHNESS ──
        "dmg_taken_mult":     1.5 - (toughness * 0.01),
        "ko_threshold":       30.0 + (toughness * 0.7),
        "limb_hp":            50.0 + (toughness * 0.8),
        "limb_hp_leg":        (50.0 + (toughness * 0.8)) * 1.2,
        "torso_hp":           100.0 + (toughness * 1.0),
        "recovery_mult":      0.3 + (toughness * 0.005),

        # ── STAMINA RATINGS ──
        "stamina_pool_mult":  0.6 + (max_stamina_rating * 0.009),
        "drain_mult":         1.5 - (drain_rate_rating * 0.009),
        "recov_per_sec":      1.0 + (recovery_rate_rating * 0.09),
        "gassed_at_pct":      0.35 - (gassed_threshold_rating * 0.0025),
        "drop_round":         2 + int(cardio_drop_rating * 0.03),
    }

func _apply_damage_effects(zone: String, raw_damage: float) -> void:
    if zone == "head" and health_pools[zone] < derived.ko_threshold:
        pass  # Triggers stun check — handled by combat manager
    # Limb damage effects are checked on every action via get_limb_status()

func get_limb_status(limb: String) -> Dictionary:
    var hp = health_pools.get(limb, 100.0)
    var max_hp = _get_max_hp_for_limb(limb)
    var pct = hp / max_hp
    return {
        "effective": pct,
        "is_compromised": pct < 0.5,
        "is_destroyed": hp <= 0.0,
        "power_mult": 1.0 if pct >= 0.5 else (0.3 + pct * 0.4),
        "speed_mult": 1.0 if pct >= 0.3 else (0.4 + pct * 0.5),
    }

func _get_max_hp_for_limb(limb: String) -> float:
    match limb:
        "left_arm", "right_arm": return derived.limb_hp
        "left_leg", "right_leg": return derived.limb_hp_leg
        _: return 100.0

# ─────────────────────────────────────
# INTERNAL — Style application
# ─────────────────────────────────────

const _STYLE_MODIFIERS: Dictionary = {
    "boxing": {
        "bonus": {"boxing": 12, "head_movement": 8, "footwork": 5},
        "penalty": {"kickboxing": -8, "clinch_offense": -5, "clinch_defense": -3, "sub_offense": -5},
    },
    "muay_thai": {
        "bonus": {"muay_thai": 12, "clinch_offense": 10, "clinch_defense": 5},
        "penalty": {"footwork": -5, "td_defense": -8, "sub_defense": -5},
    },
    "wrestling": {
        "bonus": {"td_offense": 15, "td_defense": 15, "top_control": 12, "cage_wrestling": 10},
        "penalty": {"kickboxing": -8, "sub_offense": -8, "sub_awareness": -5},
    },
    "bjj": {
        "bonus": {"sub_offense": 15, "sub_defense": 12, "guard_retention": 10, "bottom_control": 10},
        "penalty": {"boxing": -10, "td_offense": -10, "kickboxing": -8},
    },
    "kickboxing": {
        "bonus": {"kickboxing": 15, "footwork": 10, "muay_thai": 5},
        "penalty": {"clinch_offense": -8, "td_defense": -8, "clinch_defense": -5},
    },
    "sambo": {
        "bonus": {"td_offense": 8, "td_defense": 8, "sub_offense": 8, "clinch_takedown": 8, "counter_td": 8},
        "penalty": {"boxing": -3, "kickboxing": -3},
    },
    "judo": {
        "bonus": {"clinch_takedown": 15, "clinch_offense": 12, "top_control": 8, "sub_offense": 5},
        "penalty": {"kickboxing": -8, "head_movement": -5, "boxing": -3},
    },
    "karate": {
        "bonus": {"kickboxing": 12, "footwork": 15, "head_movement": 8},
        "penalty": {"clinch_offense": -10, "sub_defense": -5, "td_defense": -5},
    },
    "taekwondo": {
        "bonus": {"kickboxing": 15, "footwork": 10, "sub_awareness": 3},
        "penalty": {"boxing": -10, "clinch_offense": -10, "td_defense": -10},
    },
    "catch_wrestling": {
        "bonus": {"td_defense": 12, "top_control": 10, "sub_offense": 10, "sub_defense": 5},
        "penalty": {"boxing": -5, "kickboxing": -5},
    },
    "hapkido": {
        "bonus": {"counter_td": 12, "clinch_defense": 10, "sub_awareness": 10},
        "penalty": {"boxing": -8, "top_control": -5, "td_offense": -5},
    },
    "generic_mma": {
        "bonus": {"boxing": 2, "kickboxing": 2, "muay_thai": 2, "head_movement": 2, "footwork": 2,
                  "clinch_offense": 2, "clinch_defense": 2, "clinch_takedown": 2,
                  "td_offense": 2, "td_defense": 2, "counter_td": 2, "cage_wrestling": 2,
                  "top_control": 2, "bottom_control": 2, "guard_pass": 2, "guard_retention": 2,
                  "sub_offense": 2, "sub_defense": 2, "sub_awareness": 2},
        "penalty": {},
    },
}

func _apply_style_modifiers() -> void:
    var mods = _STYLE_MODIFIERS.get(primary_style, {})
    for skill_name in mods.get("bonus", {}):
        var v = get(skill_name) if skill_name in self else 50.0
        set(skill_name, clampf(v + mods["bonus"][skill_name], 0.0, 100.0))
    for skill_name in mods.get("penalty", {}):
        var v = get(skill_name) if skill_name in self else 50.0
        set(skill_name, clampf(v + mods["penalty"][skill_name], 0.0, 100.0))
```

---

## 8. Weight Classes

| ID | Class | Min Weight | Max Weight | Reach Bonus |
|----|-------|-----------|-----------|-------------|
| 0 | Strawweight | 105 | 115 | +0" |
| 1 | Flyweight | 115 | 125 | +1" |
| 2 | Bantamweight | 125 | 135 | +2" |
| 3 | Featherweight | 135 | 145 | +3" |
| 4 | Lightweight | 145 | 155 | +4" |
| 5 | Welterweight | 155 | 170 | +4" |
| 6 | Middleweight | 170 | 185 | +3" |
| 7 | Light Heavyweight | 185 | 205 | +2" |
| 8 | Heavyweight | 205 | 265 | +0" |

Weight classes affect:
- Speed/Stamina: Lower classes get +5-10% to SPD and END
- Power: Higher classes get +5-10% to STR
- Reach: Mapped to a normalized baseline per class

---

## 9. Control State Machine (Top-Level View)

The control input changes meaning based on the current fight state. This is the high-level state machine that routes inputs:

```
            ┌──────────┐
            │ STAND-UP │ ← Default state, ranged striking
            └────┬─────┘
                 │
       LS+RT+A   │   Y (from ground) / A+B (stand)
         ┌───────┴────────┐
         ▼                ▼
    ┌────────┐      ┌──────────┐
    │ CLINCH │      │ GROUND   │
    └────┬───┘      │ (Top)    │
         │          └────┬─────┘
  TD (top)                  │
  Trip/Throw         ┌──────┴──────┐
         │           ▼             ▼
         │     ┌──────────┐ ┌───────────┐
         │     │ GROUND   │ │ GROUND    │
         │     │ (Top)    │ │ (Bottom)  │
         │     └────┬─────┘ └─────┬─────┘
         │          │             │
         │     Sub locked   Sub locked
         ▼          ▼             ▼
    ┌─────────┐ ┌─────────┐ ┌─────────┐
    │ GROUND  │ │ SUBMIS- │ │ SUBMIS- │
    │(Ground) │ │  SION   │ │  SION   │
    │ GNP     │ │ (Top)   │ │(Bottom) │
    └─────────┘ └─────────┘ └─────────┘

Transitions:
  STAND-UP → CLINCH:  LS toward + A (with RB held, in range)
  STAND-UP → GROUND:  Takedown lands (top) or Takedown defended (bottom)
  CLINCH → STAND-UP:  Clinch break / push off
  CLINCH → GROUND:    Takedown from clinch lands
  GROUND → STAND-UP:  Stand-up / getup completes
  GROUND → SUBMISSION: Sub attempt locks in
  SUBMISSION → GROUND: Sub escape / reversal
  GROUND (Top/Bottom): Sweep → reverses position
```

---

## 10. Example Fighter Data

### Heavyweight Power Puncher
```gdscript
{
    fighter_name="Ivan Drakov", weight_class=8, age=28, reach=78, height_ft=6, height_in=4
    stance=0,  # orthodox
    strength=92, speed=38, endurance=55, toughness=85,
    boxing=82, kickboxing=35, muay_thai=25, head_movement=38, footwork=35,
    clinch_offense=45, clinch_defense=50, clinch_takedown=15,
    td_offense=25, td_defense=60, counter_td=20, cage_wrestling=30,
    top_control=35, bottom_control=15, guard_pass=20, guard_retention=25,
    sub_offense=10, sub_defense=20, sub_awareness=15,
    chin=88, cut_resistance=65, swell_resistance=70, bleed_resistance=60,
    limb_health=75, injury_recovery=55,
    max_stamina_rating=45, drain_rate_rating=40, recovery_rate_rating=40,
    gassed_threshold_rating=35, cardio_drop_rating=30,
    primary_style="boxing",
}
```

### Lightweight Grappler
```gdscript
{
    fighter_name="Kenji Takeshi", weight_class=4, age=26, reach=70, height_ft=5, height_in=9
    stance=0,
    strength=60, speed=72, endurance=82, toughness=65,
    boxing=45, kickboxing=30, muay_thai=45, head_movement=50, footwork=55,
    clinch_offense=78, clinch_defense=72, clinch_takedown=85,
    td_offense=88, td_defense=68, counter_td=55, cage_wrestling=65,
    top_control=82, bottom_control=72, guard_pass=68, guard_retention=78,
    sub_offense=72, sub_defense=80, sub_awareness=68,
    chin=60, cut_resistance=50, swell_resistance=45, bleed_resistance=55,
    limb_health=65, injury_recovery=70,
    max_stamina_rating=85, drain_rate_rating=90, recovery_rate_rating=88,
    gassed_threshold_rating=85, cardio_drop_rating=90,
    primary_style="wrestling",
}
```

### Welterweight Striker
```gdscript
{
    fighter_name="Damien Cruz", weight_class=5, age=30, reach=74, height_ft=6, height_in=0
    stance=1,  # southpaw
    strength=68, speed=88, endurance=72, toughness=58,
    boxing=62, kickboxing=92, muay_thai=75, head_movement=68, footwork=92,
    clinch_offense=50, clinch_defense=58, clinch_takedown=35,
    td_offense=30, td_defense=62, counter_td=72, cage_wrestling=35,
    top_control=25, bottom_control=30, guard_pass=22, guard_retention=28,
    sub_offense=18, sub_defense=28, sub_awareness=32,
    chin=52, cut_resistance=55, swell_resistance=42, bleed_resistance=50,
    limb_health=48, injury_recovery=62,
    max_stamina_rating=75, drain_rate_rating=80, recovery_rate_rating=78,
    gassed_threshold_rating=72, cardio_drop_rating=75,
    primary_style="karate",
}
```

---

## 11. Cross-Genre Extraction Map

| Layer | MMA | Beat-em-up | Fighting Game | RPG |
|-------|-----|-----------|--------------|-----|
| Core Stats (4) | ✓ Full | ✓ STR/SPD/TGH only | ✓ Full (END = super meter) | ✓ Full |
| Striking Skills (5) | ✓ Full | Boxing = melee damage, Footwork = dodge | Boxing = normals, Kickboxing = specials | Boxing = weapon skill |
| Clinch (3) | ✓ Full | ❌ | Close range grapple | ❌ |
| Takedowns (4) | ✓ Full | ❌ | Throw input | ❌ |
| Ground (4) | ✓ Full | ❌ | Knockdown state | ❌ |
| Subs (3) | ✓ Full | ❌ | Command grab | ❌ |
| Health Profile | ✓ Full | TGH + HP pools | TGH + stun threshold | Full + body-part HP |
| Stamina | ✓ Full | Single stamina bar | Super meter | ❌ (use MP) |
| Styles | ✓ 12 styles | Boxing = class | Fighting style archetype | Class system |

---

## 12. Implementation Order

1. **FighterData.gd** — the complete RefCounted class (ready above)
2. **StyleData.gd** — Resources for animation set references per style
3. **FighterDataBuilder.gd** — static helper that creates fighters from config data
4. **6 Example fighters** — 2 per archetype (striker, grappler, balanced), in .tres format
5. **FighterStatsUI.gd** — radar chart + stat panel for testing
6. **ControlMap.gd** — autoload singleton that exposes the current control scheme per state
