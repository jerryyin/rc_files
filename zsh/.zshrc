#zmodload zsh/zprof

# TMUX
# # If not running interactively, do not do anything
# # This configuration allows multiple tmux sessions
#[[ $- != *i* ]] && return
#[[ -z "$TMUX" ]] && exec tmux -2u || :

# This configuration allows attaching to one base session
# https://unix.stackexchange.com/questions/16237/why-might-tmux-only-be-capable-of-attaching-once-per-shell-session
if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
  base_session=$(whoami)
  if ! tmux has-session -t "$base_session" 2>/dev/null; then
    tmux new-session -d -s "$base_session"
  fi
  tmux attach-session -t "$base_session"
fi

# Load p10k instant promopt
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
if [[ -r "$CACHE_DIR/p10k-instant-prompt-${(%):-%n}.zsh"  ]]; then
  source "$CACHE_DIR/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load Zinit
ZINIT_BIN_DIR="$CACHE_DIR/zinit/bin"
if [[ ! -d $ZINIT_BIN_DIR ]]; then
    command mkdir -p $ZINIT_BIN_DIR
    command git clone https://github.com/zdharma/zinit $ZINIT_BIN_DIR --depth=1
fi
source "$ZINIT_BIN_DIR/zi.zsh"

# Create completions dir if not exist, docker plugin need it
ZSH_COMPLETIONS_DIR=$CACHE_DIR/zsh/completions
if [[ ! -d $ZSH_COMPLETIONS_DIR  ]]; then
  mkdir -p $ZSH_COMPLETIONS_DIR
fi

#----------------------------------------------
# Plugin section
#
# Load essential plugins immediately
zinit ice depth=1; zinit light romkatv/powerlevel10k
source "$HOME/.zi/plugins/romkatv---powerlevel10k/config/p10k-robbyrussell.zsh"
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
# Alternative custom prompt
#PROMPT='%F{green}%n@%m %F{blue}%1~ %F{reset}$ '
#PROMPT='%F{cyan}%1~ %F{green}$ '
zinit light zdharma-continuum/fast-syntax-highlighting

# Critical plugins required for core functionality
zinit ice wait'0' depth=1 lucid; zinit light zsh-users/zsh-autosuggestions
#zinit ice wait'0' depth=1; 
zinit ice wait'0' depth=1 lucid; zinit light zsh-users/zsh-history-substring-search

# Important but not immediate
zinit ice wait'1' depth=1 lucid; zinit light jeffreytse/zsh-vi-mode
zinit ice wait'1' depth=1 lucid; zinit light zsh-users/zsh-completions
zinit ice wait'1' depth=1 lucid; zinit snippet OMZP::tmux
zinit ice wait'1' depth=1 lucid; zinit snippet OMZP::git

# Optional Plugins
zinit ice wait'2' depth=1 lucid; zinit light jreese/zsh-titles
zinit ice wait'2' depth=1 lucid; zinit light hlissner/zsh-autopair
# Color
zinit ice wait'2' depth=1 lucid; zinit snippet OMZP::colorize
zinit ice wait'2' depth=1 lucid; zinit snippet OMZP::colored-man-pages
# Utility
zinit ice wait'2' depth=1 lucid; zinit snippet OMZP::sudo
zinit ice wait'2' depth=1 lucid; zinit snippet OMZP::docker
zinit ice wait'2' depth=1 lucid; zinit snippet OMZP::command-not-found
# marks, mark/unmark + <markname>, jump + <markname>
zinit ice wait'2' depth=1 lucid; zinit snippet OMZP::jump
# extract + <archive>
zinit ice wait'2' depth=1 lucid; zinit snippet OMZP::extract

#----------------------------------------------
# Configuration and Alias
# Configure zsh options
setopt extended_glob
setopt inc_append_history
setopt hist_ignore_space
setopt hist_ignore_dups
setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt hist_reduce_blanks
setopt hist_verify
setopt share_history
HISTFILE=~/.zsh_history
SAVEHIST=10000

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias vi='vim'
# From OMZP::colorize
alias cat='ccat'

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  alias ls='ls -G'
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Ubuntu or other Linux distributions
  alias ls='ls --color'
  bindkey '^[OA' history-substring-search-up
  bindkey '^[OB' history-substring-search-down
fi

# zsh-history-substring-search
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Make Alt + arrow work on Ubuntu
# https://stackoverflow.com/questions/12382499/looking-for-altleftarrowkey-solution-in-zsh
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word

#----------------------------------------------
# Custom settings unrelated with zsh
#
export LESS="-XFR"

alias dockrun='sudo docker run -it --network=host --device=/dev/kfd --device=/dev/dri --group-add video --cap-add=SYS_PTRACE --security-opt seccomp=unconfined --name zyin-$(date "+%m%d") -h $(date "+%m%d") -v /data:/data -v $HOME:/zyin'

# Function to set the COMPOSE_PROJECT_NAME if not already set
function set_compose_project_name() {
  local DATE=$(date "+%m%d")
  local TIME=$(date "+%H%M%S")
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
  docker-compose -f ~/.docker/docker-compose.yml "$@"
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

export PATH=/root/build/tools:$PATH
export NODE_TLS_REJECT_UNAUTHORIZED=0

#zprof
