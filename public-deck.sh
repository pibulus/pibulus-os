#!/bin/bash
# PUBLIC DECK — sandboxed game launcher for web visitors
export TERM=xterm-256color
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:${PATH:-}"
export ZCODE_PATH=/usr/share/games/zcode

trap '' INT TSTP

colorize() {
  if command -v lolcat >/dev/null 2>&1; then
    lolcat
  else
    cat
  fi
}

signal_line() {
  gum style --foreground 245 --align center 'arrows move // enter opens // quit exits remote worlds'
}

show_banner() {
  clear
  figlet -f small "TEXTWORLDS" | colorize
  printf '  BBS  •  MUDs  •  Roguelikes  •  Text Adventures  \n' | colorize
  printf '             quickcat.club\n' | colorize
  signal_line
  echo
}

press_enter() {
  echo
  gum style --foreground 245 'Signal ended. Press Enter to return to the gateway.'
  read -r _
}

run_local_game() {
  nice -n 15 timeout --foreground 10m "$@"
}

roguelike_menu() {
  while true; do
    clear
    printf 'ROGUELIKES\n' | figlet -f small | colorize
    echo 'Terminal-native dungeon crawlers. ? usually opens help. q usually quits.'
    echo

    rogue_choice=$(gum choose \
      --header='Pick a dungeon.' \
      --height=9 \
      --cursor='▸ ' \
      --cursor.foreground 212 \
      --header.foreground 245 \
      --selected.foreground 51 \
      '⚔️  NetHack — classic ASCII dungeon crawler' \
      '🐙  Dungeon Crawl Stone Soup — modern, brutal, readable' \
      '💍  Angband — Tolkien dungeon descent' \
      '🧪  Slash’EM — NetHack turned weirder and meaner' \
      '🕯️  Moria — the old deep dungeon ancestor' \
      '↩️  Back to Textworlds')

    case "$rogue_choice" in
      *'NetHack'*)
        clear
        printf 'NETHACK\n' | figlet -f small | colorize
        echo 'Arrow keys to move. ? for help. q to save+quit.'
        echo
        gum confirm 'Ready to enter the dungeon?' && run_local_game nethack
        press_enter
        ;;
      *'Dungeon Crawl'*)
        clear
        printf 'CRAWL\n' | figlet -f small | colorize
        echo 'Dungeon Crawl Stone Soup. Pick a species/background, then try not to die.'
        echo
        run_local_game crawl
        press_enter
        ;;
      *'Angband'*)
        clear
        printf 'ANGBAND\n' | figlet -f small | colorize
        echo 'Descend, loot, run away when the math turns against you.'
        echo
        run_local_game angband -mgcu -- -D -K 2>/dev/null
        press_enter
        ;;
      *'Slash'*)
        clear
        printf 'SLASHEM\n' | figlet -f small | colorize
        echo 'NetHack variant. More roles, more monsters, less mercy.'
        echo
        run_local_game slashem
        press_enter
        ;;
      *'Moria'*)
        clear
        printf 'MORIA\n' | figlet -f small | colorize
        echo 'Old-school dungeon crawl. Minimal, mean, historically important.'
        echo
        run_local_game moria
        press_enter
        ;;
      *'Back'*|'')
        return
        ;;
    esac
  done
}

bbs_menu() {
  while true; do
    clear
    printf 'BBS GATEWAY\n' | figlet -f small | colorize
    echo 'Door games, boards, and old internet rooms. Type "quit" to disconnect.'
    echo

    bbs_choice=$(gum choose \
      --header='Pick a board.' \
      --height=11 \
      --cursor='▸ ' \
      --cursor.foreground 212 \
      --header.foreground 245 \
      --selected.foreground 51 \
      '🐉  Legend of the Red Dragon — classic BBS door RPG' \
      '📟  Fozz BBS — retro computing bulletin board' \
      '🚀  TW Lounge — TradeWars + door games' \
      '🏰  Realm of Serion — classic BBS and LORD tournament' \
      '🌀  ConstructiveChaos — active Synchronet BBS' \
      '🌉  Gateway BBS — long-running classic board' \
      '💾  NerdRage BBS — retro boards and doors' \
      '↩️  Back to Textworlds')

    case "$bbs_choice" in
      *'Legend of the Red Dragon'*)
        clear
        printf 'RED DRAGON\n' | figlet -f small | colorize
        echo 'Legend of the Red Dragon. New players: follow the LORD prompts.'
        echo
        TERM=ansi telnet lord.stabs.org
        press_enter
        ;;
      *'Fozz'*)
        clear
        printf 'FOZZ BBS\n' | figlet -f small | colorize
        echo
        TERM=ansi telnet bbs.fozztexx.com
        press_enter
        ;;
      *'TW Lounge'*)
        clear
        printf 'TW LOUNGE\n' | figlet -f small | colorize
        echo 'TradeWars, LORD, and other BBS doors.'
        echo
        TERM=ansi telnet bbs.twlounge.net
        press_enter
        ;;
      *'Realm of Serion'*)
        clear
        printf 'SERION\n' | figlet -f small | colorize
        echo 'Classic BBS with LORD tournament energy.'
        echo
        TERM=ansi telnet connect.serionbbs.com
        press_enter
        ;;
      *'ConstructiveChaos'*)
        clear
        printf 'CHAOS BBS\n' | figlet -f small | colorize
        echo 'Active Synchronet board.'
        echo
        TERM=ansi telnet conchaos.synchro.net
        press_enter
        ;;
      *'Gateway'*)
        clear
        printf 'GATEWAY BBS\n' | figlet -f small | colorize
        echo
        TERM=ansi telnet gatewaybbs.net 2023
        press_enter
        ;;
      *'NerdRage'*)
        clear
        printf 'NERDRAGE\n' | figlet -f small | colorize
        echo
        TERM=ansi telnet nerdragebbs.ddns.net
        press_enter
        ;;
      *'Back'*|'')
        return
        ;;
    esac
  done
}

mud_menu() {
  while true; do
    clear
    printf 'MUD PORTAL\n' | figlet -f small | colorize
    echo 'Multi-user dungeons. Type "quit" to disconnect when you are done.'
    echo

    mud_choice=$(gum choose \
      --header='Pick a world.' \
      --height=13 \
      --cursor='▸ ' \
      --cursor.foreground 212 \
      --header.foreground 245 \
      --selected.foreground 51 \
      '🐉  Aardwolf — one of the largest MUDs online' \
      '📚  Discworld MUD — funny, deep, bookish' \
      '💍  MUME — Tolkien multiplayer world' \
      '⚔️  Realms of Despair — classic DIKU MUD (1994)' \
      '🐺  BatMUD — Finnish MUD, running since 1990' \
      '🏰  Medievia — classic medieval fantasy MUD' \
      '🔥  Threshold RPG — story-driven fantasy world' \
      '🌀  Lost Souls — deep lore, been running since 1990' \
      '🐍  Achaea — polished Iron Realms MUD' \
      '↩️  Back to Textworlds')

    case "$mud_choice" in
      *'Aardwolf'*)
        clear
        printf 'AARDWOLF MUD\n' | figlet -f small | colorize
        echo 'New players: type "new" at the prompt.'
        echo
        telnet aardmud.org 4000
        press_enter
        ;;
      *'Discworld'*)
        clear
        printf 'DISCWORLD\n' | figlet -f small | colorize
        echo 'Pratchett-shaped MUD. New players: follow the login prompts.'
        echo
        telnet discworld.starturtle.net 4242
        press_enter
        ;;
      *'MUME'*)
        clear
        printf 'MUME\n' | figlet -f small | colorize
        echo 'Multi-Users in Middle-earth.'
        echo
        telnet mume.org 4242
        press_enter
        ;;
      *'Realms of Despair'*)
        clear
        printf 'REALMS OF DESPAIR\n' | figlet -f small | colorize
        echo 'Classic DIKU MUD since 1994.'
        echo
        telnet realmsofdespair.com 4000
        press_enter
        ;;
      *'BatMUD'*)
        clear
        printf 'BATMUD\n' | figlet -f small | colorize
        echo 'New players: type "create" at the prompt.'
        echo
        telnet bat.org
        press_enter
        ;;
      *'Medievia'*)
        clear
        printf 'MEDIEVIA\n' | figlet -f small | colorize
        echo 'New players: follow the prompts to create a character.'
        echo
        telnet medievia.com 4000
        press_enter
        ;;
      *'Threshold'*)
        clear
        printf 'THRESHOLD RPG\n' | figlet -f small | colorize
        echo 'New players: type "new" at the prompt.'
        echo
        telnet thresholdrpg.com 3333
        press_enter
        ;;
      *'Lost Souls'*)
        clear
        printf 'LOST SOULS\n' | figlet -f small | colorize
        echo 'Deep lore. Take your time at the intro.'
        echo
        telnet lostsouls.org
        press_enter
        ;;
      *'Achaea'*)
        clear
        printf 'ACHAEA\n' | figlet -f small | colorize
        echo 'New players: type "new" at the prompt.'
        echo
        telnet achaea.com
        press_enter
        ;;
      *'Back'*|'')
        return
        ;;
    esac
  done
}

wonders_menu() {
  while true; do
    clear
    printf 'WONDERS\n' | figlet -f small | colorize
    echo 'Strange network-native terminal places that are worth one click.'
    echo

    wonder_choice=$(gum choose \
      --header='Pick a weird signal.' \
      --height=9 \
      --cursor='▸ ' \
      --cursor.foreground 212 \
      --header.foreground 245 \
      --selected.foreground 51 \
      '🖥️  Telehack — simulated old internet with commands and games' \
      '🗺️  MapSCII — pan-and-zoom world map in the terminal' \
      '🚲  SSHTron — multiplayer lightcycles over SSH' \
      '🎬  ASCII Star Wars — the classic terminal screening' \
      '🏛️  NetHack Alt.org — public NetHack server' \
      '↩️  Back to Textworlds')

    case "$wonder_choice" in
      *'Telehack'*)
        clear
        printf 'TELEHACK\n' | figlet -f small | colorize
        echo 'Try commands like help, zork, wumpus, starwars, or basic.'
        echo
        telnet telehack.com
        press_enter
        ;;
      *'MapSCII'*)
        clear
        printf 'MAPSCII\n' | figlet -f small | colorize
        echo 'Terminal map of the world. Use arrows and +/- to move and zoom.'
        echo
        telnet mapscii.me
        press_enter
        ;;
      *'SSHTron'*)
        clear
        printf 'SSHTRON\n' | figlet -f small | colorize
        echo 'Multiplayer Tron/lightcycles in a terminal.'
        echo
        ssh -o StrictHostKeyChecking=accept-new sshtron.zachlatta.com
        press_enter
        ;;
      *'ASCII Star Wars'*)
        clear
        printf 'STAR WARS\n' | figlet -f small | colorize
        echo 'Passive, dumb, perfect.'
        echo
        telnet towel.blinkenlights.nl
        press_enter
        ;;
      *'NetHack Alt'*)
        clear
        printf 'ALT ORG\n' | figlet -f small | colorize
        echo 'Public NetHack server: play, watch, or make an account.'
        echo
        telnet alt.org
        press_enter
        ;;
      *'Back'*|'')
        return
        ;;
    esac
  done
}

while true; do
  show_banner
  choice=$(gum choose \
    --header='Pick a portal.' \
    --height=8 \
    --cursor='▸ ' \
    --cursor.foreground 212 \
    --header.foreground 245 \
    --selected.foreground 51 \
    '⚔️  Roguelikes — NetHack, Crawl, Angband' \
    '📖  Text adventures — interactive fiction' \
    '📟  BBS boards — LORD, doors, retro rooms' \
    '🐉  MUD worlds — Aardwolf, Discworld, MUME' \
    '🖥️  Terminal wonders — Telehack, MapSCII, SSHTron' \
    '🚪  Disconnect')

  case "$choice" in
    *'Roguelikes'*)
      roguelike_menu
      ;;
    *'Text adventures'*)
      clear
      printf 'TEXT ADVENTURES\n' | figlet -f small | colorize
      echo
      GAMES_DIR=/usr/share/games/zcode
      GAME=$(ls "$GAMES_DIR"/*.z* 2>/dev/null | while read -r f; do
        basename "$f" | sed 's/\.[^.]*$//'
      done | gum choose --cursor.foreground 212)
      if [ -n "$GAME" ]; then
        FILE=$(ls "$GAMES_DIR/$GAME".* 2>/dev/null | head -1)
        [ -n "$FILE" ] && run_local_game frotz "$FILE"
        press_enter
      fi
      ;;
    *'MUD worlds'*)
      mud_menu
      ;;
    *'Terminal wonders'*)
      wonders_menu
      ;;
    *'BBS boards'*)
      bbs_menu
      ;;
    *'Disconnect'*|'')
      clear
      printf 'NEURAL LINK SEVERED\n' | figlet -f small | colorize
      echo
      gum style --foreground 212 --align center 'Come back anytime. =^..^='
      sleep 2
      exit 0
      ;;
  esac
done
