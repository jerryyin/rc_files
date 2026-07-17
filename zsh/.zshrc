#zmodload zsh/zprof

# Environments tmux depend on
export TERM=xterm-256color
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Add ~/bin to PATH for user scripts
export PATH="$HOME/bin:$PATH"

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
# Guard on zinit.zsh itself, not the directory: a partial bootstrap (mkdir
# succeeds but the clone fails/is interrupted) leaves an empty dir that a
# directory-existence check would treat as installed forever. Safe to wipe+reclone:
# this lives under ~/.cache (a disposable cache with no user data).
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
ZINIT_BIN_DIR="$CACHE_DIR/zinit/bin"
if [[ ! -f $ZINIT_BIN_DIR/zinit.zsh ]]; then
    command rm -rf $ZINIT_BIN_DIR
    command mkdir -p $ZINIT_BIN_DIR
    command git clone https://github.com/zdharma-continuum/zinit $ZINIT_BIN_DIR --depth=1
fi
if [[ -f $ZINIT_BIN_DIR/zinit.zsh ]]; then
    source "$ZINIT_BIN_DIR/zinit.zsh"
else
    print -u2 "zinit: bootstrap failed (no $ZINIT_BIN_DIR/zinit.zsh); skipping plugin load"
fi

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

# Auto-load FFM model environment used by Triton MI450 dev shells.
# /am-ffm/ffmlite_env.sh is the canonical source; it sets HSA_MODEL_LIB,
# HSA_MODEL_TOPOLOGY, HSA_KMT_MODEL_GPUVM_BASE, and LD_LIBRARY_PATH for us
# (zsh-aware via the ${(%):-%x} fallback for BASH_SOURCE).
function load_ffm_env() {
  [[ -n "$_TRITON_MODEL_PKG" ]] && return
  [[ -f /am-ffm/ffmlite_env.sh ]] || return

  source /am-ffm/ffmlite_env.sh

  # Prepend system ROCm so its libamd_smi/libroctx win over the bundled ones.
  if [[ -d /opt/rocm/lib ]]; then
    export LD_LIBRARY_PATH="/opt/rocm/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  fi

  export _TRITON_MODEL_PKG=/am-ffm

  # Auto-inject ffm_teardown pytest plugin to avoid FFM simulator hang on exit.
  # FFM's 192 simulator threads don't shut down during Py_Finalize; the plugin
  # calls hipDeviceReset + os._exit after pytest finishes.
  export PYTHONPATH="${HOME}/scripts/tools${PYTHONPATH:+:$PYTHONPATH}"
  export PYTEST_PLUGINS=ffm_teardown
}
load_ffm_env

alias dockrun='sudo docker run -it --network=host --device=/dev/kfd --device=/dev/dri --group-add video --cap-add=SYS_PTRACE --security-opt seccomp=unconfined --name zyin-$(date "+%m%d") -h $(date "+%m%d") -v /data:/data -v $HOME:/zyin'

alias ssh='autossh -M 0'

# ssh that forwards localhost:1455 -> <host>:1455 (for codex login etc.).
# Fails explicitly if local 1455 is already taken. ss is used (not /dev/tcp,
# which falsely reports bound ssh -L ports as free on WSL2).
# Usage: sshf <host> [extra ssh args...]
function sshf() {
  if ss -tlnH 'sport = :1455' 2>/dev/null | grep -q .; then
    echo "✗ local port 1455 is already in use:" >&2
    ss -tlnpH 'sport = :1455' 2>/dev/null >&2
    echo "  free it first, then retry." >&2
    return 1
  fi
  echo "→ forwarding localhost:1455 → $1:1455"
  ssh -o ExitOnForwardFailure=yes -L 1455:localhost:1455 "$@"
}

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

# IREE environment
export PATH=~/iree/build/model/tracy:$PATH
export PATH=~/iree/third_party/tracy/csvexport/build:$PATH
export PATH=~/iree/third_party/llvm-project/build/bin:$PATH
export PYTHONPATH=~/iree/build/model/compiler/bindings/python:~/iree/build/model/runtime/bindings/python:$PYTHONPATH
export GLIBC_TUNABLES=glibc.rtld.optional_static_tls=4096
export PATH=~/iree/build/dbg/tools:$PATH

# Triton environment
export PYTHONPATH=~/triton-mi450/python:$PYTHONPATH

#zprof
#
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export KUBECONFIG="$HOME/.kube/configs/tw-tus1-bm-private-sso.conf"
if command -v switcher >/dev/null 2>&1; then
  source <(switcher init zsh)
fi
if command -v switch >/dev/null 2>&1; then
  source <(switch completion zsh)
fi

# SSH agent auto-start
SSH_ENV="$HOME/.ssh-agent-env"
function start_agent {
    echo "Starting SSH agent..."
    ssh-agent -s > "${SSH_ENV}"
    chmod 600 "${SSH_ENV}"
    source "${SSH_ENV}" > /dev/null
    ssh-add ~/.ssh/id_rsa 2>/dev/null
}

# Source SSH agent environment if it exists
if [ -f "${SSH_ENV}" ]; then
    source "${SSH_ENV}" > /dev/null
    # Check if agent is still running
    ps -p ${SSH_AGENT_PID} > /dev/null 2>&1 || start_agent
else
    start_agent
fi

# Add ~/.local/bin to PATH (for Claude Code)
export PATH="$HOME/.local/bin:$PATH"
