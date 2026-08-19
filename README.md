# dotfiles

This repository uses [GNU Stow](https://www.gnu.org/software/stow/) to symlink configuration files into their expected locations.

Install Stow (on macOS):

```sh
brew install stow
```

From the repository root, install the regular dotfile packages into your home directory:

```sh
stow --target="$HOME" nvim tmux wezterm
```

The agent-related packages use different target directories:

```sh
mkdir -p "$HOME/.pi/agent" "$HOME/.agents"
stow --target="$HOME/.pi/agent" pi
stow --target="$HOME/.agents" agents
```

After adding, removing, or renaming files in a package, recreate its links with `stow -R`:

```sh
stow -R --target="$HOME" nvim tmux wezterm
```

To remove a package's symlinks without deleting its files from this repository:

```sh
stow -D --target="$HOME" nvim
```

Use `-n -v` to preview any Stow command before applying it. Existing files at a target path may cause a conflict; move or back them up first.
