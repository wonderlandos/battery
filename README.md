# Battery Care

How worn the battery is, and a reminder to unplug at the charge you choose.

- **Desktop card:** health (what the battery holds now against what it was made for), in watt-hours, and the charge cycles.
- **Menu bar item:** a battery icon; while the battery charges at or above the chosen charge (80% unless you change it)
  it says **Unplug** and posts one notification per charge. Click it for the details, the charge (60 to 100%, in steps
  of 5) and the reminder switch. Settings are kept in the plugin's own state.
- **Asks for:** `run` (`wol battery --json`, a Read helper verb) and `notifications` (the reminder).
- Without a battery it says so and does nothing else.
- **Files:** `plugin.toml`, `bar.lua`, `card.lua`, `icon.png`, `preview.webp`.

## Install

From the Store: **Plugins**, then **Get** on Battery Care. From a release: `wol plugin add wonderlandos.battery-1.0.wolplug --yes` (a file the index did not sign is marked
unreviewed), then `wol plugin enable wonderlandos.battery`.

## Tests

`.tests/case-*.json` are runs of the scripts in the WolOS plugin runtime (wol-lua, the shell's sandbox and Lua API) with
fixture answers for `wol.run`: nothing on the machine runs. Each case lists the steps (render, popover, click, change,
query) and the text the result must and must not contain; the runner (`plugtest`, wol-lua with fixture services) is
not published yet. `wol plugin check` on a copy of the folder named after the id is the lint.

## Release

`.github/workflows/hub-release.yml` turns a pushed tag `v<plugin.toml version>` (`v1.0`) into a GitHub release with
`wonderlandos.battery-<version>.wolplug`, checked by the hub's own hubcheck first (wonderlandos/hub `wol-release.yml`, pinned).

Licence: GPL-2.0-or-later.
