case $- in
    *i*) ;;
      *) return;;
esac
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac
force_color_prompt=yes
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w \$\[\033[00m\] '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
if ! shopt -oq posix; then
  fi
fi
. "/home/pibulus/.deno/env"
export DENO_INSTALL="/home/pibulus/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"
alias deck="~/pibulus-os/launcher.sh"
alias halp="deck --help"
alias sos='deck --help'
alias wtf='deck --help'
export PATH="$HOME/.local/bin:$PATH"
alias passport='cd /media/pibulus/passport'
alias vault='cd /media/pibulus/passport/Knowledge-Vault'
alias music='cd /media/pibulus/passport/Music'
alias soulseek='cd /media/pibulus/passport/Soulseek'
alias calibre='cd /media/pibulus/passport/Calibre-Library'
alias downloads='cd /media/pibulus/passport/Soulseek'
alias diskspace='df -h | grep -E "passport|mmcblk"'
alias dockerspace='docker system df'
alias slskd-web='echo "Soulseek Web UI: http://pibulus.local:5030"'
export NVM_DIR="$HOME/.nvm"
~/pibulus-os/welcome.sh
export PATH="$HOME/.local/bin:$PATH"
help() { deck --help; }
export PATH=$HOME/bin:$PATH
alias bunker="~/pibulus-os/scripts/set_stealth.sh bunker"
