# Tiles

Original 1-bit tile-and-sprite games for the Playdate, built the way you
would build for the NES, Game Boy, or C64: a fixed 16px tile grid,
code-drawn tilesets and sprites, and per-game logic on a small shared
core. No art assets — every tile and sprite is string art in Lua.

| Game | One-liner | Crank |
| --- | --- | --- |
| [Blast](games/blast/) | Bomb the maze, trap the beasts (Bomberman-like) | fuse-length dial |
| [Spirit](games/spirit/) | 4-way talisman shooter vs yokai waves (KiKi KaiKai-like) | spin to bank a wand sweep |
| [Relic](games/relic/) | Screen-flip action RPG: keys, dungeon, boss (Zelda-like) | wind up a spin attack |
| [Burrow](games/burrow/) | Scrolling Boulder-Dash-style digger on a 640x448 cave | pan the camera to survey |

Prebuilt games are in `dist/` — copy a `.pdx` onto your Playdate (or open
it in the Simulator) and play.

## Building

Requires the [Playdate SDK](https://play.date/dev/) (`pdc` on PATH).

```sh
make blast          # build one game -> out/Blast.pdx
make all            # build everything
tools/smoke.sh blast 240 '"wins":[1-9]'   # headless autopilot test
```

Engine internals and the development workflow: [DEVELOPING.md](DEVELOPING.md).

MIT licensed.
