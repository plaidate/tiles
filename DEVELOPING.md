# Developing tile games (engine + workflow notes)

How to build a game in this repo. General Playdate conventions live in
`~/Projects/playdate/PLAYDATE-GUIDE.md`; this file is the Tiles-engine
specifics. Written for a fresh session to be productive immediately.

## The engine (`core/`)

16x16 tiles on the 400x240 screen = exactly 25x15 tiles; house layout is
a 16px HUD row plus a 25x14 playfield. Everything is code-drawn: tiles
are pattern fills + string-art overlays, sprites are string art.

- `tmap.lua` — `Tiles.def(ch, {solid=, kind=, pat=, art=})` registers a
  tile type (prerendered to an image once; extra fields like `shootthru`
  ride along for games to query via `Map.def`). `Map.load(rows, ox, oy)`
  takes an array of strings, one char per tile. `Map.build()` renders the
  whole map ONCE into a background image; `Map.set` repaints just that
  cell — static terrain costs one blit per frame regardless of
  complexity (same performance model as Vox). `Tiles.PAT` has the
  standard dither ramp (WHITE/LIGHT/MID/DARK/BLACK).
- `tspr.lua` — `Spr.make(rows)`: '.' transparent, '#' black, 'o' white.
  `Spr.draw(img, x, y, flip)` draws centered. Palette rule that reads:
  white player with black outline, dark enemies with a white eye pixel.
- `tphys.lua` — AABB actors ({x,y} center, {hw,hh} half extents) moved
  with 1px sub-steps, axis-separated: `Phys.move(a, dx, dy, isSolid)`.
  `Phys.moveAssist` adds the classic corner nudge (blocked on one axis
  but nearly aligned with an open corridor -> slide into alignment).
  Games pass their own `isSolid(tx, ty)` closure to add bombs, doors etc.
  `Phys.bfs`/`Phys.firstStep`/`Phys.descend` are the shared pathfinding
  used by chase AI and every autopilot.
- `tkit.lua` — `Kit.title/over/panel/text/centered`, 2D debris particles,
  screen shake (`Kit.shake` + `gfx.setDrawOffset(Kit.sx, Kit.sy)`), and
  `Kit.marker` — the bobbing player-locator chevron every avatar game
  draws last (user rule: bold player visibility).
- `tcam.lua` — the camera, for maps bigger than the screen. Everything
  draws in WORLD coordinates; `Cam.apply()` routes it through
  `gfx.setDrawOffset`, `Cam.done()` returns to screen space for the HUD.
  `Cam.follow(wx, wy, dt)` smooth-follows (clamped so the map always
  fills the viewport under the 16px HUD row); `Cam.center` snaps on
  spawns/room entry. Screen-sized maps clamp to a fixed camera, so
  static games can ignore it entirely (blast/spirit/relic do).
  See games/burrow for the pattern — including crank-pans-the-camera,
  a scrolling-native crank mapping.
- `tsnd.lua` — `Snd.play(wave, freq, dur, vol)` over a small synth pool,
  `Snd.boom` for descending noise sweeps.
- `tutil.lua` — clamp/sign/dist2/choose + the `Util.after` scheduler.
- `harness.lua` — smoke instrumentation (identical to voxel's).

## Adding a game (checklist)

1. `games/<name>/` with `pdxinfo` (bundleID `com.sdwfrost.tiles.<name>`),
   `config.lua`, `gamestate.lua`, a map/world module (`arena.lua` or
   `world.lua`), `game.lua`, `input.lua`, `draw.lua`, `main.lua`. Copy
   the shape from `games/blast/` (single arena) or `games/relic/`
   (rooms-as-data + saves).
2. Add the name to `GAMES` in the Makefile.
3. `main.lua` boilerplate: `import "lib"` then the game modules;
   `setRefreshRate(SMOKE_BUILD and 0 or 30)`; `Harness.frame` wrapping
   Input.poll -> Game.update(Config.DT) -> Util.runPending -> Draw.frame;
   `Harness.extra` fields + `Harness.shotPath =
   ".../tiles/build/<name>-shot.png"`; updMs/drwMs rolling timings.
4. Smoke-shorten campaigns: `LEVELS = SMOKE_BUILD and 2 or 5`.
5. Autopilot in `game.lua` behind `Harness.enabled`, driving Input.state
   (the same paths humans use). Follow the master guide's autopilot
   lessons — and these, learned here:
   - **Post-win reckless mode** (stop dodging AND stop attacking, stand
     somewhere genuinely lethal) is how one long run exercises win,
     death, and game-over. Check the kill spot has line of fire — the
     first relic attempt parked in a wall's shadow and lived forever.
   - Walk-to-cell steering must keep pressing toward the cell CENTER on
     arrival: room-edge transitions trigger past the cell edge, and
     stopping on arrival strands the actor in the dead zone.
   - Anything walkable-until-you-leave (dropped bombs) must stay
     passable until the actor's BOX fully clears the tile — center-cell
     checks freeze you straddling the boundary (this bug caused 90
     self-kills before diagnosis).
6. Verify: `tools/smoke.sh <name> 240 '"wins":[1-9]'` then a
   `'"gameovers":[1-9]'` run. LOOK AT THE SCREENSHOTS — they caught
   unreadable pillars, a key spawned on water, and the stuck-in-the-gap
   bug that counters alone only hinted at.
7. Package: pick a good `build/<name>-shot-<frame>.png` as
   `games/<name>/screenshot.png`, write the README, add a row to the
   root README table, `cp -r out/<Title>.pdx dist/`.

## Design notes (learned, user-aligned)

- Palette that reads on 1-bit: LIGHT dithered floors with an etched dot
  per tile, DARK walls with a white top bevel, MID for water/crates,
  white caps on landmarks. Mid-gray pillars vanish against light floors
  — indestructibles want DARK.
- Room/level data as strings, one char per tile; for multi-room games
  define 23x12 INTERIORS and let a loader add the border + standardized
  exit gaps (rows 7-8 / cols 12-13) so rooms always line up. Validate
  string widths at import time — hand-authored rows WILL be off by one.
- Spawn coordinates in data go through `findOpen` (nearest open cell) —
  hand-placed spawns land on trees/water more often than you'd think.
- Performance: whole games measured ~0.1-1ms update + draw in the
  Simulator (30fps budget is 33ms). The bg-image map blit is effectively
  free; don't hand-optimize before measuring.
