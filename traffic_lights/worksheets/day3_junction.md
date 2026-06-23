# Day 3 — The Junction (and how systems scale)

**Goal:** control **two** interacting traffic lights at a crossroads without
ever causing a crash — then talk about how real engineers handle systems with
*hundreds* of states.

The single most important idea today:

- **Safety invariant** — a statement that must be true *at every instant*, no
  matter what. For our junction it is:

  > **North-South green and East-West green must NEVER be on at the same time.**

If that is ever false for even one moment, cars collide. Today you don't just
*hope* it's true — you **prove** it.

---

## Activity 3.1 — Design the phases (paper, ~25 min, as a pair)

A crossroads has two approaches: **North-South (NS)** and **East-West (EW)**.

1. Only one approach can be green at a time. While NS is green, what is EW
   showing? (All the time?)

2. When it's EW's turn next, you can't just switch NS-green off and EW-green
   on. List, in order, every stage NS goes through to stop, and every stage EW
   goes through to start. (Remember Day 1's full UK sequence, and Day 2's idea
   of an **all-red gap**.)

3. Write your phases as a ring (a cycle of states). Beside each, note which of
   the six lamps are on:

   `ns_red ns_amber ns_green | ew_red ew_amber ew_green`

4. Circle every phase where the invariant could be at risk. Convince yourself
   it never breaks.

> Checkpoint — walk your supervisor around your ring of phases.

---

## Activity 3.2 — Build & prove it (MATLAB, ~30 min)

```matlab
create_junction                      % builds Junction.slx
run_demo('Junction')                 % watch the two lights take turns
check_junction_safety('Junction')    % PROVE the invariant holds
```

`check_junction_safety` simulates the whole run and checks, at every time step,
that the two greens are never on together. It prints **PASS** or **FAIL**.

---

## Activity 3.3 — Break it on purpose (~20 min)

This is the best part. Engineers trust tests more when they've *seen them fail*.

1. In `create_junction.m`, make the NS approach go straight to EW green with no
   all-red gap (or delete a clearance transition). Re-run `create_junction`,
   then `check_junction_safety('Junction')`.
2. Did it catch the danger? At what time?
3. Put it back. Re-run the check and confirm **PASS** again.

> You just did **verification**: written, repeatable evidence that the system
> meets a requirement. "It looked fine when I watched it" is not evidence.

---

## Activity 3.4 — Make it smart, and talk about scale (~30 min)

```matlab
create_junction_4way                 % sensor-actuated junction
run_demo('Junction4Way')             % toggle the NS demand / EW demand switches
check_junction_safety('Junction4Way')% the invariant must STILL hold
```

This version has a **sensor** on each road and only turns a light green when a
car is actually waiting. Toggle the demand switches and watch it serve whoever's
there.

**Night / fault mode.** There is also a `night_demand` switch. Toggle it on and
watch every approach drop to a **flashing amber** (the same flashing trick as
the pelican crossing). Notice two things:

- It uses the *exact* flashing technique from Day 2 — a lamp toggled on a
  counter inside the `NIGHT` state. The same small idea reused in a bigger
  system.
- The junction only *enters* night mode at a **safe point** (when it's idle or
  clearing) — never by snapping out of a green. That's the Day-2 "finish safely
  first" rule again. Watch the timing chart: how long does it take to enter
  night mode if you flip the switch while a light is green? Why is that *good*?
- Because nothing is ever green in night mode, `check_junction_safety` still
  **PASS**es. A new mode, same invariant.

Discussion (write a few notes for each):

- **Fairness:** if NS is always busy, can EW ever get starved out? Look at how
  the chart serves the *other* side after each phase. Is that enough?
- **Green extension:** real junctions keep a light green a bit longer while cars
  keep arriving. Where in the chart would that rule go?
- **Scaling up:** a real crossroads has dedicated *turn* arrows, separate lamps
  for all four arms (that's 12+ lamps), and pedestrian phases too. If you tried
  to draw *one giant flat diagram* of every combination, how many states would
  there be? Why is that unmanageable?
- **The answer — hierarchy & concurrency:** engineers split a big machine into
  smaller machines that run *side by side* (each arm's lights) coordinated by
  one *controller* (whose turn is it?). Sketch how you'd split our junction that
  way.

---

## Activity 3.5 — Bonus: a model is just structure (~15 min)

The repo already has a tool that reads a Stateflow chart back into a script:

```matlab
slx2script('Junction.slx', 'Junction', 'Junction_rebuild.m')
```

Open `Junction_rebuild.m`. Every state, transition and timer you built is just
*data* that can be read, written and regenerated. That's a deep idea: your
design is information, and information can be inspected, checked and
transformed by other programs.

> **Big idea of the week:** real systems are too big to hold in your head all at
> once. You tame them by *decomposing* them into states and smaller machines,
> stating the rules that must never break, and *verifying* them — exactly what
> you did from one light up to a smart junction.
