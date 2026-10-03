# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/nikolya/.docker/bin"
# End of Docker Desktop section.

# Managed by dotfiles/shell/zsh.
# Login-shell only configuration.

docker_bin="$HOME/.docker/bin"
if [ -d "$docker_bin" ]; then
  case ":$PATH:" in
    *":$docker_bin:"*) ;;
    *) export PATH="$PATH:$docker_bin" ;;
  esac
fi
unset docker_bin

if [ -r "$HOME/.zprofile.local" ]; then
  . "$HOME/.zprofile.local"
fi
