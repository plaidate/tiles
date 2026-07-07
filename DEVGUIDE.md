# Tiles — developer guide

The engine architecture, the per-game file layout, how to add a new game,
and one-paragraph notes on each shipped game. General Playdate conventions
live in `~/Projects/playdate/PLAYDATE-GUIDE.md`; this file is the
Tiles-specific layer. Player-facing instructions are in
[MANUAL.md](MANUAL.md).

Tiles are original 1-bit tile-and-sprite games built the way you'd build
for the NES / Game Boy / C64: a fixed 16px tile grid, code-drawn tilesets
and sprites (no art assets — every tile and sprite is string art in Lua),
and per-game logic on a small shared core.

## Repo layout

```
core/            the shared engine (imported via lib.lua)
games/<name>/    one directory per game (blast, spirit, relic, burrow)
tools/smoke.sh   headless autopilot runner
Makefile         stages core/ + games/<g>/ into build/<g>/source, runs pdc
dist/            prebuilt release .pdx bundles
out/             pdc output (gitignored)
build/           staging + smoke screenshots (gitignored)
```

A build stages `core/*.lua` + `games/<g>/*` into `build/<g>/source` (pdc
wants a single source root), writes `smokeflag.lua`
(`SMOKE_BUILD = false` for release, `true` for `-smoke`), then runs pdc.
Per-game `README.md`, `screenshot.png` and any `*.py` are stripped from
the staged source.

## The engine (`core/`)

16x16 tiles on the 400x240 screen = exactly 25x15 tiles; the house layout
is a 16px HUD row plus a 25x14 playfield. Everything is code-drawn: tiles
are pattern fills + string-art overlays, sprites are string art. Modules
are global tables (the repo convention — `Tiles`, `Map`, `Spr`, `Phys`,
`Kit`, `Cam`, `Snd`, `Util`, `Harness`), pulled in by one `import "lib"`.

- **`tmap.lua` — the tileset and tile map.** `Tiles.def(ch, {solid=,
  kind=, pat=, art=})` registers a tile type by character, prerendering
  it to a 16x16 image once (`pat` is a dither fill from `Tiles.PAT`
  WHITE/LIGHT/MID/DARK/BLACK; `art` overlays pixels — `'#'` black, `'o'`
  white, `'.'` skip). Extra fields (`kind`, `shootthru`, `round`, …) ride
  along on the def for games to query via `Map.def(tx, ty)`. `Map.load(rows,
  ox, oy)` takes an array of strings, one char per tile. `Map.build()`
  renders the whole map ONCE into a background image; `Map.set(tx, ty, ch)`
  repaints just that cell. Static terrain therefore costs one blit per
  frame regardless of complexity (same performance model as Vox).
  Helpers: `Map.get/def/solid`, `Map.tileAt(px,py)`, `Map.cx/cy(t)` (screen
  px center of a tile), `Map.each(fn)`, `Map.count(ch)`.

- **`tspr.lua` — string-art sprites.** `Spr.make(rows)` builds a
  transparent image (`'.'` skip, `'#'` black, `'o'` white); `Spr.makeSet`
  maps a name→rows table to name→image. `Spr.draw(img, x, y, flip)` draws
  centered on (x,y). Palette rule that reads on 1-bit: white player with a
  black outline, dark enemies with a white eye pixel.

- **`tphys.lua` — AABB movement + pathfinding.** Actors are `{x, y}`
  center px with `{hw, hh}` half extents, moved with 1px sub-steps and
  axis separation: `Phys.move(a, dx, dy, isSolid)`. `Phys.moveAssist`
  adds the classic corner nudge (blocked on one axis but nearly aligned
  with an open corridor → slide into alignment). Games pass their own
  `isSolid(tx, ty)` closure to add bombs, doors, water. `Phys.bfs`,
  `Phys.firstStep`, `Phys.descend` are the shared BFS pathfinding used by
  chase AI and every autopilot. `Phys.cell`/`Phys.aligned` are grid
  helpers.

- **`tkit.lua` — shared game scaffolding.** `Kit.title/over/panel/
  text/centered/bigCentered` for HUD and overlay text (cached big text via
  `Kit.bigText`). 2D debris particles (`Kit.burst`/`updateParts`/
  `drawParts`), screen shake (`Kit.shake` + `Kit.updateShake`, then add
  `Kit.sx/Kit.sy` to draw offsets), and `Kit.marker` — the bobbing
  black-outlined white player-locator chevron every avatar game draws last
  (bold-player-visibility rule). `Kit.drawSorted` runs a painter-sorted
  draw list.

- **`tcam.lua` — the camera, for maps bigger than the screen.**
  Everything draws in WORLD coordinates; `Cam.apply()` routes it through
  `gfx.setDrawOffset` (including Kit's shake), `Cam.done()` returns to
  screen space for the HUD. `Cam.follow(wx, wy, dt)` smooth-follows
  (clamped so the map always fills the viewport under the 16px HUD row);
  `Cam.center` snaps on spawns/room entry; `Cam.reset` pins it. Screen-sized
  maps clamp to a fixed camera, so static games ignore it entirely
  (blast/spirit/relic do). See `games/burrow` for the pattern — including
  crank-pans-the-camera, a scrolling-native crank mapping.

- **`tsnd.lua` — synth SFX.** `Snd.play(wave, freq, dur, vol)` over a
  small round-robin synth pool per wave (`square`/`tri`/`saw`/`noise`);
  `Snd.boom(freq, n)` for descending noise sweeps (explosions, deaths).

- **`tutil.lua` — helpers.** `Util.clamp/sign/dist2/choose` and the
  `Util.after(delay, fn)` delayed-call scheduler (drained by
  `Util.runPending(dt)`; `Util.clearPending` on mode resets). NB
  `Util.sign(0) == 0`.

- **`harness.lua` — smoke instrumentation.** A no-op when `SMOKE_BUILD`
  is false, so release builds pay nothing. When on: `Harness.count/set`
  counters, a pcall-wrapped `Harness.frame` that writes runtime errors to
  the `err` datastore, a 90-frame heartbeat to the `smoke` datastore
  (augmented by the game's `Harness.extra(t)`), periodic PNG screenshots
  to `Harness.shotPath`, and the `Harness.autopilot`/`Harness.enabled`
  hooks the game's input module consults.

## Per-game file layout

Each `games/<name>/` mirrors the same shape (copy `blast/` for a single
arena, `relic/` for rooms-as-data with saves):

- `pdxinfo` — name, author, `bundleID=com.sdwfrost.tiles.<name>`, version.
- `config.lua` — the `Config` tunables table (`DT`, level counts, speeds,
  enemy mixes). Smoke builds shorten campaigns: `LEVELS = SMOKE_BUILD and
  2 or 5`.
- `gamestate.lua` — `State` with `State.reset()` (and, for relic,
  datastore `save`/`load`).
- a map/world module — `arena.lua` (single screen: registers tiles,
  builds the arena, spawns enemies) or `world.lua` (rooms-as-data + loader).
- `game.lua` — the update loop, entity logic, enemy AI, scoring, and the
  `Game.autopilot(s)` that drives the same `Input.state` a human does.
- `input.lua` — polls the d-pad / A / B / crank into `Input.state`; when
  `Harness.enabled`, calls `Game.autopilot` instead.
- `draw.lua` — map blit + entities + HUD + mode overlays.
- `main.lua` — `import "lib"` + game modules, `setRefreshRate(SMOKE_BUILD
  and 0 or 30)`, and `playdate.update` wrapping `Harness.frame(frame, ...)`
  around Input.poll → Game.update(Config.DT) → Util.runPending → Draw.frame,
  with rolling `updMs`/`drwMs` timings and the smoke `Harness.extra`.

## Adding a game (checklist)

1. `games/<name>/` with `pdxinfo` (bundleID
   `com.sdwfrost.tiles.<name>`), and the modules above. Copy the shape
   from `games/blast/` (single arena) or `games/relic/` (rooms-as-data +
   saves).
2. Add the name to `GAMES` in the Makefile.
3. `main.lua` boilerplate as above; set `Harness.shotPath =
   ".../tiles/build/<name>-shot.png"` under `playdate.simulator`.
4. Smoke-shorten campaigns in `config.lua`
   (`LEVELS = SMOKE_BUILD and 2 or 5`).
5. Write the autopilot in `game.lua` behind `Harness.enabled`, driving
   `Input.state` through the same paths humans use. Lessons learned here:
   - **Post-win reckless mode** (stop dodging AND stop attacking, stand
     somewhere genuinely lethal) is how one long run exercises win,
     death, and game-over. Check the kill spot has a line of fire — the
     first relic attempt parked in a wall's shadow and lived forever.
   - Walk-to-cell steering must keep pressing toward the cell CENTER on
     arrival: room-edge transitions trigger past the cell edge, and
     stopping on arrival strands the actor in the dead zone.
   - Anything walkable-until-you-leave (dropped bombs) must stay passable
     until the actor's BOX fully clears the tile — center-cell checks
     freeze you straddling the boundary (this bug caused 90 self-kills
     before diagnosis).
6. Verify: `tools/smoke.sh <name> 240 '"wins":[1-9]'` then a
   `'"gameovers":[1-9]'` run. LOOK AT THE SCREENSHOTS — they caught
   unreadable pillars, a key spawned on water, and the stuck-in-the-gap
   bug that counters alone only hinted at.
7. Package: pick a good `build/<name>-shot-<frame>.png` as
   `games/<name>/screenshot.png`, write the README, add a row to the root
   README table and a section to MANUAL.md, `cp -r out/<Title>.pdx dist/`.

## Design notes (learned, user-aligned)

- Palette that reads on 1-bit: LIGHT dithered floors with an etched dot
  per tile, DARK walls with a white top bevel, MID for water/crates,
  white caps on landmarks. Mid-gray pillars vanish against light floors —
  indestructibles want DARK.
- Room/level data as strings, one char per tile; for multi-room games
  define 23x12 INTERIORS and let a loader add the border + standardized
  exit gaps (rows 7-8 / cols 12-13) so rooms always line up. Validate
  string widths at import time — hand-authored rows WILL be off by one.
- Spawn coordinates in data go through `findOpen` (nearest open cell) —
  hand-placed spawns land on trees/water more often than you'd think.
- Performance: whole games measure ~0.1-1ms update + draw in the
  Simulator (30fps budget is 33ms). The bg-image map blit is effectively
  free; don't hand-optimize before measuring.

## The shipped games (one paragraph each)

- **Blast** (`games/blast/`, Bomberman-like) — single-screen bomb-the-maze
  arcade on a fixed 25x14 arena: a hard border, a pillar lattice on
  odd/odd cells, random destructible crates, and a corner pocket kept
  clear for the player. Bombs blast in a cross and chain-detonate; a fresh
  bomb stays walkable until the player's box clears its cell, then hardens.
  Crates can drop B/F/S powerups (more bombs / longer flames / speed).
  Puffs wander, hounds path to the player via `Phys.bfs`. Crank dials the
  fuse length. Five levels.

- **Spirit** (`games/spirit/`, KiKi KaiKai-like) — 4-way talisman shooter
  defending a fixed symmetric shrine courtyard against eight waves of
  yokai. Ghosts drift and float over cover, spitters lob aimed shots,
  dashers wind up and charge. Lanterns are solid cover; ponds block
  walking but talismans (and enemy shots) fly over them — the `shootthru`
  tile flag. Spinning the crank banks a wand sweep that clears everything
  nearby and cancels enemy bullets. Three hearts with generous i-frames.

- **Relic** (`games/relic/`, Zelda-like) — screen-flip action RPG over a
  six-room overworld and a four-room dungeon, defined as 23x12 interior
  strings that a loader borders with standardized exit gaps and doors.
  Sword, key-locked doors, a boomerang (stuns, fetches pickups, flies over
  water), heart containers, and a boss that lumbers at you and calls
  blobs. Crank charges a spin attack. Datastore `save`/`continue` is
  written on every room transition and refills hearts on continue.

- **Burrow** (`games/burrow/`, Boulder-Dash-like) — the first game on the
  `Cam` module: a scrolling 40x28 (640x448) cave, freshly carved each
  time. Rocks and gems live as TILES driven by a bottom-up cellular
  automaton — every move is two `Map.set` dirty repaints. Standing under a
  resting rock is safe (it sits on your helmet), but an object already
  falling when it reaches you is fatal; digging straight down under a rock
  invites it to follow. Bank the gem quota to open the exit before the
  clock runs out. The crank pans the camera to survey the shaft. Three
  caves.
