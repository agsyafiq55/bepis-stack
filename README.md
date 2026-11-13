```
██████╗ ███████╗██████╗ ██╗███████╗       ███████╗████████╗ █████╗  ██████╗██╗  ██╗
██╔══██╗██╔════╝██╔══██╗██║██╔════╝       ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝
██████╔╝█████╗  ██████╔╝██║███████╗█████╗ ███████╗   ██║   ███████║██║     █████╔╝
██╔══██╗██╔══╝  ██╔═══╝ ██║╚════██║╚════╝ ╚════██║   ██║   ██╔══██║██║     ██╔═██╗
██████╔╝███████╗██║     ██║███████║       ███████║   ██║   ██║  ██║╚██████╗██║  ██╗
╚═════╝ ╚══════╝╚═╝     ╚═╝╚══════╝       ╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
```

My Claude Code CLI setup: settings, status line, skills, commands, agents, output styles, hooks and plugins. One command sets up a new machine.

## Quickstart

```bash
git clone https://github.com/agsyafiq55/bepis-stack.git ~/Projects/bepis-stack
cd ~/Projects/bepis-stack
./install.sh
```

Or without cloning first (it clones to `~/Projects/bepis-stack`, override with `BEPIS_DIR`):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/agsyafiq55/bepis-stack/main/install.sh)
```

Flags: `--dry-run` (show actions only), `--no-plugins` (skip plugin installs).

## How it works

`claude/` mirrors `~/.claude`, and **this repo is the source of truth**: change things here (usually by asking Claude Code in a session), then run `./install.sh` or `scripts/sync.sh` to copy them into `~/.claude`. Nothing is symlinked, so settings Claude Code writes itself (like the model picked with `/model`) stay on the machine and never dirty the repo.

How files are copied:
- Directories (`skills/`, `commands/`, ...): repo files are copied over; files that exist only on the machine are left alone. Nothing is ever deleted, so removing something from the repo does not remove it from `~/.claude`.
- `settings.json`: deep-merged. Repo values win; keys only the machine has (e.g. `model`) are kept. Keep machine-specific keys out of the repo file.
- Anything that would be overwritten is backed up to `~/.claude/backups/bepis-<timestamp>/` first.

Credentials, history, sessions, projects and the plugin cache are never touched.

```
claude/
  settings.json          model, theme, status line, permissions, hooks
  statusline/            status line scripts (usage meter)
  skills/                <name>/SKILL.md per skill
  commands/              custom slash commands (*.md)
  agents/                custom subagents (*.md)
  output-styles/         output style mods
  hooks/                 scripts referenced by hooks in settings.json
plugins/plugins.txt      marketplaces + plugins to install
scripts/
  deps.sh                install git, jq, claude CLI if missing
  sync.sh                copy claude/* into ~/.claude (merge settings.json)
  plugins.sh             add marketplaces, install plugins
  doctor.sh              check links, tools, settings, status line
```

## Status line

`claude/statusline/statusline.sh` shows model, folder, a context-usage meter (green under 60%, yellow under 85%, red above), token totals and session cost:

```
[Opus 5.5] bepis-stack | ctx ████░░░░░░ 42% | tokens in:12000 out:3400 | $0.01
```

## Adding things

- **Skill**: create `claude/skills/<name>/SKILL.md`, then run `scripts/sync.sh`.
- **Slash command / agent / output style**: drop a `.md` file into the matching folder, then sync.
- **Plugin**: add `plugin <name>@<marketplace>` to `plugins/plugins.txt`, then run `scripts/plugins.sh`.
- **New top-level item in `~/.claude`** (e.g. `CLAUDE.md`, `keybindings.json`): put it in `claude/` and sync.

Run `scripts/doctor.sh` any time to check `~/.claude` matches the repo.
