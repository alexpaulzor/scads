import sys, math
from pathlib import Path; sys.path.insert(0, str(Path(__file__).resolve().parent)); sys.argv = ['x']
import spiral_run as S
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Circle
B = S.build()
fig, axs = plt.subplots(1, 2, figsize=(16, 8.4), gridspec_kw={'width_ratios': [1.15, 1]})
import math
for ax, zoom in zip(axs, (False, True)):
    ax.add_patch(Rectangle((0, 0), 300, 300, fc='#f3e6cf', ec='k'))
    x, y = zip(*B['cut']); ax.plot(x, y, 'r-', lw=.8, label='sheet: the one spiral cut')
    for h, lab in B['holes']:
        hx, hy = zip(*h); ax.fill(hx, hy, 'w'); ax.plot(hx, hy, 'r-', lw=.8)
    g = B['guide']
    gx, gy = g.exterior.xy; ax.fill(gx, gy, color='peru', alpha=.55, label='centre guide (separate piece)')
    ax.plot(gx, gy, 'k-', lw=.8)
    for b in B['bolts']: ax.add_patch(Circle(b, 2.5, fc='w', ec='k', lw=.8))
    bx, by = zip(*B['ball']); ax.plot(bx, by, ':', color='steelblue', lw=.7, label='ball centre on the shelves')
    px, py = zip(*B['path']); ax.plot(px, py, '-', color='steelblue', lw=1.6, label='ball centre in the guide channel')
    ax.add_patch(Rectangle((S.CX - S.FLANGE_HALF, S.CY - S.FLANGE_HALF), 2 * S.FLANGE_HALF, 2 * S.FLANGE_HALF,
                           fill=False, ls='--', ec='gray', label='exit flange (under the sheet)'))
    eg = B['entry_guide']; ex_, ey_ = eg.exterior.xy
    ax.fill(ex_, ey_, color='sienna', alpha=.45, label=f'entry guide (~10 above the sheet, {S.ENTRY_SPAN:g} deg)')
    for q in B['entry_m5']: ax.add_patch(Circle(q, 2.5, fc='w', ec='k', lw=.8))
    for phi, (arm, steps, m5) in B['arms'].items():
        u = (math.cos(math.radians(phi)), math.sin(math.radians(phi)))
        ax.plot([S.CX + S.ARM_S0 * u[0], S.CX + arm.bounds[2] * u[0]], [S.CY + S.ARM_S0 * u[1], S.CY + arm.bounds[2] * u[1]],
                '-', color='green', lw=3, alpha=.6, label='stair arms (under the sheet)' if phi == 45 else None)
    ax.add_patch(Rectangle((0, 0), 300, 20, fc='silver', alpha=.5, label='edge beam (on top of the sheet)'))
    if zoom:
        for k in range(0, len(B['path']), 75):
            ax.add_patch(Circle(B['path'][k], S.BALL_R, fill=False, ec='steelblue', lw=.6))
        ax.set_xlim(S.CX - 75, S.CX + 75); ax.set_ylim(S.CY - 65, S.CY + 70)
        ax.set_title(f"Centre: guide channel curls {B['curl']} deg from the bridge into the bore (tightest turn r {B['rmin']:.0f})")
    else:
        ax.set_xlim(-5, 305); ax.set_ylim(-5, 305)
        ax.set_title(f"spiral_run v3: {B['laps']:.2f} laps, pitch {S.PITCH}, {S.DROP_REV:g} drop per lap on 4 stair arms")
        ax.text(150, 3, 'mount edge (top in use): M5 every 50 into the 2020', ha='center', fontsize=8)
        ax.legend(loc='upper right', fontsize=7)
    ax.set_aspect('equal'); ax.grid(alpha=.25)
plt.tight_layout(); plt.savefig(str(Path(__file__).resolve().parent / 'spiral_run.png'), dpi=110)
fig, axs = plt.subplots(1, 4, figsize=(18, 4.4))
for ax, (phi, (arm, steps, m5)) in zip(axs, B['arms'].items()):
    x, y = arm.exterior.xy; ax.fill(x, y, color='peru', alpha=.5); ax.plot(x, y, 'k-', lw=.7)
    for r in arm.interiors: ax.plot(*r.xy, 'k-', lw=.7)
    for s_in, s_out, z in steps: ax.text((s_in + s_out) / 2, z + 1.5, f'{-z:.1f}', ha='center', fontsize=6)
    ax.set_title(f'stair arm {phi} deg (s from the centre, z below the frame)', fontsize=8); ax.set_aspect('equal'); ax.grid(alpha=.3)
plt.tight_layout(); plt.savefig(str(Path(__file__).resolve().parent / 'spiral_stairs.png'), dpi=110)
