# GPU Bandits

A fast arcade dogfight for 2 to 16 pilots over a LAN or the internet, made with Godot 4.
Every mesh is built in code; the only imported assets are the boss model, sounds and a few pictures.

## Modes

**Boss Hunt (co-op).** Everyone flies against the mecha boss, his turrets, missile pods,
point-defence guns and three pink ace jets. There is no time limit: the match ends a few
seconds after the boss goes down. Highest score wins.

**Deathmatch.** Pilots against pilots, 3 lives each, no time limit. The boss is switched off
and stays as scenery and cover. The last pilot still flying wins. Pilots who are out watch
the others (click to switch who you watch).

## Playing

1. Start `GPU Bandits.exe`.
2. The host types a pilot name, picks a port (default 27016) and presses **HOST GAME**.
3. Everyone else types the host's IP address and the same port and presses **JOIN GAME**.
   On a LAN you can leave the IP blank: the game finds a host on the network by itself.
4. In the lobby the host picks the mode (click the MODE line or press TAB), can add bots
   (B / N or the buttons) and presses **START GAME** (or Enter).

Over the internet the host must forward the chosen port (UDP) on their router to their PC
and give the other players their public IP address. Everybody must run the same version.

## Controls

| Action | Keys |
| --- | --- |
| Aim | Mouse (arrow keys or left stick also work), I inverts pitch |
| Lasers | Left mouse / Space / pad A (one click fires a 9-shot volley) |
| Missiles | Right mouse / pad B (one under each wing, each reloads in 2.5 s) |
| Throttle up / slow down | W / S |
| Afterburner | Shift / right trigger |
| Bank | A / D or bumpers (banking turns tighter) |
| Loop | Tap W three times |
| Barrel roll | Double-tap A or D (slides sideways and deflects lasers) |
| Music / fullscreen | M / F11 |
| Leave the match | Esc twice |

## Settings file

`scalper_config.cfg` next to the exe holds every gameplay number (speeds, shield and armour,
weapon stats, boss health, turrets, aces, towers). Edit and save: a running game picks the
change up within a second. In a network match the host's file is used by everybody.

## Command line (optional)

`--name=<pilot>`, `--port=<n>`, `--windowed`, `--host`, `--join=<ip>`, `--mode=boss|dm`,
`--bots=<n>`, `--autostart=<seconds>`. None are needed to play.

## Building from source

Open the folder in Godot 4.7 (Forward+) and export with the "Windows Desktop" preset, or run
`godot --headless --path . --export-release "Windows Desktop" "build/GPU Bandits.exe"`.
