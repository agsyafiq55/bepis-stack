# bepis-stack

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

`claude/` mirrors `~/.claude`. The installer symlinks each top-level entry in it into `~/.claude`, so edits made on the machine (including ones Claude Code writes itself, like `/model` saving a default) show up as git diffs here. Anything already in `~/.claude` that would be replaced is moved to `~/.claude/backups/bepis-<timestamp>/` first.

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
  link.sh                symlink claude/* into ~/.claude
  plugins.sh             add marketplaces, install plugins
  doctor.sh              check links, tools, settings, status line
```

## Status line

`claude/statusline/statusline.sh` shows model, folder, a context-usage meter (green under 60%, yellow under 85%, red above), token totals and session cost:

```
[Opus 5.5] bepis-stack | ctx ████░░░░░░ 42% | tokens in:12000 out:3400 | $0.01
```

## Adding things

- **Skill**: create `claude/skills/<name>/SKILL.md` (or `claude plugin init <name>`, which writes into the linked `~/.claude/skills`).
- **Slash command / agent / output style**: drop a `.md` file into the matching folder.
- **Plugin**: add `plugin <name>@<marketplace>` to `plugins/plugins.txt`, then run `scripts/plugins.sh`.
- **New top-level item in `~/.claude`** (e.g. `CLAUDE.md`, `keybindings.json`): put it in `claude/` and run `scripts/link.sh`.

Run `scripts/doctor.sh` any time to check everything is wired up.
