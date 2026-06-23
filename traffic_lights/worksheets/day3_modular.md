# Day 3 Extension — Modularity & Reuse (build the junction *properly*)

**Goal:** build the 4-way junction a second time — but instead of one giant
chart, assemble it from a **reusable component used four times**. Then feel the
difference. This is one of the most important ideas in all of engineering:
**don't build big things as one lump; build small reusable pieces and combine
them.**

Two new words:

- **Module / component** — a self-contained piece with a clear job and a small
  **interface** (its inputs and outputs). You can use it without knowing how it
  works inside.
- **Reuse** — define something once, use it many times. Fix it once, and every
  use is fixed.

---

## Activity M.1 — Spot the duplication (paper + reading, ~15 min)

Open `create_junction_4way.m` (the monolithic version you built earlier).

1. Find the `lamps(...)` line. Count how many states call it — i.e. how many
   times the **six-lamp pattern** is written out. (It's roughly one per state.)
2. Now imagine the boss says "make the amber last one second longer." In the
   monolithic chart, how many places might you have to change? What could go
   wrong if you miss one?
3. Write one sentence: why is repeating the same pattern many times risky?

---

## Activity M.2 — Meet the reusable component (~15 min)

Open `create_tl_lib.m`. This defines **one** traffic light, **once**, as a
component called `TrafficLightUnit`, living in a *library*.

Look at its **interface** — that's the whole contract the outside world sees:

| Direction | Name | Meaning |
|-----------|------|---------|
| in  | `go`     | "you should be green" |
| out | `r,a,g`  | the three lamps |
| out | `is_red` | "I am fully stopped" (used as a safety signal) |

Notice what the unit does **not** know: it has no idea it's part of a junction,
how many other lights exist, or whose turn it is. It only knows how *one* UK
light sequences. That ignorance is a feature — it's what makes it reusable.

---

## Activity M.3 — Assemble & run (~20 min)

```matlab
create_tl_lib                              % build the reusable component (once)
create_junction_modular                    % link it 4x (N/S/E/W) + a Controller
run_demo('Junction4WayModular')            % watch all four arms
```

You'll see **four** traffic-light heads — a whole crossroads. Open
`create_junction_modular.m` and find:

- the four **linked** copies `N, S, E, W` (all the same component);
- the small **`Controller`** chart — it only decides *whose turn it is*
  (`ns_go`, `ew_go`) and waits for `is_red` before swapping. It contains **no**
  lamp logic at all.

This split has a name: **separation of concerns**. The unit handles "how a light
works"; the controller handles "junction policy". Neither meddles in the other.

> Engineer's aside: the controller reads each unit's `is_red` through a tiny
> one-step **Unit Delay** (`d_ns`, `d_ew`). That's there to break a feedback
> *algebraic loop* between the two machines — a real and common modelling
> detail when components feed signals back to each other.

---

## Activity M.4 — One edit, four lights (~20 min) ★

Here's the payoff. Change the component **once** and watch all four arms change.

1. In `create_tl_lib.m`, change the green→red amber time, e.g. make `AMBER`'s
   `after(2,sec)` into `after(4,sec)`.
2. Rebuild and re-run:
   ```matlab
   create_tl_lib                 % rebuild the component
   create_junction_modular       % relink it
   run_demo('Junction4WayModular')
   ```
3. All **four** arms now use the new timing — from **one** edit.
4. Contrast: in `create_junction_4way.m` you'd have had to find and edit every
   amber state by hand, and hope you didn't miss one (Activity M.1).

---

## Activity M.5 — Reuse the *test*, too (~10 min)

```matlab
check_junction_safety('Junction4WayModular')
```

The **exact same** safety checker you used on the monolithic junction passes on
this completely different build — **unchanged**. Why?

Because both models expose the same `ns_green` / `ew_green` signals — the same
**interface**. Good interfaces let you reuse not just components, but the tools
and tests built around them. That is a huge deal in real engineering.

---

## Discussion (write a few notes)

- When is it worth the extra effort to build a reusable component instead of
  just one big chart? (Hint: how many times will it be used? how likely to
  change?)
- The unit and the controller talk through a tiny interface (`go`, `is_red`).
  Why is a *small, clear* interface better than a big one?
- This is exactly how real systems scale: a car has one "door controller"
  design reused on four doors; an aircraft reuses one "control surface" module
  many times. Name something else that's built from repeated identical modules.

> **Big idea:** the monolithic junction and this one do the *same thing*. But one
> is built from a reusable, testable, edit-once component — and that is the
> difference between something you can grow and maintain, and something that
> fights you every time it changes.
