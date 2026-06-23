# Instructor Guide — Traffic-Light Systems Engineering Week

A 3-day, hands-on introduction to **systems engineering through state machines**
for a secondary-school work-experience student, using MATLAB/Simulink Stateflow.
Complexity grows: one light → a push-button crossing → a safe junction → scaling.

This guide is for **you** (the supervisor): timings, expected answers, talking
points, and what to watch for. The student-facing worksheets are in
`../worksheets/`.

---

## Before they arrive (15 min setup)

- MATLAB with **Simulink** and **Stateflow** installed (R2018b+ recommended; the
  scripts use `after(n,sec)` temporal logic and dataset logging — see *Tech
  notes* at the bottom).
- Add the scripts folder to the path: in MATLAB, `cd` to
  `traffic_lights/scripts` (or `addpath` it).
- Sanity-check the toolchain yourself first:
  ```matlab
  create_single_light; run_demo('TrafficLight')
  create_pelican;       run_demo('Pelican')
  create_junction;      check_junction_safety('Junction')
  create_junction_4way; check_junction_safety('Junction4Way')
  ```
  All four should build, animate, and the two safety checks should print PASS.

> The student does **not** need to know MATLAB beforehand. They edit numbers and
> read mostly-English chart labels. Keep them in the *design → build → run →
> check* loop rather than teaching MATLAB syntax.

---

## Day 1 — One light (≈ 1.5 hrs)

**Aim:** the vocabulary of state machines (state, transition, trigger, default
state, entry action) via the safest possible system — one timed light.

| Activity | Time | What to look for |
|----------|------|------------------|
| 1.1 Draw it first | 20 min | Don't let them open MATLAB yet. The paper diagram is the deliverable. |
| 1.2 Build it | 30 min | They run `create_single_light; run_demo('TrafficLight')` and *watch the active state highlight move*. |
| 1.3 Observe & check | 15 min | They map chart lines back to their paper diagram. |
| 1.4 Make it yours | 15 min | One change, predict, run, compare. |

**Expected state table (UK):**

| State | red | amber | green |
|-------|:---:|:-----:|:-----:|
| RED | ● | | |
| RED+AMBER | ● | ● | |
| GREEN | | | ● |
| AMBER | | ● | |

**Talking points**
- A state machine is only ever in **one** state at a time (today).
- The "default state" is a real engineering decision: a light powers up on RED
  (fail-safe), never green.
- Entry actions are "what I switch on the moment I enter this state".

**Common stumbles:** forgetting RED+AMBER exists (it's UK-specific); expecting
the light to change "instantly" rather than after the timer.

---

## Day 2 — Pelican crossing (≈ 1.75 hrs)

**Aim:** reacting to an **input** safely — guards, latching, minimum-time
safety. This is the conceptual jump of the week: from a system that *runs* to a
system that *responds*.

| Activity | Time | What to look for |
|----------|------|------------------|
| 2.1 Safety thinking | 20 min | The discussion *is* the learning. Push "what if...?" |
| 2.2 Build & drive | 30 min | They double-click the **Press** Manual Switch mid-run to "press the button". |
| 2.3 Observe & check | 20 min | Press just after green → it *waits* (minimum green). Find the latch and the clear. |
| 2.4 Flashing amber | 20 min | Understand `PED_FLASH`: a lamp toggled on a counter is a tiny on/off machine inside one state. Change the rate. |
| 2.5 Extend | optional | A re-trigger lockout (no more than once per 30 s). |

**Expected answers to 2.1**
1. Pedestrian green ⇒ cars are RED; just before, cars went GREEN → AMBER → RED.
2. No minimum green / no all-red gap ⇒ a car already in the junction (or unable
   to stop) meets pedestrians. Minimum green stops the lights "flickering"; the
   all-red gap clears the box.
3. The press sets a **latched** flag `req=1` that stays set until serviced —
   so a momentary tap is remembered.
4. Reasonable answer: a second press while already servicing does nothing (it's
   already latched / already happening). Accept any *justified* choice.

**Talking points**
- Distinguish **input** (`request`, from the world) from **internal state**
  (`req`, what the machine remembers).
- A **guard** `[req && after(5,sec)]` = "only cross if someone asked *and*
  cars have had their fair minimum". Two conditions, one transition.
- Latching = decoupling *when the button is pressed* from *when it's safe to
  act*. Real systems almost always need this.
- **Flashing amber (2.4):** the headline UK feature. The key insight for the
  student is that a *flashing* output needs something that changes over time —
  here a counter (`blink`) toggling the lamp every few steps, i.e. an on/off
  machine living inside a single state. Also note a Pelican goes
  flashing-amber → green with **no** red+amber (unlike Day 1 / a junction):
  requirements come from the situation, not a universal "how lights work".

**Common stumbles:** expecting the crossing to react instantly (it shouldn't);
confusing `request` and `req`. Use those two names deliberately to teach the
input-vs-memory distinction.

---

## Day 3 — Junction & scaling (≈ 2.5 hrs)

**Aim:** coordinating **two** machines safely, *proving* a safety invariant,
and understanding how engineers manage systems too big to draw flat.

| Activity | Time | What to look for |
|----------|------|------------------|
| 3.1 Design phases (pair) | 25 min | A ring of phases with an all-red gap between every swap. |
| 3.2 Build & prove | 30 min | `check_junction_safety` prints **PASS**. |
| 3.3 Break it on purpose | 20 min | They induce a FAIL, read the time it failed, then fix it. ★ highlight of the week |
| 3.4 Smart junction, night mode & scale | 35 min | Toggle demand + `night_demand` switches; discuss fairness, extension, modes, hierarchy. |
| 3.5 Bonus: model = data | 15 min | `slx2script` regenerates their chart as code. |

**The invariant:** `ns_green` and `ew_green` are never on together. The flat
controller guarantees it by construction (only one approach gets green; all-red
between swaps).

**Activity 3.3 — make sure they actually see a FAIL.** The lesson lands when a
test they trust goes red. Suggested sabotage: in `create_junction.m` point
`NS_GO` straight at `EW_GO` (delete the amber/all-red chain), rebuild, re-check.
Then restore and confirm PASS.

**Night / fault mode (3.4).** The `night_demand` switch drops the whole junction
to flashing amber. Two teaching points: (1) it reuses the Day-2 flashing trick
in a bigger system, and (2) it only engages at a **safe point** (idle/clearing),
never mid-green — so flipping the switch during a green takes a moment to act,
which is *correct*. Because nothing is green in NIGHT, the invariant still holds
and `check_junction_safety('Junction4Way')` still PASSes — a new mode that can't
break the safety rule.

**Scaling discussion — the real systems-engineering payoff.** Steer them to:
- A flat diagram of every lamp combination *explodes* combinatorially (state
  explosion). Roughly: independent sub-systems multiply, not add.
- The fix is **decomposition**: small machines (each approach's lights) running
  **concurrently**, coordinated by one **controller** ("whose turn?"). That's
  hierarchy + parallelism — the same trick used in cars, aircraft, factories.
- The invariant lives in the **controller**, not scattered across the lamps.

**Common stumbles:** forgetting the all-red gap; assuming "I watched it, it's
fine" counts as verification (it doesn't — that's the whole point of 3.3);
in the 4-way, expecting demand to interrupt a phase mid-way (it doesn't — safety
beats responsiveness, a callback to Day 2).

---

## Day 3 Extension — Modularity & reuse (≈ 1.5 hrs, optional but high-value)

**Aim:** rebuild the 4-way from a **reusable component** and feel why modularity
matters. Worksheet: `day3_modular.md`. This is the strongest "real engineering"
payoff in the pack.

| Activity | Time | What to look for |
|----------|------|------------------|
| M.1 Spot the duplication | 15 min | They count the six-lamp pattern repeated per state in `create_junction_4way.m`. |
| M.2 Meet the component | 15 min | The `TrafficLightUnit` interface (`go` / `r,a,g,is_red`) and what it deliberately *doesn't* know. |
| M.3 Assemble & run | 20 min | `create_tl_lib; create_junction_modular; run_demo('Junction4WayModular')` — four arms, controller = policy only. |
| M.4 One edit, four lights | 20 min | Change the unit once, rebuild, all four arms change. ★ the payoff |
| M.5 Reuse the test | 10 min | `check_junction_safety('Junction4WayModular')` PASSes **unchanged**. |

**How it's built.** `create_tl_lib.m` puts one `TrafficLightUnit` chart in a
Simulink **library** (`tl_lib.slx`). `create_junction_modular.m` **links** it
four times (N/S/E/W) and adds a tiny `Controller` chart that only sequences
phases (`ns_go`/`ew_go`) and waits on each unit's `is_red` before swapping. The
light behaviour exists in exactly one place.

**Two teaching beats to land:**
- *Edit once, change everywhere (M.4):* one timing change in the unit updates all
  four arms — versus hunting through every state in the monolith.
- *Interfaces enable test reuse (M.5):* both models expose `ns_green`/`ew_green`,
  so the same checker proves both. Good interfaces are why you can reuse tools.

**Talking points:** encapsulation (unit knows lights, not junctions; controller
the reverse), separation of concerns, small interfaces, and "when is a reusable
component worth the up-front effort?" (answer: when it's used many times and/or
likely to change).

**Note (don't skip):** the `is_red` feedback from units to controller would form
an **algebraic loop**; a one-step **Unit Delay** (`d_ns`/`d_ew`) breaks it. If a
strong student asks "why the delay block?", that's the answer — feedback between
two state machines needs a step of delay.

---

## Wrap-up conversation (15 min, end of Day 3)

Ask them to explain, in their own words:
- the difference between a **state** and an **event**;
- why a system needs a **safety invariant** and how they *proved* one;
- why you can't just draw one giant diagram for a big system.

If they can answer those three, the week succeeded.

---

## Tech notes / troubleshooting

- **Verified on:** R2026a (MathWorks Home licence) — all four models build and
  simulate, both safety checks PASS, and the behavioural checks hold: pedestrian
  gets a green that never overlaps vehicle green and the **amber genuinely
  flashes** in `PED_FLASH`; both junction approaches are served with no
  two-green overlap; and the 4-way **night mode flashes amber with no greens**
  (invariant preserved). The **modular** junction also builds (one library unit
  linked 4×), simulates with all four arms, and the *same* `check_junction_safety`
  PASSes on it unchanged.
- **Benign warnings:** you may see "Unable to determine the default toolchain"
  (no C compiler configured) and "model name is shadowing" on rebuild. Neither
  stops simulation — the builders suppress the shadowing one and Stateflow runs
  without a C compiler here.
- **Visual lamps:** each model has live **Dashboard Lamp** indicators bound to
  the chart's lamp outputs (red/amber/green heads; a pedestrian head on the
  Pelican). They light up during simulation. `run_demo` opens both the model
  (to see the lamps) and the chart (to see the active state highlight) — run
  them side by side. Dashboard blocks are part of base Simulink (R2015a+); no
  extra toolbox needed.
- **Manual Switch:** double-click it during a run to toggle. The on/off
  *position* is what matters to the student; they just click until the lights
  respond (programmatically the `sw` parameter is counter-intuitive: `'0'`
  passes the lower input).
- **Release sensitivity:** `after(n,sec)` (absolute-time temporal logic) needs a
  defined sample time. The builders set `chart.ChartUpdate='DISCRETE'` and a
  fixed-step discrete solver via `configDiscrete`. If a timer seems ignored on
  an older release, check the chart's *Update method* is Discrete and the model
  solver is fixed-step discrete.
- **Manual Switch:** double-click toggles it; the change takes effect on the next
  time step (not instantly) — that's realistic, not a bug.
- **Logging:** models save outputs as a Dataset (`out.yout`); `run_demo` and
  `check_junction_safety` read signals by name from it.
- **Idempotent builders:** every `create_*.m` closes and rebuilds its model, so
  the student can re-run freely after edits.
- **Can't run MATLAB here:** these scripts were written to the repo's existing
  Stateflow-API pattern (`create_vm_states.m`, `slx2script.m`) but must be run in
  a real MATLAB install — there is no way to execute them in the planning/CI
  environment.
