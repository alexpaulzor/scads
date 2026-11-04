# Moving marbles/ to its own repo (task #22)

Tested 2026-11-04 on a local copy. The marble history (80 commits) moves with it, and the scripts find quickcut and the
material profiles through a `cnc_vibes` git submodule. `fit_coupon.py` and `clock/ring_jig_compact.py`
produced the same files as here.

**Blocked on you:** this Claude session can't create GitHub repositories (403). Create an **empty**
private repo (no README), e.g. `alexpaulzor/marble-clock`, then run the steps below or ask a session to
(it will need that repo added to the session).

```sh
# 1. split marbles/ with its history (run in scads)
git subtree split --prefix=marbles -b marbles-split

# 2. new repo from the split
git clone -b marbles-split ~/src/scads marble-clock && cd marble-clock
git branch -m main
mkdir -p lib && cp ~/src/scads/lib/t2020beam.scad lib/        # the one file outside marbles/ it uses
sed -i 's|use <../lib/t2020beam.scad>;|use <lib/t2020beam.scad>;|' marbles2.scad

# 3. shared tooling as a submodule (quickcut, material profiles, validator)
git submodule add https://github.com/alexpaulzor/cnc_vibes.git cnc_vibes
git add -A && git commit -m "own repo: lib/t2020beam.scad, cnc_vibes submodule"
git remote set-url origin https://github.com/alexpaulzor/marble-clock.git
git push -u origin main
```

Then in scads: `git rm -r marbles` and add a one-line pointer to the new repo in the README (once
you're happy the new repo works).

**Keeping in sync** (no library machinery):
- Pull new cnc_vibes changes into the marble repo: `git submodule update --remote cnc_vibes && git commit -am "bump cnc_vibes"`.
- Change a material/profile from the marble repo: edit inside `cnc_vibes/`, commit and push *there*
  (it's a normal checkout), then commit the bumped pointer in the marble repo.
- Fresh clone: `git clone --recurse-submodules ...` (or `git submodule update --init` after a plain clone).
- `laser_parts.find_quickcut` looks in `./cnc_vibes/quickcut` first, then the old sibling layout, so
  the scripts work in both places during the move.
