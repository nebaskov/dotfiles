# dotfiles

This repository uses [GNU Stow](https://www.gnu.org/software/stow/) to symlink configuration files into their expected locations.

## Requirements

On macOS:

```sh
brew install stow
```

Clone this repository to the same path on each machine when possible; Stow creates symlinks that point back to the clone.

## Install

From the repository root, install the regular dotfile packages into your home directory:

```sh
stow -R --target="$HOME" nvim tmux wezterm
```

Install zsh configuration from the nested shell package:

```sh
./shell/setup.sh --dry-run
./shell/setup.sh --backup-existing
```

Equivalent manual Stow command:

```sh
stow -R --dir="$PWD/shell" --target="$HOME" zsh
```

Install Pi extensions and shared agent skills into Pi's global agent directory:

```sh
mkdir -p "$HOME/.pi/agent"
stow -R --target="$HOME/.pi/agent" pi agents
```

Do **not** also stow `agents` into `~/.agents`: Pi scans both `~/.pi/agent/skills` and `~/.agents/skills`, so installing the same skills in both locations causes duplicate skill-name conflicts. If you previously used the old layout, back up and remove the stale copy:

```sh
mv "$HOME/.agents/skills" "$HOME/.agents/skills.backup.$(date +%Y%m%d-%H%M%S)"
```

## Maintenance

After adding, removing, or renaming files in a package, recreate its links with `stow -R`:

```sh
stow -R --target="$HOME" nvim tmux wezterm
stow -R --dir="$PWD/shell" --target="$HOME" zsh
stow -R --target="$HOME/.pi/agent" pi agents
```

To remove a package's symlinks without deleting its files from this repository:

```sh
stow -D --target="$HOME" nvim
```

Use `-n -v` to preview any Stow command before applying it. Existing files at a target path may cause a conflict; move or back them up first.
