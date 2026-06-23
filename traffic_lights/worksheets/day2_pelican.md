# Day 2 — The Pelican Crossing (a push button)

**Goal:** make the system *react to the outside world*. Yesterday the light ran
on a timer with no inputs. Today a pedestrian presses a button — and the system
has to handle it **safely**.

Three new ideas today:

- **Input** — information coming *into* the machine (the button).
- **Guard / condition** — a transition that only fires *if* something is true,
  written in square brackets, e.g. `[req]`.
- **Latch** — *remembering* that the button was pressed, even after the
  pedestrian lets go.

---

## Activity 2.1 — Think like a safety engineer (paper, ~20 min)

A pedestrian crossing controls **cars** *and* **people** with one machine.
Before designing, answer these:

1. When the pedestrian gets a green man, what **must** the cars be showing?
   What must they have shown *just before* that? (Hint: cars can't jump from
   green straight to red being safe — there's a stage in between.)

2. A car is doing 30 mph. If the lights went green-for-pedestrians the *instant*
   the button was pressed, what happens? Why must there be a **minimum** time
   the cars stay green, and a gap where **everything is red**?

3. The button is pressed for a tenth of a second while no lights are changing.
   How does the machine make sure that press isn't *forgotten*? (This is the
   **latch**.)

4. The button is pressed *again* while the green man is already showing. What
   should happen — nothing? start over? Decide, and write down why.

> Checkpoint — defend your answers to your supervisor. There are no silly
> answers here; safety engineering is mostly asking "what if...?"

---

## Activity 2.2 — Build & drive it (MATLAB, ~30 min)

```matlab
create_pelican               % builds Pelican.slx
run_demo('Pelican')          % runs it; chart opens so you can watch
```

While the simulation runs, **double-click the "Press" switch** (it's the
Manual Switch block) to flip it to `1` — that's the pedestrian pressing the
button. Watch what the lights do, and *when*.

---

## Activity 2.3 — Observe & check (~20 min)

- Press the button right after green starts. Does the crossing change
  *immediately*, or does it wait? Find the line in `create_pelican.m` that
  causes that wait: `[req && after(5,sec)]`. Explain it in your own words.
- Find where the press is **latched**: `du: if request; req = true; end`.
- Find where the request is **cleared** so the next pedestrian starts fresh:
  `en: req = false;` in `PED_FLASH`.
- Tap the button quickly and let go. Is it still serviced? Why?

---

## Activity 2.4 — The flashing amber (~20 min)

Watch the end of a crossing cycle carefully. After the steady green man, the
cars get a **flashing amber** and the green man **flashes** too — this is the
`PED_FLASH` state. It means "pedestrians still crossing have priority, but cars
may go once it's clear". It's the signature of a UK *Pelican* crossing.

1. **How does a light flash?** A steady lamp is just `amber = 1`. To make it
   flash you must turn it on and off *over time*. Find this line in
   `PED_FLASH`:

   ```
   du: blink = blink + 1; if blink >= 5; veh_amber = 1 - veh_amber; ped_green = 1 - ped_green; blink = 0; end
   ```

   In your own words: what does it do every time step? Why `1 - veh_amber`?
   That toggling is itself a tiny state machine (on → off → on → off…) living
   *inside* one state.

2. **Change the flash rate.** The chart runs every 0.1 s. `blink >= 5` flips the
   lamp every 0.5 s. Change `5` to make it flash twice as fast, re-run, and
   confirm on the timing chart.

3. **Spot the requirement difference.** A Pelican goes *flashing-amber → green*
   with **no** red+amber in between — unlike the single light on Day 1, and
   unlike a road junction. Why might the rules be different for different kinds
   of crossing? (This is a real systems-engineering point: the *requirements*
   come from the situation, not from "how lights always work".)

---

## Activity 2.5 — Extend it (challenge, optional)

Add a rule: the crossing can't be triggered more than once per 30 seconds.
Where would that logic live, and what new data would you need?

> **Big idea:** the timer-only machine from Day 1 was *predictable*. Adding an
> input made it *responsive* — but responsiveness without rules is *dangerous*.
> Guards, latches and minimum times are how engineers make a reactive system
> safe.
