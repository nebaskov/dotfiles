#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: shell/setup.sh [options] [SHELL]

Stow the zsh package from this repository and optionally make it the login shell.

Options:
  --shell SHELL       Shell binary or name to set (default: zsh from PATH)
  --no-chsh           Only stow config; do not change the login shell
  --skip-omz          Do not install Oh My Zsh or its plugins
  --backup-existing   Move existing ~/.zshenv, ~/.zprofile, ~/.zshrc aside first
  -n, --dry-run       Preview actions and run Stow in simulation mode
  -h, --help          Show this help

Examples:
  shell/setup.sh --dry-run
  shell/setup.sh --backup-existing --shell /opt/homebrew/bin/zsh
EOF
}

log() {
  printf '==> %s\n' "$*"
}

run() {
  if (( DRY_RUN )); then
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
TARGET_HOME="${HOME:?HOME is not set}"
PACKAGE="zsh"
REQUESTED_SHELL=""
CHANGE_SHELL=1
INSTALL_OMZ=1
BACKUP_EXISTING=0
DRY_RUN=0

while (($#)); do
  case "$1" in
    --shell)
      [[ $# -ge 2 ]] || { echo "--shell requires a value" >&2; exit 2; }
      REQUESTED_SHELL="$2"
      shift 2
      ;;
    --no-chsh)
      CHANGE_SHELL=0
      shift
      ;;
    --skip-omz)
      INSTALL_OMZ=0
      shift
      ;;
    --backup-existing)
      BACKUP_EXISTING=1
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$REQUESTED_SHELL" ]]; then
        echo "Unexpected argument: $1" >&2
        usage >&2
        exit 2
      fi
      REQUESTED_SHELL="$1"
      shift
      ;;
  esac
done

if (($#)); then
  echo "Unexpected argument: $1" >&2
  usage >&2
  exit 2
fi

resolve_shell() {
  local requested="$1"
  local resolved=""

  if [[ -z "$requested" ]]; then
    requested="zsh"
  fi

  if [[ "$requested" == */* ]]; then
    resolved="$requested"
  else
    resolved="$(command -v "$requested" || true)"
  fi

  if [[ -z "$resolved" || ! -x "$resolved" ]]; then
    echo "Shell '$requested' was not found or is not executable" >&2
    exit 1
  fi

  local resolved_dir
  resolved_dir="$(cd "$(dirname "$resolved")" && pwd -P)"
  printf '%s/%s\n' "$resolved_dir" "$(basename "$resolved")"
}

install_oh_my_zsh() {
  (( INSTALL_OMZ )) || return 0

  if [[ ! -d "$TARGET_HOME/.oh-my-zsh" ]]; then
    log "installing Oh My Zsh"
    if ! command -v curl >/dev/null 2>&1; then
      echo "curl is required to install Oh My Zsh" >&2
      exit 1
    fi
    if (( DRY_RUN )); then
      echo '+ RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    else
      RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
  fi

  local custom_dir="${ZSH_CUSTOM:-$TARGET_HOME/.oh-my-zsh/custom}"
  run mkdir -p "$custom_dir/plugins"

  clone_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git" "$custom_dir/plugins/zsh-autosuggestions"
  clone_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$custom_dir/plugins/zsh-syntax-highlighting"
}

clone_plugin() {
  local name="$1"
  local url="$2"
  local dest="$3"

  if [[ -d "$dest/.git" || -e "$dest" ]]; then
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "git is required to install $name" >&2
    exit 1
  fi

  log "installing Oh My Zsh plugin $name"
  run git clone --depth=1 "$url" "$dest"
}

backup_existing_dotfiles() {
  (( BACKUP_EXISTING )) || return 0

  local stamp backup_dir rel src dest
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup_dir="$TARGET_HOME/.dotfiles-backup/$stamp"

  for rel in .zshenv .zprofile .zshrc; do
    src="$TARGET_HOME/$rel"
    [[ -e "$src" || -L "$src" ]] || continue

    # Stow can manage existing symlinks; only move real files/directories.
    [[ ! -L "$src" ]] || continue

    dest="$backup_dir/$rel"
    log "backing up $src to $dest"
    run mkdir -p "$(dirname "$dest")"
    run mv "$src" "$dest"
  done
}

stow_zsh() {
  if ! command -v stow >/dev/null 2>&1; then
    echo "GNU Stow is required. Install it with: brew install stow" >&2
    exit 1
  fi

  local stow_args=(-R -v --dir="$SCRIPT_DIR" --target="$TARGET_HOME")
  if (( DRY_RUN )); then
    stow_args=(-n "${stow_args[@]}")
  fi

  log "stowing $PACKAGE package into $TARGET_HOME"
  if ! stow "${stow_args[@]}" "$PACKAGE"; then
    cat >&2 <<EOF

Stow reported conflicts. If the conflicting zsh files should be replaced by
this repo, rerun with --backup-existing, or resolve them manually and retry.
EOF
    exit 1
  fi
}

ensure_shell_allowed() {
  local shell_path="$1"

  [[ -r /etc/shells ]] || return 0
  if grep -qxF "$shell_path" /etc/shells; then
    return 0
  fi

  log "adding $shell_path to /etc/shells"
  if (( DRY_RUN )); then
    echo "+ echo '$shell_path' | sudo tee -a /etc/shells >/dev/null"
  else
    echo "$shell_path" | sudo tee -a /etc/shells >/dev/null
  fi
}

set_login_shell() {
  local shell_path="$1"

  (( CHANGE_SHELL )) || return 0

  if [[ "${SHELL:-}" == "$shell_path" ]]; then
    log "login shell is already $shell_path"
    return 0
  fi

  ensure_shell_allowed "$shell_path"
  log "changing login shell to $shell_path"
  run chsh -s "$shell_path"
}

main() {
  local shell_path
  shell_path="$(resolve_shell "$REQUESTED_SHELL")"

  log "repo root: $REPO_ROOT"
  log "target home: $TARGET_HOME"
  log "requested shell: $shell_path"

  install_oh_my_zsh
  backup_existing_dotfiles
  stow_zsh
  set_login_shell "$shell_path"
}

main "$@"
