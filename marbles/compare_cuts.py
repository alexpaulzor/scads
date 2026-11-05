#!/usr/bin/env python3
"""Compare cut files: which cuts are new, removed or unchanged.

Each cut in a G-code file (a "; --- cut i/n" block, or an etch block) becomes a set of points.
A cut in NEW with a match in OLD (all points within --tol, both ways) is unchanged (red); one
only in NEW is new (green); one only in OLD is removed (blue, dashed). Both files are taken from
their own X0 Y0 (bottom-left), so a part whose outline grew shows its outline as new + removed.

    python3 marbles/compare_cuts.py out.png OLD.gcode:NEW.gcode [OLD2:NEW2 ...]   # one panel per pair
    python3 marbles/compare_cuts.py out.png -:NEW.gcode                           # NEW only (all green)
    python3 marbles/compare_cuts.py out.png OLD.gcode@0,-20:NEW.gcode             # shift OLD by (dx, dy) first
                                                                                  # (e.g. an edge was trimmed, moving X0 Y0)
"""
import math
import re
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from shapely.geometry import MultiPoint  # noqa: E402

XY = re.compile(r"\b([XY])(-?[0-9.]+)")


def cut_blocks(path):
    """list of point lists, one per cut / etch block (G1 moves only, in order); PATH@dx,dy shifts them"""
    if path in ("-", ""):
        return []
    if "@" in path:
        path, off = path.split("@")
        dx, dy = (float(v) for v in off.split(","))
        return [[(x + dx, y + dy) for x, y in b] for b in cut_blocks(path)]
    blocks, cur = [], None
    x = y = 0.0
    for ln in Path(path).read_text().splitlines():
        if ln.startswith("; --- cut") or ln.startswith("; --- etch"):
            cur = []
            blocks.append(cur)
            continue
        c = ln.split(";")[0].strip()
        if c.startswith("M5"):
            cur = None
            continue
        if not (c.startswith("G1") or c.startswith("G0")):
            continue
        for ax, v in XY.findall(c):
            if ax == "X":
                x = float(v)
            else:
                y = float(v)
        if cur is not None and (c.startswith("G1") or not cur):
            cur.append((x, y))
    return [b for b in blocks if len(b) > 1]


def classify(old, new, tol):
    mo = [MultiPoint(b) for b in old]
    mn = [MultiPoint(b) for b in new]
    used = set()
    status_new = []
    for n in mn:
        hit = next((i for i, o in enumerate(mo) if i not in used and n.hausdorff_distance(o) <= tol), None)
        if hit is None:
            status_new.append("new")
        else:
            used.add(hit)
            status_new.append("same")
    removed = [old[i] for i in range(len(old)) if i not in used]
    return status_new, removed


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    out = Path(sys.argv[1])
    tol = 0.05
    pairs = []
    for a in sys.argv[2:]:
        if a.startswith("--tol="):
            tol = float(a.split("=")[1])
            continue
        o, n = a.split(":")
        pairs.append((o, n))
    cols = min(3, len(pairs))
    rows = math.ceil(len(pairs) / cols)
    fig, axes = plt.subplots(rows, cols, figsize=(6.2 * cols, 4.2 * rows), squeeze=False)
    for ax in axes.flat:
        ax.axis("off")
    for ax, (o, n) in zip(axes.flat, pairs):
        old, new = cut_blocks(o), cut_blocks(n)
        st, removed = classify(old, new, tol)
        for b in removed:
            ax.plot(*zip(*b), color="#1f6feb", lw=1.1, ls=(0, (3, 2)))
        for b, s in zip(new, st):
            ax.plot(*zip(*b), color="#d62728" if s == "same" else "#2ca02c", lw=1.3 if s == "new" else 0.9)
        nn, ns = st.count("new"), st.count("same")
        title = Path(n).stem if n not in ("-", "") else Path(o.split("@")[0]).stem
        sub = f"{nn} new (green), {len(removed)} removed (blue), {ns} unchanged (red)"
        if o in ("-", ""):
            sub = f"new part: {len(new)} cuts"
        ax.set_title(f"{title}\n{sub}", fontsize=9)
        ax.set_aspect("equal")
        ax.axis("on")
        ax.tick_params(labelsize=7)
        ax.grid(alpha=0.2)
        print(f"{title}: {sub}  (old {Path(o.split('@')[0]).name if o not in ('-', '') else '-'})")
    fig.tight_layout()
    fig.savefig(out, dpi=110)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
