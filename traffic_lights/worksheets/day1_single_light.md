# Day 1 — One Traffic Light

**Goal:** understand what a *state machine* is by building the simplest possible
traffic light: one signal that cycles on a timer.

You will hear three words all day. Learn them now:

- **State** — a situation the system can be *in* (e.g. the light is on RED).
- **Transition** — a *move* from one state to another (RED → RED+AMBER).
- **Event / trigger** — the *reason* a transition happens. Today the trigger is
  always "enough time has passed".

---

## Activity 1.1 — Draw it first (paper, ~20 min)

Do **not** touch MATLAB yet. On paper:

1. A UK traffic light shows four patterns in this order, forever:

   | State       | 🔴 red | 🟠 amber | 🟢 green |
   |-------------|:-----:|:-------:|:-------:|
   | RED         |       |         |         |
   | RED + AMBER |       |         |         |
   | GREEN       |       |         |         |
   | AMBER       |       |         |         |

   Fill in the table — tick which lamps are **on** in each state.

2. Draw each state as a bubble. Draw an arrow from each state to the next.
   On every arrow write **how long** the system waits before moving (your
   choice of seconds — real lights are not all equal!).

3. Which state should the light start in when the power is switched on? Mark it
   with a little incoming arrow from nowhere. (This is called the **default
   state**.)

> Checkpoint — talk it through with your supervisor before moving on.

---

## Activity 1.2 — Build it (MATLAB, ~30 min)

In MATLAB, with the `traffic_lights/scripts` folder on the path:

```matlab
create_single_light          % builds TrafficLight.slx
run_demo('TrafficLight')     % runs it and draws the timing chart
```

While it runs, watch the chart: the **active state lights up**. That highlight
moving around the chart *is* your paper diagram coming alive.

---

## Activity 1.3 — Observe & check (~15 min)

- Does the order of states match the table you drew?
- On the timing chart, are exactly the right lamps "on" in each state?
- Read `create_single_light.m`. Find:
  - the line that says the light **starts on RED** (`mkDefault`),
  - the **entry actions** that switch lamps on/off (`en: red=1; ...`),
  - the **timers** on the transitions (`after(5,sec)`).

---

## Activity 1.4 — Make it yours (~15 min)

Change something, re-run, and predict the result *before* you look:

- Make GREEN last twice as long.
- Swap an `after(...)` time and see the timing chart shift.

> **Engineer's habit:** change *one* thing, predict, run, compare. That loop —
> *design → build → run → check* — is the heart of systems engineering, and you
> will use it every single day this week.
