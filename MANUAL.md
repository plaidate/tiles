# Tiles — player's manual

Four original 1-bit games built the NES / Game Boy / C64 way: a fixed
tile grid, code-drawn sprites, and a crank that does something different
in each. No two play alike — this manual has a section per game. Pick one
and dig in.

| Game | Hook | The crank |
| --- | --- | --- |
| [Blast](#blast) | Bomb the maze, trap the beasts | fuse-length dial |
| [Spirit](#spirit) | Hold the shrine against the yokai tide | spin to bank a wand sweep |
| [Relic](#relic) | Sword, keys and boomerang down to the boss | wind up a spin attack |
| [Burrow](#burrow) | Dig deep, bank the gems, mind the rocks | pan the camera to survey |

Every game shows a bobbing chevron over your character so you never lose
yourself in the dither. Press Ⓐ at any title or game-over screen to
begin or continue.

---

## Blast

*Bomb the crates. Trap the beasts. Mind your own fuse.*

A single-screen bomb-the-maze arcade in the Bomberman mold. You start in
one corner of a walled arena studded with indestructible pillars and
packed with destructible crates. Blow your way out, hunt down every
creature on the level, and don't get caught in your own blast. Clear all
five levels to win.

### Controls

- **D-pad** — move (4-way, with corner assist that slides you around
  pillar edges into open corridors)
- **Ⓐ** — drop a bomb
- **Crank** — the fuse dial: crank toward the top (0°) for a hair-trigger
  1.2s fuse, toward the bottom (180°) for a slow 3.6s burn. The current
  setting shows live in the HUD.

### How to play

Bombs detonate in a plus-shaped cross. The flame reaches as far as your
current **flame power** in each direction, stopping at walls, pillars, and
the first crate it burns. Crates take one hit to destroy; walls and
pillars never break. Bombs chain: a flame touching another bomb sets it
off almost instantly, so you can rig cascades.

A freshly dropped bomb is **walkable** — you can step off the tile you
placed it on. The instant your body fully clears that tile, the bomb
turns solid and blocks you (and everyone else) for the rest of its fuse.
Plan your escape route before you drop.

Clear every enemy on a level to advance. Reach the far side of level five
and the arena is yours.

### Scoring, lives and upgrades

- Start with **3 lives**. Touching any enemy, or standing in any flame
  (including your own), costs a life. Lose them all and it's game over.
- **Crates** +10, **powerups** +50, **puff** +100, **hound** +200,
  **level clear** +500.
- Three upgrades **persist across levels but reset when you die**:
  - **B** (bombs) — carry one more bomb at a time, up to 5.
  - **F** (flame) — one more tile of blast reach, up to 6.
  - **S** (speed boots) — move faster, up to 3 pairs.

### Enemies and pickups

- **Puff** — a slow drifter. Wanders the maze, only reversing direction
  when it hits a dead end. Harmless if you keep your distance; herd it
  into a flame.
- **Hound** — the hunter. Most of the time it paths straight toward you
  through the open maze, so you can't just run — you have to cut it off
  with a bomb. Later levels stack more of them.
- **Powerups (B / F / S)** — dropped from about a third of destroyed
  crates. Walk over one to grab it. Careful: a powerup sitting in a flame
  burns up before you can reach it.

### Tips

- Set a **short fuse** when you're bombing a crate right next to you and
  can dart away; set a **long fuse** to lay a trap ahead of a hound and
  lead it in.
- You can only escape a bomb through a tile that stays open — remember it
  hardens the moment you leave it, so never bomb yourself into a pocket.
- Chain bombs to clear a wall of crates in one go, but a chain covers a
  lot of floor: give yourself two tiles of clearance.
- Hounds path to your current cell. Drop a bomb, step around a pillar,
  and let the hound walk into the tile you just left.
- Grab **F** early — longer flames make every later bomb safer to place
  because you can trigger crates and enemies from further away.
- The corner pocket you spawn in is always clear; retreat there to
  regroup when a level gets crowded.

---

## Spirit

*Talismans against the yokai tide. Spin the wand when they close in.*

A 4-way shrine-defense shooter in the KiKi KaiKai / Pocky & Rocky mold.
You're a shrine maiden holding a fixed courtyard against eight escalating
waves of yokai that pour in from all four edges. Throw talismans, weave
between the stone lanterns, and bank the crank when you're swarmed to
sweep the whole courtyard clean.

### Controls

- **D-pad** — move (8-way). Your talismans fly in the direction you last
  walked along a single axis (4-way aiming), shown by the wand tip.
- **Ⓐ** — throw a talisman (hold to autofire)
- **Crank** — spin it (either direction) to fill the SPIN meter in the
  HUD; at a full wind it **releases a wand sweep automatically**, killing
  every yokai within range and wiping out enemy shots around you.

### How to play

Enemies spawn a few at a time and briefly flicker in before they can hurt
you or be hit. Line up on the same row or column as a yokai and fire — a
talisman travels until it hits an enemy, a wall, or a lantern. Keep
moving: everything on the field is trying to reach you.

The **wand sweep** is your panic button. It costs a full crank wind, so
spin steadily between threats to keep it charged and save the release for
when enemies (or a wall of bullets) get close.

Clear every yokai in a wave — including the ones still queued to spawn —
to move on. Survive all eight waves to bring the shrine peace.

### Scoring and lives

- **3 hearts**. A hit costs one heart and grants a long stretch of
  invincibility (you flash while it lasts). Lose all three and it's game
  over.
- **Ghost** +100, **dasher** +150, **spitter** +200, **wave clear** +250.

### Enemies and terrain

- **Ghost** — drifts steadily toward you with a side-to-side wobble, and
  **floats over lanterns and ponds** so cover won't stop it. Dies in one
  hit. The bulk of every wave.
- **Spitter** — sits back and lobs an aimed shot at you on a timer. Takes
  **two hits**. Its shots stop on lanterns but sail over ponds, so put a
  lantern between you and it.
- **Dasher** — winds up in place, then charges in a straight line at high
  speed before resetting. One hit to kill, but hard to hit mid-charge —
  strike during the wind-up or sidestep and punish after.
- **Lanterns** — solid stone cover. They block you, block enemy shots,
  and block your talismans, but ghosts float over them.
- **Ponds** — block walking, but **everything shoots across them** (yours
  and theirs). Good for lining up a shot you can't be charged through.

### Tips

- **Advance-fire:** the game already lines you up and shoots as you close
  the last of the gap — hold Ⓐ and press toward a yokai on its axis.
- Keep the crank turning during lulls so the sweep is ready the instant a
  wave crests. A sweep also deletes incoming bullets, so it doubles as a
  bullet-clear.
- Fight near lanterns to break spitter lines of fire, but never against a
  lantern you can be pinned against by a dasher.
- Ghosts ignore cover — deal with the drifting swarm by backpedaling in a
  circle and firing behind you, rather than trying to hide.
- After a hit, use your invincibility window aggressively: wade in and
  clear the densest cluster while you can't be hurt.

---

## Relic

*Sword, keys, boomerang. The relic sleeps below the hills.*

A screen-flip action RPG in the Zelda mold. Explore an overworld of six
linked rooms, find the key hidden among the ponds, unlock the dungeon
mouth in the hills, and descend four floors to the boss and the Relic it
guards. The game saves as you go, so you can put it down and continue
later.

### Controls

- **D-pad** — move; walk off an edge gap to flip to the next room
- **Ⓐ** — sword stab (at the title screen: start a **new quest**)
- **Ⓑ** — throw the boomerang, once you've found it (at the title screen:
  **continue** a saved quest)
- **Crank** — wind it to charge a **spin attack**; it releases on a full
  wind, hitting everything around you for double damage

To open a **locked door**, walk into it while holding at least one key.

### How to play

The world is a 3x2 grid of overworld rooms above and a 4-room dungeon
below, connected by edge gaps, a dungeon mouth (stairs), and locked
doors. Each screen holds its own enemies and any pickups you haven't
already collected.

Your **sword** stabs in the direction you're facing, with a short cooldown
— tap and reposition rather than mashing. The **boomerang** flies out and
returns, stunning enemies it passes, fetching pickups back to you, and
flying over water. The **spin attack** is your crank-charged panic move
for when you're surrounded.

The quest route: grab the **key** hidden among the overworld ponds, open
the dungeon door in the north-east hills, take the stairs down, find a
**second key** in the dungeon, unlock the boss door, beat the boss, and
claim the **Relic**.

### Health and saving

- You start with **3 hearts**; a **heart container** in the north-west
  overworld rocks raises your maximum (up to 5). Slain blobs sometimes
  drop a single refill heart.
- A hit costs a heart, flashes you invincible briefly, and knocks you
  back away from what hit you. Lose all hearts and you fall — continue to
  try again.
- The game **saves at every room transition**. "Continue" from the title
  resumes exactly where you were, with your hearts refilled.

### Enemies, items and terrain

- **Blob** — wanders in short random hops; one hit. Can drop a refill
  heart.
- **Skeleton** — periodically re-aims and lunges toward you, bouncing off
  walls; takes **two hits**.
- **Sentry (shooter)** — stationary, fires an aimed shot on a timer;
  **two hits**. Its shots stop on walls but fly over water.
- **Boss** — lumbers straight at you and summons blobs (up to two at a
  time). Sword it down through the chip damage; the spin attack and
  boomerang help control its minions.
- **Key** — opens one locked door (doors open together with their
  neighbors). **Boomerang** — the dungeon-fetching, enemy-stunning item.
  **Heart container** — raises max hearts. **Relic** — the goal.
- **Water** blocks walking but the boomerang (and enemy shots) fly over
  it. **Trees, rocks and walls** are solid.

### Tips

- **Hit and run:** stab, then back off while the sword recovers — the
  autopilot lives by this and so should you, especially against
  skeletons.
- Keep the crank charged so a spin is ready whenever two enemies close in
  at once.
- The boomerang **stuns** — throw it into a knot of enemies to freeze
  them, then wade in with the sword. It also drags distant pickups (and
  that dungeon key) to you across water.
- Explore the overworld fully before descending: the heart container in
  the north-west rocks makes the dungeon far more survivable.
- You can't out-trade the sentries in the open — approach them behind
  cover or stun them with the boomerang first.
- Because it saves on every room change, stepping back through a doorway
  to bank progress before a risky room is a legitimate tactic.

---

## Burrow

*Dig deep, bank the gems, never stand under a rock.*

A scrolling Boulder-Dash-style digger, and the only Tiles game with a
camera that roams — the cave is far bigger than the screen. Tunnel
through the dirt, collect enough gems to open the exit, and respect
gravity: everything you undermine falls. Three freshly-carved caves.

### Controls

- **D-pad** — dig / walk one cell at a time; push a rock sideways into an
  open cell by walking into it
- **Crank** — pan the camera up and down to survey the shaft ahead; it
  springs back to your miner when you let go
- **Ⓐ** — start / continue

### How to play

You move on a grid, one cell per press, carving away dirt as you go. The
cave is a 640x448 field of dirt, open tunnel, steel walls (indestructible
border), rocks, and gems. The camera follows you; crank to peek up or
down a shaft before you commit to a dig.

**Gravity runs the hazards.** Rocks and gems sit still on dirt or on
another object, but the moment the cell below them is empty they fall,
one cell per tick, and roll off the shoulders of rounded piles into open
gaps beside them. Collect the gem quota shown in the HUD to open the exit
door, then reach it before the timer hits zero.

The key rule: **standing directly under a resting rock is safe** — it
balances on your helmet. But an object that is **already falling** when it
reaches your head is fatal. So digging straight down beneath a rock is a
trap: it drops into the space you just vacated and lands on you.

### Scoring, lives and the clock

- **3 lives**. Being crushed by a falling rock or gem, or running out of
  time, costs a life and re-cuts the same cave fresh. Lose them all for
  game over.
- **Gem** +25, **cave clear** +250 plus a **time bonus** equal to the
  seconds left. Each of the three caves needs more gems than the last.
- **200 seconds** per cave.

### Hazards and objects

- **Dirt** — dig straight through it; this is how you carve tunnels.
- **Rock** — falls when undermined, rolls off rounded piles, and can be
  shouldered one cell sideways into empty space. Lethal only while
  falling.
- **Gem** — collect for the quota; **falls and kills exactly like a
  rock** if it drops onto you. Don't grab a gem that's mid-fall.
- **Steel wall** — the indestructible cave border.
- **Exit door** — sealed until you've banked the gem quota, then it opens
  and you head for it.

### Tips

- Before digging under anything, **crank up** to check what's stacked
  overhead — a single peek saves a life.
- To clear a rock safely, dig a cell **beside and below** it and shoulder
  it sideways, or tunnel around rather than straight down.
- Undermining a rock on purpose lets you drop it into a pit to clear a
  path — just be somewhere else when it lands.
- Gems dislodged from a pile fall too; wait for a tumbling cluster to
  settle before you walk in to collect.
- Watch the clock on later caves: the gem quota climbs, so plan an
  efficient route and cash the time bonus for a big score.
- A rock resting on your helmet won't hurt you — but the moment you step
  out from under it, it falls, so step to a cell that isn't beneath
  anything else.
