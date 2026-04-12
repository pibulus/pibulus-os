# WEECHAT — IRC Client That Can Look Incredible

Infinitely themeable, scriptable in Python/Perl/Ruby, and it will look exactly how you want
if you put an hour in. This is the cyberpunk terminal communication tool.

---

## Start and connect

```bash
weechat

# Inside WeeChat — connect to a server
/server add libera irc.libera.chat/6697 -ssl
/connect libera

# Quick connect without saving
/connect irc.libera.chat

# Join a channel
/join #linux

# Switch between windows
Alt+1, Alt+2, ... (or F5/F6 to cycle)

# Close a window
/close
```

---

## Essential commands

```
/nick yournick           change nickname
/msg someone hello       private message
/query someone           open private chat window
/part                    leave current channel
/quit                    disconnect and exit
/away [message]          set away status
/whois nick              look up a user
/list                    list all channels on server (warning: huge)
/list #python            search channels
```

---

## Making it look good

```bash
# Install the script manager
/script install iset.py     # settings browser
/script install colorize_nicks.py   # colour nicks in chat

# Popular themes — download from weechat.org/scripts
# Good ones to look up: dracula, gruvbox, nord
```

---

## Split windows (the killer feature)

```
/window splitv    vertical split
/window splith    horizontal split
/window merge     merge back
Ctrl+X            switch focus between splits
```

---

## Mouse support

```
/set weechat.look.mouse on
/mouse enable
```

---

## Useful settings

```
/set weechat.bar.nicklist.hidden on     hide nicklist (cleaner)
/set weechat.look.prefix_align_max 12  align nicks
/set weechat.color.chat_nick_colors "cyan,magenta,yellow,green,brightblue"
/set weechat.bar.status.color_bg default   transparent status bar
/save                                   save all settings
```

---

## Filters (hide noise)

```
/filter add joinquit * irc_join,irc_part,irc_quit *   hide join/part/quit spam
/filter toggle joinquit    toggle it on/off
```

---

## Underground IRC networks worth visiting

```
Libera.chat          irc.libera.chat:6697 (SSL)    open source, tech, Linux
Hackint              irc.hackint.org:6697 (SSL)     hacker/security culture
EFnet                irc.efnet.org                  the original, no registration
IRCnet               open.ircnet.net                old school European
```

---

## Install

```bash
sudo apt install weechat
```
