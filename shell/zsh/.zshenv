# Managed by dotfiles/shell/zsh.
# zsh reads this for every invocation; keep it fast and side-effect free.

if [ -r "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

if [ -r "$HOME/.zshenv.local" ]; then
  . "$HOME/.zshenv.local"
fi
