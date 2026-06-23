# Traffic-Light Systems Engineering Pack

A 3-day, hands-on introduction to **systems engineering through state machines**,
built for a secondary-school work-experience student. It starts with a single
traffic light and grows, step by step, into a self-verifying, sensor-actuated
road junction — teaching the core ideas of systems engineering along the way.

Everything is built programmatically with the MATLAB **Stateflow** API, in the
same idiom as this repo's `create_vm_states.m` / `slx2script.m`, so the charts
are reproducible and the student can read how they're made. Each model also has
**live Dashboard Lamp indicators** (coloured lights) that light up during
simulation, so it looks and behaves like a real traffic light.

## What you need

MATLAB with **Simulink** and **Stateflow** (R2018b+ recommended). No prior
MATLAB experience needed from the student — they mostly edit numbers and read
plain-English chart labels.

```matlab
cd traffic_lights/scripts     % or addpath this folder
```

## The three days at a glance

| Day | System | New idea | Build & run |
|-----|--------|----------|-------------|
| **1** | One UK light, on a timer | states, transitions, triggers | `create_single_light; run_demo('TrafficLight')` |
| **2** | Pelican crossing with a button | inputs, guards, latching, minimum-time safety | `create_pelican; run_demo('Pelican')` |
| **3** | A safe crossroads + a smart one | concurrency, safety invariants, **verification**, scaling | `create_junction; check_junction_safety('Junction')` |
| **3+** | The 4-way rebuilt from reusable parts | **modularity, reuse, encapsulation, interfaces** | `create_tl_lib; create_junction_modular; run_demo('Junction4WayModular')` |

## Folder layout

```
traffic_lights/
  README.md                  <- you are here
  worksheets/                <- give these to the student
    day1_single_light.md
    day2_pelican.md
    day3_junction.md
    day3_modular.md          <- Day 3 extension: modularity & reuse
  instructor/                <- for the supervisor
    guide.md                 <- timings, answers, talking points, troubleshooting
    se_concepts_map.md       <- which activity teaches which SE concept
  scripts/                   <- the working MATLAB/Stateflow builders
    tl_helpers.m             <- shared toolkit (mkState/mkTrans/mkData/lamps/harness)
    create_single_light.m    <- Day 1 chart -> TrafficLight.slx
    create_pelican.m         <- Day 2 chart -> Pelican.slx
    create_junction.m        <- Day 3 chart -> Junction.slx
    create_junction_4way.m   <- Day 3 stretch (sensor-actuated, monolithic)
    create_tl_lib.m          <- Day 3 ext: reusable TrafficLightUnit -> tl_lib.slx
    create_junction_modular.m<- Day 3 ext: same 4-way from 4 linked units
    run_demo.m               <- simulate + animate + plot a timing chart
    check_junction_safety.m  <- prove "never two greens" (PASS/FAIL)
```

## How a script becomes a running model

Each `create_*.m`:
1. makes a fresh Simulink model with one Stateflow chart (`tl_helpers.newChartModel`),
2. adds the **outputs** (lamps) and any **inputs** (button / sensors),
3. adds **states** (each with an entry action setting the lamps),
4. adds **transitions** (timers `after(n,sec)` and guards `[...]`),
5. wires a small **harness** (logging, and a Manual Switch for inputs),
6. arranges, saves, and reports — then you `run_demo(...)` it.

The builders are **idempotent**: re-run any of them after an edit and the model
is rebuilt cleanly.

## Quick self-test (supervisor, before Day 1)

```matlab
create_single_light; run_demo('TrafficLight')
create_pelican;       run_demo('Pelican')
create_junction;      check_junction_safety('Junction')   % -> PASS
create_junction_4way; check_junction_safety('Junction4Way')% -> PASS
```

See `instructor/guide.md` for timings, expected answers and troubleshooting.

> Note: these scripts must run in a real MATLAB install — they were written to
> this repo's Stateflow-API pattern and cannot be executed in a headless CI /
> planning environment.
