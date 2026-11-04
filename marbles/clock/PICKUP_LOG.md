# Pickup mechanism + open items — design log

Started 2026-11-04. These are the user's ideas, written down as stated, **not designed yet**. Dig into each
item in its own session. Main notes and task list: `NOTES.md` §6 (L14+). Machine/pipeline TODOs:
`cnc_vibes/custom_setups/anolex/SETTINGS_2026-11-04.md`.

Context for a fresh session: the 2026-11-04 session transcript has every prompt the user typed (feeder box,
trough, ring jig, view slots, button macro). Re-read the user's prompts there for background if anything
here is unclear.

## 1. Pickup mechanism (the user's concept, 2026-11-04)

**Wire:** 12 or 14 ga, bent into hooks.

**Pendulum side (the grabber):**
- Hooks stick out from above the trough.
- A spiderweb tunnel (wire rings + straight wires, the ring jig / spider parts) curves the wires from
  vertical toward the direction of swing. The hooks extend from the last spiderweb ring.
- The wire ends are **fishhook-shaped**.

**Hopper side (the waiting ball):**
- A spiderweb wire track, fed from the bottom catch hopper, extends toward the pendulum, **parallel to its
  swinging plane**.
- Its wires end in a **triangle sloped end** (not hooked like the pendulum's catcher wires). The slope keeps
  the hopper-fed ball from rolling out.

**Springiness (both tunnels):** the wires continue some distance past the last ring, so they can flex
and spring back after being wedged apart.

**The hand-off:**
1. At the end of the pendulum stroke, the pendulum's fishhook ends meet the ball waiting on the hopper track.
2. The ball's round shape against the hook's own curve wedges the grabber fingers apart as the pendulum swings in.
3. The fingers snap back behind the ball and snag it.
4. The ball rolls into the feeder interface (the 20 x 20 port on the feeder front keeper / trough).

**Open questions (not yet answered):** how far the ball sits off the pendulum's path; the hook and
triangle shapes; finger overlap and spring rate; how many fingers; how the hopper track releases
exactly one ball; how the snagged ball gets from the fingers into the trough.

## 2. Spider tunnel to feeder interface adapter (near top of the to-do list)

A part that joins a spiderweb wire tunnel to the standard feeder port: the 20 x 20 opening with tab
slots and M5 bolt pattern (`feeder.scad`: PORT, PORT_BOLT, MID_ALL). The trough cap already shows the
bolt pattern.

## 3. Status changes recorded 2026-11-04

- L1–L4 marked done by the user (including L4, the V-slot faces check).
- The front-button reset works (home X/Y, go to the bed origin X21 Y8). The file is in cnc_vibes.

## 4. Still pending from before

- Cut-profile comparison sheet: new cuts green, removed cuts blue, unchanged red, for every shape that changed.
