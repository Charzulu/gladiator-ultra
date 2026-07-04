# EA UFC Systems Deep Research — GU Design Audit

> **Scope:** Full systems reference across EA SPORTS UFC 3/4/5/6, cross-referenced against Gladiator Ultra's current design docs (`docs/`), Godot codebase (`scripts/`), and Three.js prototype (`threejs/`).
> **Goal:** Identify gaps, flag incoherencies, and prioritize a unified roadmap.

---

## 1. Research Sources (Training Data)

| Title | Year | Key Contribution |
|-------|------|------------------|
| EA SPORTS UFC 3 | 2018 | Real Player Motion (RPM), Grounded grappling, gate submission system, stamina overhaul |
| EA SPORTS UFC 4 | 2020 | Pocket striking, clinch simplification, cage physics, health events, leg kick damage model |
| EA SPORTS UFC 5 | 2024 | Real Impact System, Severe Damage states, doctor stoppage, performance ratings, damage-over-time |
| EA SPORTS UFC 6 | 2026 | "Fight Your Fight" — evolved striking & motion systems, refined damage model |
| UFC Undisputed 3 (THQ) | 2012 | Reference: deeper ground game, submission grapple advantage, Pride mode |

---

## 2. System-by-System Audit

### 2.1 Striking / Stand-Up

| EA UFC Feature | GU Doc Coverage | GU Prototype Coverage | Gap? |
|----------------|----------------|----------------------|------|
| 4-button striking (A/B/X/Y) | ✅ ControlMap.gd, attack-frame-system.md | ✅ Prototype V3 (A=jab, B=cross, X=hook, Y=uppercut) | — |
| High/Low target modifiers | ✅ LB/RB system | ✅ LB modifier for power variants | — |
| Head movement (slip/duck/weave) | ✅ I-frame evades with startup | ✅ evade system (slip/duck 1f startup) | — |
| Parry (RS click) | ✅ Attack-frame-system.md Appendix B | ❌ Not in prototype | **MINOR** |
| Block stamina damage through guard | ✅ Guard degradation | ✅ zone[armX] absorbs, guardEff scales | — |
| Guard break (stamina depleted) | ✅ GuardBreak=true → ×0.7 | ✅ Same | — |
| Body damage → stamina drain | ✅ zoneFrac('body') in stam regen | ✅ stCap burn on body hits | — |
| Leg damage → movement penalty | ✅ zoneFrac('legs') × moveSpd | ✅ Same | — |
| Perfect striking (LT tap) | ✅ ×1.25 damage | ❌ Not in prototype | **MINOR** |
| **Per-limb AttackState** | ✅ Attack-frame-system.md (AttackState.gd) | ❌ V3 still uses single `this.phase` | **CRITICAL** |
| **Phase-based vulnerability** | ✅ Attack-frame-system.md (×1.3 windup, ×1.5 recovery) | ❌ V3 uses flat isCounter flag | **CRITICAL** |
| **Phase-aware blocking** | ✅ Attack-frame-system.md §5 | ❌ V3 block is always-on flag | **CRITICAL** |
| Switch stance (orthodox ↔ southpaw) | ❌ Not designed | ❌ Not implemented | **SHOULD HAVE** |
| Weave (circular head movement) | ❌ Not designed | ❌ Only slip/duck | **SHOULD HAVE** |
| Pull counter | ❌ Not designed | ❌ Not implemented | **NICE TO HAVE** |

### 2.2 FK Velocity — The Star System

| EA UFC Feature | GU Equivalent | Status |
|----------------|---------------|--------|
| Real Impact System (UFC 5) — velocity maps to damage | ✅ **FK strike-tip velocity** — arc-length integrated tip velocity → damage multiplier | **IMPLEMENTED IN V3** |
| Physical animation (RPM) — motion-captured body mechanics | ✅ **Two-bone analytic IK** — parametric bezier paths for each strike kind | **IMPLEMENTED IN V3** |
| Derived: stamina affects velocity organically | ✅ Tired fighter → longer frames → same arc, more time → lower tip velocity → less damage | **INHERENT** |
| Derived: leg damage affects kick velocity | ✅ `v *= 0.7 + 0.3*zoneFrac('legR')` | **INHERENT** |

**Verdict:** This is GU's strongest system and should become the canonical approach in both the Three.js prototype and the Godot port. It's more elegant than EA's approach because stamina effects on damage emerge from frame math rather than a separate multiplier table.

---

### 2.3 Clinch

| EA UFC Feature | GU Doc Coverage | GU Prototype Coverage | Gap? |
|----------------|----------------|----------------------|------|
| Clinch entry (LS→ + A + RB) | ✅ ControlMap.gd _poll_stand_up() | ❌ | **CRITICAL** |
| Clinch positions (over-under, single-collar, Thai, cage) | ✅ Character-attribute-system.md §3.2 | ❌ | **CRITICAL** |
| Clinch strikes (knee, elbow, body knee, foot stomp) | ✅ Move-data-and-combos.md §2.2 | ❌ | **CRITICAL** |
| Pummel for control advantage | ✅ ControlMap.gd _poll_clinch() | ❌ | **CRITICAL** |
| Cage push | ✅ ControlMap.gd _poll_clinch() | ✅ V3 fence absorption exists | **PARTIAL** |
| Clinch break (contested escape) | ✅ FighterStateMachine.gd _attempt_clinch_break() | ❌ | **CRITICAL** |
| Clinch takedown (trip, body lock, hip throw) | ✅ Move-data-and-combos.md §2.1 | ❌ | **CRITICAL** |
| Dirty boxing flurries | ✅ Move-data-and-combos.md C08 | ❌ | **SHOULD HAVE** |

**Verdict:** The clinch is fully designed in Godot scripts but absent from the prototype. Adding it to the Three.js prototype is a major scope item (new fight state, 5+ new moves, new IK poses, AI clinch logic).

---

### 2.4 Ground Game

| EA UFC Feature | GU Doc Coverage | GU Prototype Coverage | Gap? |
|----------------|----------------|----------------------|------|
| Ground positions (guard, half-guard, side, mount, back mount) | ✅ Character-attribute-system.md §3.4-3.5 | ❌ | **CRITICAL** |
| Ground position progression chain | ✅ Move-data-and-combos.md §3.1 | ❌ | **CRITICAL** |
| Ground-and-pound (GNP) | ✅ Move-data-and-combos.md §3.3 | ❌ | **CRITICAL** |
| Sweeps (bottom → reversal) | ✅ ControlMap.gd _poll_ground_bottom() | ❌ | **CRITICAL** |
| Getup / stand-up | ✅ ControlMap.gd _poll_ground_bottom() | ✅ V3 seated getup | **PARTIAL** |
| Posture (top) | ✅ ControlMap.gd _poll_ground_top() | ❌ | **CRITICAL** |
| Guard passing | ✅ Move-data-and-combos.md G01-G07 | ❌ | **CRITICAL** |
| Scramble | ✅ Move-data-and-combos.md | ❌ | **SHOULD HAVE** |
| Wall walk (cage-assisted getup) | ✅ Move-data-and-combos.md C05 | ✅ V3 seated near cage | **PARTIAL** |

**Verdict:** Like the clinch, the ground game is fully designed in Godot but would be a massive addition to the Three.js prototype. EA UFC spends roughly equal dev time on stand-up, clinch, and ground — GU should eventually match this ratio but it's appropriate for the prototype to be stand-up-only.

---

### 2.5 Submissions

| EA UFC Feature | GU Doc Coverage | GU Prototype Coverage | Gap? |
|----------------|----------------|----------------------|------|
| Submission bar (attacker fills → win, defender fills → escape) | ✅ Character-attribute-system.md §3.6 | ❌ | **CRITICAL** |
| Chain submissions (transition between subs) | ✅ FightStateMachine.gd §submission | ❌ | **SHOULD HAVE** |
| Submission types (RNC, armbar, triangle, kimura, guillotine, etc.) | ✅ Move-data-and-combos.md §4 | ❌ | **SHOULD HAVE** |
| Tap out animation | ✅ ControlMap.gd _poll_submission() | ❌ | **SHOULD HAVE** |
| Post-submission victory state | ✅ match.finish() exists | ❌ No sub finish path | **SHOULD HAVE** |

---

### 2.6 Damage & Health

| EA UFC Feature | GU Doc Coverage | GU Prototype Coverage | Gap? |
|----------------|----------------|----------------------|------|
| Per-zone HP pools | ✅ FighterData.gd, Sim.zoneMax | ✅ 6 zones (head, body, armL/R, legL/R) | — |
| Permanent damage caps (hpCap burn) | ✅ FighterData.gd hpCap | ✅ hpCap = max(25%, cap - mit×0.35) | — |
| Stamina cap burn (stCap) | ✅ Character-attribute-system.md | ✅ stCap = max(35%, cap - stam×0.16) | — |
| Vulnerability window (recent damage amplifies) | ✅ vuln timer = 12s | ✅ vuln[zone] = 12s | — |
| **Cut system** | ✅ ImpactCalculator.gd §10, stun-system.md | ❌ Only blood particles, no cut mechanic | **SHOULD HAVE** |
| **Swelling / vision impairment** | ✅ Character-attribute-system.md §4 | ❌ | **SHOULD HAVE** |
| **Doctor stoppage** | ❌ Not designed | ❌ | **NICE TO HAVE** |
| **Performance rating (post-fight grade)** | ❌ Not designed | ❌ | **NICE TO HAVE** |

**Verdict:** GU's damage model is actually more granular than EA UFC's in some ways (individual LA/RA/LL/RL tracking, vulnerability windows). The missing cut/swelling/doctor systems are significant for simulation depth but not for the stand-up prototype.

---

### 2.7 Match & Rules

| EA UFC Feature | GU Doc Coverage | GU Prototype Coverage | Gap? |
|----------------|----------------|----------------------|------|
| 3 or 5 round fights | ✅ MatchManager, match.ROUNDS | ✅ 3 rounds × 99s | — |
| 10-9 scoring system | ✅ threejs/concept.md | ✅ Simple damage comparison | — |
| **10-8 / 10-7 rounds** | ❌ Not designed | ❌ All rounds are 10-9 | **MINOR** |
| **Judges' decision (unanimous/split/majority)** | ❌ Not designed | ❌ Simple winner determination | **SHOULD HAVE** |
| **Draw** | ❌ Not designed | ✅ match.decision() can return null | **MINOR** |
| **Deductions (point deduction for fouls)** | ❌ Not designed | ❌ | **NICE TO HAVE** |
| Referee intervention / stand-up | ❌ Not designed | ❌ | **NICE TO HAVE** |
| **Fight camp / preparation** | ❌ Not designed | ❌ | **NICE TO HAVE** |
| **Weigh-in / weight class mismatch** | ❌ Not designed | ❌ | **NICE TO HAVE** |

---

### 2.8 Fighter Attributes

| EA UFC Feature | GU Doc Coverage | GU Prototype Coverage | Gap? |
|----------------|----------------|----------------------|------|
| 4 core stats (STR/SPD/END/TGH) | ✅ FighterData.gd, character-attribute-system.md | ✅ Sim constructor uses all 4 | — |
| 18 combat skills | ✅ Character-attribute-system.md §3 | ❌ Only boxing, kickboxing, headMovement, footwork | **SHOULD HAVE** |
| Style modifiers (bonus/penalty to skills) | ✅ StyleData.gd, FighterData.gd _apply_style_modifiers() | ✅ SKILL_TEMPLATES per style | — |
| **Reach as independent stat** | ✅ reach_inches exists in FighterData | ❌ Height-derived only (reachMult) | **SHOULD HAVE** |
| **Weight class affects speed vs power** | ❌ Weight classes exist but have no gameplay effect | ❌ Same | **SHOULD HAVE** |
| Chin / KO resistance | ✅ FighterData.gd chin | ✅ effChin() = chin × (0.35 + 0.65×zoneFrac('head')) | — |
| **Fighter height / weight visible in game** | ✅ Displayed in HUD | ✅ wc + rec in HUD | — |

---

### 2.9 AI

| EA UFC Feature | GU Doc Coverage | GU Prototype Coverage | Gap? |
|----------------|----------------|----------------------|------|
| Style-specific behavior | ✅ AI profiles in prototype | ✅ STYLE_AI with range, aggr, weighted menus | — |
| Startup-reactive defense | ✅ In prototype aiThink() | ✅ AI reads foe.phase==='startup' → schedules react | — |
| **Range management + cage awareness** | ❌ Not in design doc | ✅ V3: circle off fence, swarm caged opponent | **PROTOTYPE-ONLY** |
| **Fight IQ — adapts to opponent patterns** | ❌ Not designed | ❌ | **SHOULD HAVE** |
| **AI aggression based on score / round** | ❌ Not designed | ❌ | **SHOULD HAVE** |
| **AI stamina management** | ✅ In prototype (gassed → defensive) | ✅ Survive mode: back up, block | — |
| Weighted strike selection by range | ✅ STYLE_AI menu with reach filter | ✅ opts.filter(reach ≥ range-0.15) | — |

---

### 2.10 Presentation & Feel

| EA UFC Feature | GU Doc Coverage | GU Prototype Coverage | Gap? |
|----------------|----------------|----------------------|------|
| Hitstop on contact | ✅ Stun-system.md §7 | ✅ hitstop = max(hitstop, blocked? ...) | — |
| Camera shake | ✅ Stun-system.md §7 | ✅ shake += dmg×0.008 | — |
| Camera punch-in | ❌ Not in design doc | ✅ V3: camPunch += mit×0.016 | **PROTOTYPE-ONLY** |
| Impact callouts | ✅ #callout system | ✅ "COUNTER!", "KNOCKDOWN!", "GUARD BREAK!" | — |
| **Health event slowdown** | ❌ Not designed | ✅ V3 whoosh sound on startup→active, hitstop tiers | **PARTIAL** |
| **Between-round corner** | ✅ threejs/concept.md §match flow | ✅ 5s rest + health/stam recovery | — |
| **Round scorecards** | ❌ Not in prototype | ❌ | **SHOULD HAVE** |
| **Fighter entrance / walkout** | ❌ Not designed | ❌ | **NICE TO HAVE** |
| **Referee in the cage** | ❌ Not designed | ❌ | **NICE TO HAVE** |

---

## 3. Cohesion Audit — Do Existing Systems Work Together?

### 3.1 Positive Cohesion

| System Pair | How They Interact | Cohesion |
|-------------|-------------------|----------|
| FK Velocity + Stamina | Fatigue → longer startup frames → lower tip velocity → less damage | ✅ **Elegant** |
| Per-zone pools + Permanent caps | Damaged arms reduce guard % permanently, body work shrinks stamina cap | ✅ **Biologically consistent** |
| Balance + Whiff Punishment | Missed kicks drain balance heavily → stumble state → vulnerable | ✅ **Emergent comedy** |
| Cage + Knockback | Fence absorbs knockback (×0.25) but rattles fighter | ✅ **Tactically meaningful** |
| AI Reaction + Startup Frames | AI reads startup → schedules block/evade based on SPD reaction stat | ✅ **Creates the frame game** |

### 3.2 Negative Cohesion / Conflicts

| Conflict | Details | Fix |
|----------|---------|-----|
| **Single phase vs per-limb design doc** | Prototype uses `this.phase` (per fighter). Design doc says AttackState tracks 4 limbs independently. They cannot both be correct for the same system. | Choose per-limb (design doc is correct) |
| **isCounter flag vs phase detection** | Prototype sets `isCounter = def.phase==='startup'` (reads single phase). Design doc says counter = def.phase==='windup||recovery' (per limb). | Align with per-limb phase detection |
| **VF2_SCALE = 1.5 global vs style-specific frame speed** | Prototype applies VF2_SCALE to ALL moves equally. Design doc says frame speed varies by style (boxing = 0.85×, wrestling = 1.0×). | Move VF2_SCALE into style modifiers |
| **Block is always-on vs phase-aware** | Prototype block is unconditional. Design doc says recovery phase = cannot block. | Match design doc |

### 3.3 Orphaned Systems (Designed but Not Implemented)

| System | Where | Priority |
|--------|-------|----------|
| MoveData resource (single source of truth) | attack-frame-system-and-controller.md | **HIGH — V4 Prompt #4** |
| AttackState per-limb FSM | attack-frame-system-and-controller.md | **HIGH — V4 Prompt #1** |
| Phase vulnerability modifiers | attack-frame-system-and-controller.md | **HIGH — V4 Prompt #2** |
| Phase-aware blocking | attack-frame-system-and-controller.md | **HIGH — V4 Prompt #3** |
| Move variant system | move-variant-system.md | MEDIUM |
| XP/prestige progression | move-xp-proficiency-system.md | LOW (career mode) |
| 12 fighting styles (full set) | StyleData.gd, fighter-skeleton-hitbox-system.md | MEDIUM |
| Hit reaction animation layer | stun-system.md §7 | MEDIUM |

### 3.4 Orphaned Prototype Features (Not in Design Doc)

| Feature | Where | Should It Be Documented? |
|---------|-------|--------------------------|
| FK strike-tip velocity → damage | prototype.html | ✅ YES — replace flat velocity bonus |
| Sumotori balance economy | prototype.html | ✅ YES — add to stun-system.md |
| Seated knockdown (cage slump) | prototype.html | ✅ YES — add to stun-system.md |
| Cage knockback absorption | prototype.html | ✅ YES — add to move-data-and-combos.md |
| Burn indicators (permanent damage overlay) | prototype.html | ❌ UI detail, not system design |
| Watch mode / attract mode | prototype.html | ❌ Nice-to-have, not core |

---

## 4. Recommended Feature Priority

### Tier 1 — Must Have (Before Godot Port)

| # | Feature | Effort | Impact | Status |
|---|---------|--------|--------|--------|
| 1 | Per-limb AttackState | Large | Defines the combat feel | **In V4 Prompt** |
| 2 | Phase-based vulnerability | Medium | Changes damage math | **In V4 Prompt** |
| 3 | Phase-aware blocking | Small | Changes block strategy | **In V4 Prompt** |
| 4 | MoveData unification | Medium | Clean architecture | **In V4 Prompt** |
| 5 | Clinch state + 5 moves | Large | New fight dimension | Next major milestone |
| 6 | Full 12-style set | Medium | Roster variety | Before career mode |

### Tier 2 — Should Have (Before Career Mode)

| # | Feature | Effort | Why |
|---|---------|--------|-----|
| 7 | Takedown system | Large | Enables ground game entry |
| 8 | Ground game (positions + GNP) | Huge | Half the sport |
| 9 | Cut system + swelling | Medium | Changes fight outcome |
| 10 | Submission system | Huge | Fight finish variety |
| 11 | Switch stance | Small | Tactical depth |
| 12 | Parry as distinct mechanic | Small | Counter-play depth |

### Tier 3 — Nice to Have (Post-1.0)

| # | Feature | Why It's Lower |
|---|---------|----------------|
| 13 | Doctor stoppage | Requires cut system first |
| 14 | Performance ratings | Post-fight UI only |
| 15 | Move variant system | Career mode feature |
| 16 | XP/prestige progression | Career mode feature |
| 17 | Weave (circular head movement) | Adds marginal value over slip/duck |
| 18 | Pull counter | Niche technique |
| 19 | Referee / walkouts | Cosmetic |

---

## 5. Key Insight — The FK Velocity Pattern Should Be Standard

The prototype's FK strike-tip velocity system is **the most innovative thing GU does differently from EA UFC**. It deserves to be the canonical damage model for both the Three.js and Godot versions:

```
Current Godot code (ImpactCalculator.gd, lines 136-140):
  velocity_bonus = 1.0 + (velocity_magnitude * 0.05)  // flat multiplier
  clamp(0.8, 2.0)

Prototype code (resolveContact, step 5):
  tipV = strikeVelocity(att, move)  // REAL limb-tip velocity from FK math
  raw *= min(1.5, max(0.8, 0.72 + tipV * 0.032))
```

The Godot version should adopt the prototype's approach: compute the weapon tip's arc-length velocity from the IK trajectory, not a flat stat-derived bonus. This means the Godot version needs a `strikeVelocity()` mirror of the Three.js FK solver, which already has an equivalent in `StrikePlanner.gd`'s trajectory functions.

---

## 6. Design Doc Gaps

Create these docs:

| Doc | Content | Priority |
|-----|---------|----------|
| `docs/balance-system.md` | Sumotori balance: drain rates, stumble state, comic fall, recovery | HIGH (exists in prototype, not documented) |
| `docs/cage-interaction.md` | Fence physics: knockback absorption, cage pressure, seated knockdown, wall walk | HIGH (exists in prototype, not documented) |
| `docs/fk-velocity-model.md` | Move from flat velocity bonus to FK arc-length velocity | MEDIUM (replaces ImpactCalculator §4) |
| `docs/phase-combat-integration.md` | How AttackState, phase vulnerability, phase blocking all wire together | MEDIUM (currently split across 3 docs) |

---

## 7. Immediate Next Steps

```
1. Send V4 prompt to Fable 5 (4 architectural changes)
2. Document FK velocity + balance system in docs/
3. Update Godot ImpactCalculator.gd to use FK velocity
4. Update Godot FighterStateMachine.gd to use per-limb AttackState
5. Port Fable 5 improvements back into Godot:
   - Cage physics
   - Seated knockdown
   - Burn indicators
   - AI cage pressure
```

The V4 prompt targets the 4 critical architectural gaps. Once those land in the prototype, GU's stand-up game will be architecturally complete and ready for clinch/ground expansion.
