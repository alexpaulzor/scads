# Cut list: designed, not yet produced

Tick an item (`[x]`) once it's cut, and add anything you find out (fit, problems, recipe) on the line under it.
Point me at this file when you want it updated or read back. G-code files are in `marbles/gcode/`.
Recipes: black acrylic `acrylic3` 100 % F150 x1 (calibrated 2026-11-10); ply3 F350 x1; mdf3 F700 x3 (unverified on
the new batch).

## Cut next

- **Acrylic: cut the spiral first, then the small parts à la carte from the offcuts.** All `acrylic3`, F150 × 1.
  (`acrylic_plate_379x291_acrylic3` packs them all into one 53 min job, if you ever want that.)
  - [ ] **Spiral**, layered top: `spiral_run_round_trim_pilot_287x291_acrylic3`. About 37 min; the outline is cut last.
        X0 Y0 = its bottom-left (the mount edge). 6.9 laps, 37 × M3 tap holes centred on the shelves, outline trimmed
        at the far corners. With the ring-test corner at the sheet's far corner, it stays clear.
    - Ply3 layers under it: `spiral_run_round_trim_slot_287x291_ply3`, × 1 or 2 (slots at the same 37 spots).
  - Spiral extras: ply3 is fine (acrylic versions are there too, `..._acrylic3`):
    - [ ] centre guide `spiral_round_centre_guide_102x108_ply3` (× 1, or × 2 for a taller wall), ~1.5 min;
    - [ ] entry guide `spiral_round_entry_guide_145x276_ply3`, ~2.5 min;
    - [ ] exit flange `spiral_round_exit_flange_54x54_ply3`, ~1 min.
  - [ ] Escapement pallets: `esc_pin_pallet_entry_49x40_acrylic3` × 2 and `esc_pin_pallet_exit_47x43_acrylic3` × 2.
  - [ ] Pallet keepers in acrylic: `esc_pin_pallet_keeper_55x21_acrylic3` × 2.
  - [ ] Ring D-jig acrylic layer: `ring_jig_d_rail_83x57_acrylic3`.
- [ ] **Escapement side plate** `esc_side_plate_296x220_ply3`, cut 2 (one per side): lantern ring (219 mm across, narrow
      rim), rocker hub plate and 1 pallet clamp. Everything for one side; about 9 min each.

## Escapement: pin-wheel deadbeat (`escapement_pin.py`, drawings `escapement_pin.png`, `views/esc_pin_tpallet_*.png`)

- [ ] **Lantern wheel faces**: `esc_pin_ring_220x220_ply3`, cut 2. 30 × M3 holes on r100, 608 seat, M5 along the spokes, 8 mm rim outside the pins.
- [ ] **Lantern hub spacer** (optional, instead of stacking 3 × 608): `esc_pin_hub_spacer_51x51_mdf3`, cut 7.
- [ ] **Rocker (anchor) face plates**: `esc_pin_anchor_plate_81x83_ply3`, cut 2. 608 seat, M5 for the 3 beams.
- [ ] **Pallets (entry)**: `esc_pin_pallet_entry_49x40_acrylic3`, cut 2 (2 layers = 6 mm, M3 through the stem).
- [ ] **Pallets (exit)**: `esc_pin_pallet_exit_47x43_acrylic3`, cut 2.
- [ ] **Pallet clamps (mount plates)**: `esc_pin_pallet_clamp_55x21_ply3`, cut 2.
- Hardware, not cut:
  - 2020 wheel spokes, 4 × 38 mm (optionally 4 more at 45°).
  - 2020 rocker arms, 2 × 171 mm.
  - Rocker tail (the pendulum, or a stub to it).
  - 30 × M3 × 30–35 screws with nuts and washers (the pins).
  - 608 bearings: 3 stacked in each hub.
  - 2 fixed 8 mm axles.
  - M5 screws and T-nuts.

## Pendulum drive (`pendulum_switch.py`, drawing `pendulum_switch.png`)

- [ ] **Marble switch rail**: one stack of
  - `pswitch_wall_mount_151x87_mdf3` × 1,
  - `pswitch_rail_a_flat_151x35_mdf3` × 2,
  - `pswitch_spacer_flat_151x31_mdf3` × 3,
  - `pswitch_rail_b_flat_151x35_mdf3` × 2,
  - `pswitch_wall_151x49_mdf3` × 1.
  - Copper foil tape on the rails.
- [ ] **Limit switch holders**: `limit_holder_single_54x28_mdf3`, cut 2 (turn one face down).
- [ ] **Actuator trip flag**: `limit_flag_37x33_mdf3`, cut 2.

## Spiral run (`spiral_run.py`, drawings `spiral_run.png`, `views/spiral_assembly_*.png`)

- [ ] **Spiral sheet**: `spiral_run_300x290_<ply3|mdf3|birch3>`. 7.26 laps, one cut line, entry-guide holes. Laminate 3?
- [ ] **Centre guide**: `spiral_centre_guide_122x105_<material>`, cut 1 (or 2: the second is the spacer).
- [ ] **Entry guide**: `spiral_entry_guide_162x285_<material>`, cut 1, on ~8 mm spacers.
- [ ] **Exit flange**: `spiral_exit_flange_54x54_<material>`, cut 1.
- [ ] Entry flange `spiral_entry_flange_54x38_<material>`: probably not needed now that the ball enters along the
      top rail.
- Not planned: the stair arms and the glue-up form (`spiral_stair_*`, `spiral_form_*`). You're making your own
  supports.
- The round acrylic spiral: see the acrylic list at the top. The earlier 296 mm version is replaced by the
  287 × 291 trimmed one.
## Jigs

- [ ] **Ring D-jig sandwich**, rail mount (centre 30 mm up, M5 10 mm up):
  - `ring_jig_base_rail_83x57_ply3` × 1,
  - `ring_jig_d_rail_83x57_acrylic3` × 1,
  - `ring_jig_d_rail_83x57_ply3` × 1.

## Re-cut to pick up interface changes (only if you need new ones)

- [ ] `feeder_tunnel_flange_54x54_mdf3` and `feeder_tunnel_relief_54x54_mdf3`: 8-notch flange pattern.
- [ ] `double_flange_94x72_mdf3`: 8-notch flange pattern.

## Done

- [x] `acrylic_cal_54x42_acrylic3`: black acrylic ring test (2026-11-10): F150 x1.

## Not designed yet (blocking a full build)

- Escapement frame: what holds the wheel axle and the rocker axle (183.6 mm apart, wheel above).
- Marble drive for the escape wheel: big ball wheel + lantern pinion, about 6:1.
- Seconds hand / disc on the escape wheel axle.
