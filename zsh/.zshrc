# Load Zinit
if [[ ! -d "${XDG_CACHE_HOME:-$HOME/.cache}/zinit/bin" ]]; then
    command mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zinit/bin"
    command git clone https://github.com/zdharma/zinit "${XDG_CACHE_HOME:-$HOME/.cache}/zinit/bin" --depth=1
fi
source "${XDG_CACHE_HOME:-$HOME/.cache}/zinit/bin/zi.zsh"

#----------------------------------------------

# Load plugins and themes
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light zdharma-continuum/fast-syntax-highlighting
# This plugin automatically inserts matching pairs of parentheses, brackets,
# quotes, etc., as you type, saving you time and effort in writing code or
# command structures.
zinit light hlissner/zsh-autopair
zinit light zsh-users/zsh-completions

typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
#zinit ice wait'1' lucid depth=1; zinit light romkatv/powerlevel10k
zinit light romkatv/powerlevel10k
source "$HOME/.zi/plugins/romkatv---powerlevel10k/config/p10k-robbyrussell.zsh"
# Custom prompt
#PROMPT='%F{green}%n@%m %F{blue}%1~ %F{reset}$ '
#PROMPT='%F{cyan}%1~ %F{green}$ '

# Load Git plugin from OMZ
zi snippet OMZP::git
zi snippet OMZP::colorize
zi snippet OMZP::tmux
zi snippet OMZP::sudo
zi snippet OMZP::docker
zi snippet OMZP::colored-man-pages

#----------------------------------------------

# Configure zsh options
setopt extended_glob
setopt inc_append_history
setopt hist_ignore_space
setopt hist_ignore_dups
setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt hist_reduce_blanks
setopt hist_verify

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias vi='vim'
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

# TMUX
# # If not running interactively, do not do anything
# # This configuration allows multiple tmux sessions
#[[ $- != *i* ]] && return
#[[ -z "$TMUX" ]] && exec tmux -2u || :

# This configuration allows attaching to one base session
# https://unix.stackexchange.com/questions/16237/why-might-tmux-only-be-capable-of-attaching-once-per-shell-session
if which tmux >/dev/null 2>&1; then
  # Default to TMUX
  if [ -z "$TMUX" ]; then
    base_session=$(whoami)
    # Create the base session if it doesn't exist
    tmux has-session -t $base_session || tmux new-session -d -s $base_session
    # Get a count of clients connected
    client_cnt=$(tmux list-clients | wc -l | sed 's/^[ \t ]*//')
    if [ $client_cnt -ge 1 ]; then
      # Make a unique session name
      session_name=$base_session"-"$client_cnt
      # Create the new session based on the base_session
      tmux new-session -d -t $base_session -s $session_name
      # Launch the connection with a few caveats (kill the session when the client goes away)
      tmux -2u attach-session -t $session_name \; set-option destroy-unattached
    else
      tmux -2u attach-session -t $base_session
    fi
  fi
fi

export LESS="-XFR"

alias drun='sudo docker run -it --network=host --device=/dev/kfd --device=/dev/dri --group-add video --cap-add=SYS_PTRACE --security-opt seccomp=unconfined --name zyin-$(date "+%m%d") -h $(date "+%m%d") -v /data:/data -v $HOME:/zyin'

# Profile plugin speed:
# Load all of the plugins that were defined in ~/.zshrc
#for plugin ($plugins); do
#  timer=$(($(gdate +%s%N)/1000000))
#  if [ -f $ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh ]; then
#    source $ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh
#  elif [ -f $ZSH/plugins/$plugin/$plugin.plugin.zsh ]; then
#    source $ZSH/plugins/$plugin/$plugin.plugin.zsh
#  fi
#  now=$(($(gdate +%s%N)/1000000))
#  elapsed=$(($now-$timer))
#  echo $elapsed":" $plugin
#done
