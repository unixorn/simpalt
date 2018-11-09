# Based on Roby Russel's agnoster theme
# https://github.com/robbyrussell/oh-my-zsh/wiki/themes
#
# # Goals
# - Make a smaller footprint in the termial while maintaning the information
#   provided by agnoster
# - Allow switching between full prompt and small prompt
# - Warn on aws-vault session being active

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
SEGMENT_SEPARATOR=''

## huh dont need this
collapse_pwd() {
   # echo $(pwd | sed -e "s,^$HOME,~,")
   echo $(pwd | sed -e "s,^$HOME,~," | sed "s@\(.\)[^/]*/@\1/@g")
}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
__simpalt_prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

__simpalt_prompt_segment_small() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%}"
  else
    echo -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
}

# End the prompt, closing any open segments
__simpalt_prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

# End the prompt, closing any open segments
__simpalt_prompt_end_small() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
__simpalt_prompt_context() {
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    __simpalt_prompt_segment black default "%(!.%{%F{yellow}%}.)$COMPUTER_SYMBOL"
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
__simpalt_prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && __simpalt_prompt_segment black default "$symbols"
}

__simpalt_prompt_aws() {
  [[ $AWS_VAULT ]] && __simpalt_prompt_segment magenta black " $AWS_VAULT"
}

__simpalt_prompt_aws_small() {
  [[ $AWS_VAULT ]] && __simpalt_prompt_segment black default "%{%F{magenta}%}"
}

# Git: branch/detached head, dirty status
__simpalt_prompt_git() {
  local ref dirty
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    ZSH_THEME_GIT_PROMPT_DIRTY='±'
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      __simpalt_prompt_segment yellow black
    else
      __simpalt_prompt_segment green black
    fi
    echo -n "${ref/refs\/heads\// }$dirty"
  fi
}

__simpalt_prompt_git_small() {
  local ref dirty
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    ref=$(git symbolic-ref HEAD 2> /dev/null)
    if [ ! $ref ]; then
      __simpalt_prompt_segment_small red
    else
      if [[ "refs/heads/master" != "$ref" ]]; then
        __simpalt_prompt_segment black default ""
      fi
      dirty=$(parse_git_dirty)
      if [[ -n $dirty ]]; then
        __simpalt_prompt_segment_small yellow
      else
        __simpalt_prompt_segment_small green
      fi
    fi
  else
    __simpalt_prompt_segment_small blue
  fi
}

# Dir: current working directory
__simpalt_prompt_dir() {
  __simpalt_prompt_segment blue black '%~'
}

__simpalt_prompt_dir_small() {
  if [[ "$PWD" != "$HOME" ]]; then
    __simpalt_prompt_segment black default "$(basename $PWD)"
  else
    __simpalt_prompt_segment black default "~"
  fi
}

## Main prompt
build_prompt() {
  RETVAL=$?
  if [ $SIMPALT_LPWD ]; then
    __simpalt_prompt_status
    __simpalt_prompt_aws
    __simpalt_prompt_context
    __simpalt_prompt_dir
    __simpalt_prompt_git
    __simpalt_prompt_end
  else
    __simpalt_prompt_status
    __simpalt_prompt_aws_small
    __simpalt_prompt_context
    __simpalt_prompt_dir_small
    __simpalt_prompt_git_small
    __simpalt_prompt_end_small
  fi
}

pw() {
  if [ $SIMPALT_LPWD ]; then
    unset SIMPALT_LPWD
  else
    export SIMPALT_LPWD=1
  fi
}

PROMPT='%{%f%b%k%}$(build_prompt) '
