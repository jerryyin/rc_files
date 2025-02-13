#zmodload zsh/zprof

# Environments tmux depend on
export TERM=xterm-256color
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# TMUX
# # If not running interactively, do not do anything
# # This configuration allows multiple tmux sessions
#[[ $- != *i* ]] && return
#[[ -z "$TMUX" ]] && exec tmux -2u || :

# This configuration allows attaching to one base session
# https://unix.stackexchange.com/questions/16237/why-might-tmux-only-be-capable-of-attaching-once-per-shell-session
if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [[ $- == *i* ]]; then
  base_session=$(whoami)
  if ! tmux has-session -t "$base_session" 2>/dev/null; then
    tmux -2u new-session -d -s "$base_session"
  fi
  tmux -2u attach-session -t "$base_session"
fi

# Load p10k instant promopt
if [[ -r "$HOME/.p10k-lean.zsh" ]]; then
  source "$HOME/.p10k-lean.zsh"
fi

# Load Zinit
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
ZINIT_BIN_DIR="$CACHE_DIR/zinit/bin"
if [[ ! -d $ZINIT_BIN_DIR ]]; then
    command mkdir -p $ZINIT_BIN_DIR
    command git clone https://github.com/zdharma-continuum/zinit $ZINIT_BIN_DIR --depth=1
fi
source "$ZINIT_BIN_DIR/zinit.zsh"

#----------------------------------------------
# Plugin section

# Load essential plugins immediately

zinit ice depth=1
zinit light romkatv/powerlevel10k

zinit light zdharma-continuum/fast-syntax-highlighting

zinit ice depth=1 lucid
zinit light jeffreytse/zsh-vi-mode

# Critical plugins required for core functionality

zinit ice wait'0' depth=1 lucid
zinit light zsh-users/zsh-autosuggestions

zinit ice wait'0' depth=1 lucid
zinit light zsh-users/zsh-history-substring-search
typeset -g HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# Important but not immediate

zinit ice wait'1' depth=1 lucid
zinit light zsh-users/zsh-completions

zinit ice wait'1' as"completion" lucid
zinit snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker

# Optional Plugins
zinit ice wait'2' depth=1 lucid
zinit light amyreese/zsh-titles

zinit ice wait'2' depth=1 lucid
zinit light hlissner/zsh-autopair

# Color
zinit ice wait'2' depth=1 lucid
zinit snippet OMZP::colorize

zinit ice wait'2' depth=1 lucid
zinit snippet OMZP::colored-man-pages

# Utility
zinit ice wait'2' depth=1 lucid
zinit snippet OMZP::command-not-found

# marks, mark/unmark + <markname>, jump + <markname>
zinit ice wait'2' depth=1 lucid
zinit snippet OMZP::jump

# extract + <archive>
# Since this is the last plugin, do compoinit for auto completion
zinit ice wait'2' depth=1 lucid atinit="zicompinit; zicdreplay"
zinit snippet OMZP::extract

#----------------------------------------------
# Configuration and Alias
# Configure zsh options
setopt extended_glob
setopt append_history
setopt inc_append_history
setopt hist_ignore_space
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_expire_dups_first
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_reduce_blanks
setopt hist_verify
setopt share_history
HISTFILE=~/.zsh_history
SAVEHIST=10000
HISTSIZE=10000

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias vi='vim'
# From OMZP::colorize
alias cat='ccat'

UP_ARROW=''
DOWN_ARROW=''
LEFT_ARROW=''
RIGHT_ARROW=''
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  alias ls='ls -G'
  UP_ARROW='^[[A'
  DOWN_ARROW='^[[B'
  LEFT_ARROW='b'
  RIGHT_ARROW='f'
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntu or other Linux distributions
  # Use showkey -a (provided by kbd) for escape sequence
  alias ls='ls --color'
  UP_ARROW='OA'
  DOWN_ARROW='OB'
  LEFT_ARROW='[1;3D'
  RIGHT_ARROW='[1;3C'
fi

# Override default bindings for zsh-vi-mode
function zvm_before_init() {
  zvm_bindkey viins $UP_ARROW history-substring-search-up
  zvm_bindkey viins $DOWN_ARROW history-substring-search-down
  zvm_bindkey viins $RIGHT_ARROW forward-word
  zvm_bindkey viins $LEFT_ARROW backward-word

  zvm_bindkey vicmd $UP_ARROW history-substring-search-up
  zvm_bindkey vicmd $DOWN_ARROW history-substring-search-down
  zvm_bindkey vicmd $RIGHT_ARROW forward-word
  zvm_bindkey vicmd $LEFT_ARROW backward-word

  # Only tested in xterm
  zvm_bindkey viins "^[^?" backward-kill-word
}

# zsh-history-substring-search
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Enable Emacs mapping in edit mode
bindkey -e

#----------------------------------------------
# Custom settings unrelated with zsh
#
export LESS="-XFR"

alias dockrun='sudo docker run -it --network=host --device=/dev/kfd --device=/dev/dri --group-add video --cap-add=SYS_PTRACE --security-opt seccomp=unconfined --name zyin-$(date "+%m%d") -h $(date "+%m%d") -v /data:/data -v $HOME:/zyin'

# Function to set the COMPOSE_PROJECT_NAME if not already set
function set_compose_project_name() {
  local DATE=$(date "+%m%d")
  local TIME=$(date "+%H%M")
  local SERVICE=""

  # Check if a custom project name is provided as an argument
  if [ -n "$1" ]; then
    SERVICE="$1"
  fi

  export COMPOSE_PROJECT_NAME="${USER}-${SERVICE}-${DATE}-${TIME}"
}

# Function to set Docker Compose file and ensure COMPOSE_PROJECT_NAME is set
function dcompose() {
  set_compose_project_name "$@[-1]"
  docker compose -f ~/.docker/docker-compose.yml "$@"
}

# Function to bring up Docker services in detached mode
function drun() {
  local CONTAINER_NAME="zyin-tools-setup"

  # Check if the container exists and remove it if necessary
  if docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing container: ${CONTAINER_NAME}"
    docker rm -f "${CONTAINER_NAME}"
  fi

  # Generate a unique project name and bring up the service
  dcompose up -d --no-build "$1"
}

# Function to build Docker services with a dynamic project name
function dbuild() {
  dcompose build "$@"
}

export CLICOLOR_FORCE=1
export NODE_TLS_REJECT_UNAUTHORIZED=0

function export_iree_tools() {
  local BUILD_DIR="${1:-$HOME/iree/build}"
  local SYMLINK="$BUILD_DIR/compile_commands.json"

  if [[ ! -L "$SYMLINK" ]]; then
    return
  fi

  # Resolve the symlink target
  local TARGET
  TARGET=$(readlink "$SYMLINK")

  # Extract the directory containing compile_commands.json
  local BUILD_TYPE_DIR
  BUILD_TYPE_DIR=$(dirname "$TARGET")

  # Ensure it's a valid directory
  if [[ -d "$BUILD_TYPE_DIR/tools" ]]; then
    export PATH="$BUILD_TYPE_DIR/tools:$PATH"
  fi
  
}
export_iree_tools

#zprof
