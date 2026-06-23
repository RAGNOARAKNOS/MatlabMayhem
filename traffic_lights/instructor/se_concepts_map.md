# Systems-Engineering Concepts Map

Which activity teaches which idea. Use this to reassure yourself (and the
student's school) that "playing with traffic lights" is really a tour of core
systems-engineering thinking.

| SE concept | Where it shows up | Artefact / proof |
|------------|-------------------|------------------|
| **Requirements before design** | Every "draw it / think first" activity (1.1, 2.1, 3.1) | The paper diagram drawn *before* any code |
| **State / transition / event** | Day 1 (1.1–1.3) | `SingleLight` chart |
| **Default / fail-safe initial state** | Day 1 talking point | Light powers up on RED, not GREEN |
| **Entry actions (what happens on entering a state)** | Day 1 (1.3) | `en: red=1; ...` labels |
| **Inputs vs internal state** | Day 2 (2.3) | `request` (input) vs `req` (latched memory) |
| **Guards / conditions** | Day 2 (2.2–2.3) | `[req && after(5,sec)]` |
| **Latching / debouncing** | Day 2 (2.1 Q3, 2.3) | `du: if request; req=true; end` |
| **Safety / minimum-time constraints** | Day 2 (2.1 Q2) | minimum green + all-red gap |
| **Flashing / oscillating output (a machine inside a state)** | Day 2 (2.4), Day 3 (3.4) | `PED_FLASH` / `NIGHT` toggle-on-counter |
| **Requirements differ per system type** | Day 2 (2.4 Q3) | Pelican flashing-amber→green vs junction red+amber |
| **Operating modes (normal / night / fault)** | Day 3 (3.4) | `NIGHT` mode in `Junction4Way` |
| **Mode changes only at safe points** | Day 3 (3.4) | NIGHT entered only when idle/clearing |
| **Concurrency / coordination** | Day 3 (3.1, 3.4) | NS & EW coordinated by one controller |
| **Mutual exclusion & interlocks** | Day 3 (3.1–3.2) | never two greens; all-red clearance |
| **Safety invariant** | Day 3 (3.2) | the stated never-two-greens rule |
| **Verification (evidence, not vibes)** | Day 3 (3.2–3.3) | `check_junction_safety` PASS/FAIL |
| **Failure injection / testing the test** | Day 3 (3.3) | deliberately breaking the junction |
| **Sensors / event-driven behaviour** | Day 3 (3.4) | demand inputs in `Junction4Way` |
| **Fairness / starvation** | Day 3 (3.4 discussion) | serving the other approach next |
| **Abstraction & decomposition** | Day 3 (3.4 discussion) | splitting a big machine into small ones |
| **State explosion & how to tame it** | Day 3 (3.4 discussion) | hierarchy + parallelism |
| **Model as data / introspection** | Day 3 (3.5) | `slx2script` regenerating the chart |
| **Modularity / reusable components** | Day 3 ext (M.2–M.3) | `TrafficLightUnit` linked 4× in `Junction4WayModular` |
| **Encapsulation / information hiding** | Day 3 ext (M.2) | unit knows lights, not junctions; controller the reverse |
| **Interfaces / contracts** | Day 3 ext (M.2, M.5) | `go` / `is_red` between unit and controller |
| **Separation of concerns** | Day 3 ext (M.3) | controller = policy, unit = light behaviour |
| **Maintainability (edit once, reuse everywhere)** | Day 3 ext (M.4) | one unit edit → all four arms change |
| **Test reuse via stable interfaces** | Day 3 ext (M.5) | same `check_junction_safety` passes both builds |
| **Breaking algebraic loops (unit delay)** | Day 3 ext (M.3 aside) | `d_ns`/`d_ew` on the `is_red` feedback |
| **Iterate: design → build → run → check** | Every day (1.4, 2.x, 3.x) | the working loop itself |

## The through-line (one sentence)

Real systems are too big to hold in your head, so you **state the rules that
must never break**, **decompose** the system into small machines, and
**verify** that the rules hold — and you can practise that entire discipline on
something as everyday as a set of traffic lights.
