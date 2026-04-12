# GEMINI — The Other Internet

A minimal protocol designed in 2019 as a deliberate alternative to the modern web.
No JavaScript, no tracking, no ads, no cookies. Just text. It feels like the internet
was supposed to feel. Active community, lots of good writing.

---

## What it is

Gemini is a protocol (like HTTP but simpler) with its own content format (Gemtext).
URLs look like: `gemini://example.com/path`

You need a Gemini browser to access it.

---

## Install a browser

```bash
# amfora — TUI browser, best for terminal
snap install amfora
# or build from source: go install tildegit.org/sloum/amfora@latest

# bombadillo — also TUI, supports Gopher + Gemini
go install tildegit.org/sloum/bombadillo@latest

# lagrange — beautiful GUI browser (heavier, needs display)
sudo apt install lagrange
```

---

## amfora quickstart

```
amfora gemini://gemini.circumlunar.space   # start here

Inside amfora:
  a              open address bar
  Enter          follow link
  Backspace      go back
  r              reload
  b              bookmarks
  B              add bookmark
  Ctrl+T         new tab
  Ctrl+W         close tab
  q              quit
```

---

## Good places to start

```gemini
gemini://gemini.circumlunar.space        the original project
gemini://tilde.town                      tilde community capsules
gemini://rawtext.club                    good writing
gemini://kennedy.gemi.dev                gemini search engine
gemini://geminispace.info                directory of capsules
gemini://midnight.pub                    the midnight pub — a fictional bar, people write in
gemini://szczezuja.space/en              tech and thoughts
```

---

## Hosting your own capsule

A Gemini capsule is just a directory of `.gmi` text files.

```bash
# Install agate (Rust-based server, very lightweight)
cargo install agate

# Or gmnisrv
sudo apt install gmnisrv

# Gemtext format is dead simple:
# Lines starting with # are headings
# Lines starting with => are links
# Everything else is body text

# Example: index.gmi
# My Capsule
Welcome to my corner of Geminispace.
=> about.gmi About me
=> log.gmi Field notes
```

---

## The culture

Gemini has a strong anti-surveillance, slow-web ethos. Most capsules are personal sites,
technical writing, fiction, and field notes. No analytics, no growth hacking.
The community is small, opinionated, and genuinely nice.

It feels like the early web felt.
