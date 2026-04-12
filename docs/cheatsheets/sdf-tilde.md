# SDF + TILDE — Public Access UNIX

These are real, shared UNIX systems you can get a free account on and actually use.
Not VMs in some cloud. Real boxes run by real communities. SDF has been running since 1987.

---

## SDF (Super Dimension Fortress)

The oldest continuously running public access UNIX. Ancient in internet terms.
Has IRC, Gopher, Gemini, shell access, email, the works.

```bash
# Connect
ssh sdf.org

# Register for a free account on their website first:
# https://sdf.org (click "new user")

# After getting an account:
ssh yourname@sdf.org
```

**What's there:**
- Full shell (bash, zsh, tmux, vim, emacs)
- Email (mutt/alpine)
- IRC (via their local server `ircnow.org`)
- Gopher hosting
- Gemini hosting
- A long-running community with history

---

## Tilde.town

A deliberately small, community-run Linux server.
Heavily focused on creativity, weird experiments, and being nice to each other.

```bash
# Request an account: https://tilde.town/~root/signup.html
ssh yourname@tilde.town
```

**The tildeverse** — a network of similar servers run by different communities:
- `tilde.town` — art, creativity, weirdness
- `tilde.club` — the original (2014)
- `rawtext.club` — writing focused
- `ctrl-c.club` — hackers and tinkerers

Full list: `https://tildeverse.org`

---

## What you can actually do there

```bash
# Host a website — your files go in ~/public_html/
# Accessible at: http://tilde.town/~yourname/

# Run persistent processes in tmux
tmux new-session -s mybot

# Write things in a shared gopher hole or gemini capsule
# Talk to people in the local IRC or on-system chat (write command)
write otherperson

# Play old games
# Most tildes have nethack, adventure, zork installed

# Read the system news and user posts
plan  # read other users' .plan files
finger username  # see a user's info
```

---

## The culture

Both communities are:
- Small enough that people know each other
- Explicitly anti-commercial
- Interested in computing as craft
- Good at helping newcomers

Expect ASCII art in people's .plan files.
Expect conversations about UNIX philosophy at 2am.
This is the underground the cyberdeck was made for.

---

## Connect

```bash
ssh -4 sdf.org
ssh -4 tilde.town
```
