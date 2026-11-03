import json, sys
def sheet(fname, key, title, sub, out, cell=(360, 300), cols=4, totals=None):
    d = json.load(open(fname))[key]
    W = cell[0] * min(cols, len(d)); rows = (len(d) + cols - 1) // cols; H = 110 + rows * cell[1]
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}"><rect width="100%" height="100%" fill="#fbfaf7"/>',
         f'<text x="20" y="34" font-family="DejaVu Sans Mono" font-size="20" font-weight="700">{title}</text>',
         f'<text x="20" y="58" font-family="DejaVu Sans Mono" font-size="13" fill="#555">{sub}</text>']
    for i, p in enumerate(d):
        cx, cy = (i % cols) * cell[0], 80 + (i // cols) * cell[1]
        x0, y0, x1, y1 = p["bounds"]; w, h = x1 - x0, y1 - y0
        s = min((cell[0] - 60) / w, (cell[1] - 110) / h)
        ox, oy = cx + (cell[0] - w * s) / 2, cy + 40 + (cell[1] - 110 - h * s) / 2
        path = ""
        for poly in p["polys"]:
            for ring in [poly["outer"]] + poly["holes"]:
                path += "M" + " L".join(f"{ox + (x - x0) * s:.1f},{oy + (y1 - y) * s:.1f}" for x, y in ring) + "Z "
        o.append(f'<rect x="{cx+8}" y="{cy}" width="{cell[0]-16}" height="{cell[1]-12}" rx="8" fill="#fff" stroke="#ddd"/>')
        o.append(f'<text x="{cx+20}" y="{cy+26}" font-family="DejaVu Sans Mono" font-size="15" font-weight="700">{p["key"]}: {p["name"]}</text>')
        o.append(f'<path d="{path}" fill="#e7d3a8" fill-rule="evenodd" stroke="#7a5420" stroke-width="1.2"/>')
        q = totals(p) if totals else f'qty {p["per_fork"]}'
        o.append(f'<text x="{cx+20}" y="{cy+cell[1]-24}" font-family="DejaVu Sans Mono" font-size="13" fill="#444">{w:.1f} x {h:.1f} mm   {q}</text>')
    o.append('</svg>')
    open(out, "w").write("".join(o))
sheet("thumbs_fork.json", "fork", "2f  Cut parts for one wheel fork (3.2 MDF), drawn to the same scale each",
      "x = across the fork toward its back wall (M is off the left edge), y = along the beam. All holes M5 = 5.0.",
      "out/thumbs_fork.svg", totals=lambda p: f'{p["per_fork"]} per fork, {4*p["per_fork"]} for 4 forks')
sheet("thumbs_assy.json", "assy", "1g  Cut parts in the assembly",
      "Sieves and keepers are the parts you already have G-code for. Each fork is 10 layers (sheet 2f).",
      "out/thumbs_assy.svg", cell=(520, 330), cols=3, totals=lambda p: f'qty {p["per_fork"]}')
