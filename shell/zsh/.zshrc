# Managed by dotfiles/shell/zsh.

path_prepend() {
  [ -d "$1" ] || [ -L "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1${PATH:+:$PATH}" ;;
  esac
}

path_append() {
  [ -d "$1" ] || [ -L "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="${PATH:+$PATH:}$1" ;;
  esac
}

path_prepend "$HOME/bin"
path_prepend "/usr/local/bin"
path_prepend "/opt/homebrew/bin"
path_prepend "/opt/homebrew/opt/openjdk/bin"
path_prepend "/opt/homebrew/opt/postgresql@11/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/clickhouse"
path_prepend "$HOME/.local/share/nvim/mason/bin"
path_prepend "$HOME/.cargo/bin"
path_append "$HOME/.docker/bin"
export PATH

export LANG="${LANG:-en_US.UTF-8}"
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export DOCKER_DEFAULT_PLATFORM="${DOCKER_DEFAULT_PLATFORM:-linux/amd64}"

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="${ZSH_THEME:-gozilla}"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

if [ -r "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit
fi

alias v="nvim"

# Yandex Cloud CLI.
[ -r "$HOME/yandex-cloud/path.bash.inc" ] && source "$HOME/yandex-cloud/path.bash.inc"
[ -r "$HOME/yandex-cloud/completion.zsh.inc" ] && source "$HOME/yandex-cloud/completion.zsh.inc"

# Nebius CLI.
[ -r "$HOME/.nebius/path.zsh.inc" ] && source "$HOME/.nebius/path.zsh.inc"

# Homebrew nvm with a fallback to ~/.nvm.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
for nvm_script in "/opt/homebrew/opt/nvm/nvm.sh" "$NVM_DIR/nvm.sh"; do
  if [ -s "$nvm_script" ]; then
    source "$nvm_script"
    break
  fi
done
unset nvm_script

for nvm_completion in "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" "$NVM_DIR/bash_completion"; do
  if [ -s "$nvm_completion" ]; then
    source "$nvm_completion"
    break
  fi
done
unset nvm_completion

# Conda, if installed.
if [ -x "$HOME/miniconda3/bin/conda" ]; then
  __conda_bin="$HOME/miniconda3/bin/conda"
elif [ -x "/opt/homebrew/Caskroom/miniconda/base/bin/conda" ]; then
  __conda_bin="/opt/homebrew/Caskroom/miniconda/base/bin/conda"
fi

if [ -n "${__conda_bin:-}" ]; then
  __conda_setup="$("$__conda_bin" shell.zsh hook 2>/dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    __conda_prefix="${__conda_bin%/bin/conda}"
    if [ -r "$__conda_prefix/etc/profile.d/conda.sh" ]; then
      source "$__conda_prefix/etc/profile.d/conda.sh"
    else
      path_prepend "$__conda_prefix/bin"
      export PATH
    fi
  fi
fi
unset __conda_bin __conda_prefix __conda_setup

# Micromamba, if installed.
if command -v micromamba >/dev/null 2>&1; then
  export MAMBA_EXE="${MAMBA_EXE:-$(command -v micromamba)}"
elif [ -x "/opt/homebrew/bin/micromamba" ]; then
  export MAMBA_EXE="${MAMBA_EXE:-/opt/homebrew/bin/micromamba}"
fi

if [ -n "${MAMBA_EXE:-}" ]; then
  export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-$HOME/micromamba}"
  __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2>/dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
  else
    alias micromamba="$MAMBA_EXE"
  fi
fi
unset __mamba_setup

if [ -r "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi
