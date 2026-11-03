"""Cut-part thumbnail sheets for the wheel boxes (reads scenes/box_*.json from wheel_box.py)."""
import json
src = open("thumbs.py").read().split('sheet("thumbs_fork.json"')[0]
exec(src)
d = json.load(open("scenes/box_dims.json"))
sheet("scenes/box_thumbs.json", "parts", f"2f  Cut parts for one wheel box (T = {d['T']} mm), each drawn to fit",
      "All holes M5 = 5.0, round. Tabs and fingers 10 wide. FC: the left edge faces M. The near wall is the keeper (sheet 1g).",
      "out/b_thumbs_box.svg", cell=(420, 360), cols=3, totals=lambda p: f'{p["per_fork"]} per box, {4*p["per_fork"]} total')
sheet("scenes/box_thumbs.json", "assy", f"1g  Cut parts in the slide (T = {d['T']} mm)",
      "Sieve already cut. WK = one wheel's keeper and near wall (beam row slotted for that wheel's tension). PK = plain guard/backing.",
      "out/b_thumbs_assy.svg", cell=(470, 330), cols=4, totals=lambda p: f'qty {p["per_fork"]}' if p["per_fork"] else 'qty: as needed')
