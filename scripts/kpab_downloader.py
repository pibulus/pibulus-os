#!/usr/bin/env python3
"""
kpab.fm slskd batch downloader
Pirate radio station filler - curated for Pablo's taste

Usage:
  python3 -u ~/kpab_downloader.py --list
  python3 -u ~/kpab_downloader.py --batch uk_bangers
  python3 -u ~/kpab_downloader.py --batch all
  python3 -u ~/kpab_downloader.py --dry-run --batch aus

For new Claude sessions: read this file, add a new batch dict entry, run it.
slskd API: http://localhost:5030/api/v0 | auth: slskd/slskd
Navidrome: http://localhost:4533 | auth: local env / service config
"""
import json, urllib.request, urllib.error, time, sys, argparse

BASE = "http://localhost:5030/api/v0"

# ================================================================
# VIBE BATCHES
# Curated for kpab.fm - pirate radio energy, operator taste
# No: Neutral Milk Hotel, Bob Dylan, ABBA, Queen, Fleetwood Mac
# Yes: anything that sounds cool at 2am in a sweaty venue
# ================================================================
BATCHES = {

    # UK post-punk new wave - Fontaines, Sleaford Mods energy
    "uk_bangers": [
        ("Fontaines D.C.", "Dogrel"),
        ("Fontaines D.C.", "A Hero's Death"),
        ("Fontaines D.C.", "Skinty Fia"),
        ("Sleaford Mods", "Divide and Exit"),
        ("Sleaford Mods", "Key Markets"),
        ("Sleaford Mods", "Spare Ribs"),
        ("Idles", "Joy as an Act of Resistance"),
        ("Idles", "Ultra Mono"),
        ("Bob Vylan", "Bob Vylan Presents the Price of Life"),
        ("Shame", "Songs of Praise"),
        ("Shame", "Drunk Tank Pink"),
        ("black midi", "Schlagenheim"),
        ("Squid", "Bright Green Field"),
        ("Yard Act", "The Overload"),
        ("Dry Cleaning", "New Long Leg"),
        ("Goat Girl", "On All Fours"),
    ],

    # UK grime / rap that slaps
    "uk_grime": [
        ("Slowthai", "Nothing Great About Britain"),
        ("Slowthai", "Tyron"),
        ("Little Simz", "Sometimes I Might Be Introvert"),
        ("Little Simz", "Grey Area"),
        ("Little Simz", "No Thank You"),
        ("Skepta", "Konnichiwa"),
        ("Stormzy", "Gang Signs & Prayer"),
        ("Ghetts", "Conflict of Interest"),
        ("Novelist", "Novelist Guy"),
    ],

    # Australian stuff - because you LIVED this scene
    "aus": [
        ("King Gizzard and the Lizard Wizard", "I'm in Your Mind Fuzz"),
        ("King Gizzard and the Lizard Wizard", "Nonagon Infinity"),
        ("King Gizzard and the Lizard Wizard", "Infest the Rats' Nest"),
        ("Tropical Fuck Storm", "A Laughing Death in Meatspace"),
        ("Tropical Fuck Storm", "Braindrops"),
        ("The Drones", "Wait Long by the River"),
        ("The Drones", "Gala Mill"),
        ("Civic", "Future Forecast"),
        ("Cable Ties", "Far Enough"),
        ("The Chats", "High Risk Behaviour"),
        ("Meanies", "Gold"),
        ("Hard-Ons", "Dickcheese"),
        ("Sampa the Great", "The Return"),
        ("Sampa the Great", "As Above, So Below"),
        ("Hiatus Kaiyote", "Tawk Tomahawk"),
        ("Hiatus Kaiyote", "Choose Your Weapon"),
        ("Genesis Owusu", "Smiling with No Teeth"),
        ("Methyl Ethel", "Oh Inhuman Spectacle"),
        ("Jess Ribeiro", "My Little River"),
    ],

    # Hip hop that actually rules - no corny shit
    "hiphop": [
        ("JPEGMafia", "All My Heroes Are Cornballs"),
        ("JPEGMafia", "LP!"),
        ("Freddie Gibbs", "Piñata"),
        ("Freddie Gibbs", "Bandana"),
        ("Freddie Gibbs", "Alfredo"),
        ("Armand Hammer", "Haram"),
        ("Armand Hammer", "We Buy Diabetic Test Strips"),
        ("billy woods", "Maps"),
        ("billy woods", "Aethiopes"),
        ("Injury Reserve", "By Strict Order of Volcanoes"),
        ("Tierra Whack", "Whack World"),
        ("Cities Aviv", "Come to Life"),
        ("Knxwledge", "Hud Dreems"),
        ("Serengeti", "Kenny Dennis LP"),
    ],

    # Garage punk - the real shit, proto punk roots
    "garage": [
        ("The Stooges", "Fun House"),
        ("The Stooges", "Raw Power"),
        ("T. Rex", "Electric Warrior"),
        ("T. Rex", "The Slider"),
        ("The Troggs", "From Nowhere"),
        ("The Sonics", "Here Are the Sonics!!!"),
        ("The Seeds", "The Seeds"),
        ("The Pretty Things", "S.F. Sorrow"),
        ("The Mummies", "Never Been Caught"),
        ("The Gories", "Houserockin'"),
        ("The Oblivians", "Soul Food"),
        ("Jay Reatard", "Blood Visions"),
        ("The Reatards", "Teenage Hate"),
        ("Reigning Sound", "Time Bomb High School"),
        ("The Exploding Hearts", "Guitar Romantic"),
        ("Ausmuteants", "Ausmuteants"),
        ("Uranium Club", "All of Them Naturals"),
        ("Electric Eels", "Die Electric Eels"),
        ("Rocket from the Tombs", "The Day the Earth Met the Rocket from the Tombs"),
    ],

    # Hardcore / crossover / fun metal
    "hardcore": [
        ("Black Flag", "Damaged"),
        ("Black Flag", "My War"),
        ("Minor Threat", "Out of Step"),
        ("The Minutemen", "Double Nickels on the Dime"),
        ("Melvins", "Houdini"),
        ("Melvins", "Stoner Witch"),
        ("Suicidal Tendencies", "Suicidal Tendencies"),
        ("D.R.I.", "Dealing With It!"),
        ("Excel", "The Joke's on You"),
        ("Cro-Mags", "The Age of Quarrel"),
        ("Eyehategod", "Take as Needed for Pain"),
        ("Sleep", "Sleep's Holy Mountain"),
        ("Sleep", "Dopesmoker"),
        ("METZ", "METZ"),
        ("METZ", "Automat"),
    ],

    # Shoegaze - the ones that actually matter
    "shoegaze": [
        ("Slowdive", "Souvlaki"),
        ("Slowdive", "Pygmalion"),
        ("Ride", "Nowhere"),
        ("Ride", "Going Blank Again"),
        ("Lush", "Spooky"),
        ("Lush", "Split"),
        ("Swervedriver", "Mezcal Head"),
        ("Loop", "A Gilded Eternity"),
        ("Hum", "You'd Prefer an Astronaut"),
        ("Failure", "Fantastic Planet"),
        ("Chapterhouse", "Whirlpool"),
    ],

    # Electronic with actual soul
    "electronic": [
        ("Burial", "Burial"),
        ("Burial", "Untrue"),
        ("Burial", "Rival Dealer"),
        ("Portishead", "Dummy"),
        ("Portishead", "Portishead"),
        ("Arca", "Arca"),
        ("Arca", "Kick I"),
        ("Factory Floor", "Factory Floor"),
        ("Actress", "R.I.P."),
        ("Actress", "Ghettoville"),
        ("Shackleton", "Three EPs"),
        ("Demdike Stare", "Tryptych"),
        ("Flying Lotus", "Cosmogramma"),
        ("Flying Lotus", "You're Dead!"),
        ("Andy Stott", "Faith in Strangers"),
        ("Andy Stott", "Passed Me By"),
    ],

    # Cool indie / women-led / vibes
    "cool_indie": [
        ("Chastity Belt", "I Used to Spend So Much Time Alone"),
        ("Chastity Belt", "Time to Go Home"),
        ("Alvvays", "Antisocialites"),
        ("Alvvays", "Blue Rev"),
        ("Dehd", "Flower of Devotion"),
        ("Jay Som", "Everybody Works"),
        ("Hand Habits", "Placeholder"),
        ("Snail Mail", "Lush"),
        ("Palehound", "A Place I'll Always Go"),
        ("Preoccupations", "Preoccupations"),
        ("Preoccupations", "New Material"),
    ],

    # Krautrock - the backbone
    "krautrock": [
        ("Can", "Tago Mago"),
        ("Can", "Ege Bamyasi"),
        ("Can", "Future Days"),
        ("Neu!", "Neu!"),
        ("Neu!", "Neu! 2"),
        ("Faust", "Faust"),
        ("Faust", "So Far"),
        ("Amon Düül II", "Yeti"),
        ("Harmonia", "Musik von Harmonia"),
    ],

    # Sick soundtracks - movies with taste
    "soundtracks": [
        ("Soundtrack", "The Blues Brothers"),
        ("Soundtrack", "Tales from the Crypt Demon Knight"),
        ("Soundtrack", "Empire Records"),
        ("Soundtrack", "O Brother Where Art Thou"),
        ("Soundtrack", "Pulp Fiction"),
        ("Soundtrack", "Reservoir Dogs"),
        ("Soundtrack", "Trainspotting"),
        ("Soundtrack", "The Crow"),
        ("Soundtrack", "Dazed and Confused"),
        ("Soundtrack", "Natural Born Killers"),
        ("Soundtrack", "Lost Highway"),
        ("Soundtrack", "Judgment Night"),
        ("Soundtrack", "Singles"),
        ("Soundtrack", "Suburbia"),
        ("Soundtrack", "Repo Man"),
        ("Soundtrack", "Drive 2011"),
        ("Soundtrack", "Baby Driver"),
        ("Soundtrack", "Jackie Brown"),
        ("Soundtrack", "Kill Bill Vol 1"),
        ("Soundtrack", "Kill Bill Vol 2"),
        ("Soundtrack", "Django Unchained"),
        ("Soundtrack", "The Warriors"),
        ("Soundtrack", "Romeo and Juliet 1996"),
        ("Soundtrack", "High Fidelity"),
        ("Soundtrack", "Guardians of the Galaxy"),
        ("Soundtrack", "Until the End of the World Wim Wenders"),
        ("Soundtrack", "Paris Texas"),
        ("Soundtrack", "Ghost World"),
        ("Soundtrack", "The Royal Tenenbaums"),
        ("Soundtrack", "Donnie Darko"),
    ],

    # Tony Hawk soundtracks - the whole generation grew up on these
    "tony_hawk": [
        ("Soundtrack", "Tony Hawk Pro Skater"),
        ("Soundtrack", "Tony Hawk Pro Skater 2"),
        ("Soundtrack", "Tony Hawk Pro Skater 3"),
        ("Soundtrack", "Tony Hawk Pro Skater 4"),
        ("Soundtrack", "Tony Hawk Underground"),
    ],

    # Underground electronic deep cuts - long-form pirate radio gold
    "electronic_deep": [
        ("Gas", "Pop"),
        ("Gas", "Narkopop"),
        ("William Basinski", "The Disintegration Loops"),
        ("Tim Hecker", "Harmony in Ultraviolet"),
        ("Tim Hecker", "Ravedeath 1972"),
        ("Tim Hecker", "Virgins"),
        ("Oneohtrix Point Never", "Replica"),
        ("Oneohtrix Point Never", "R Plus Seven"),
        ("Oneohtrix Point Never", "Garden of Delete"),
        ("Aphex Twin", "Selected Ambient Works Volume II"),
        ("Aphex Twin", "Drukqs"),
        ("Autechre", "Tri Repetae"),
        ("Autechre", "Confield"),
        ("Boards of Canada", "Geogaddi"),
        ("Boards of Canada", "The Campfire Headphase"),
        ("GAS", "Zauberberg"),
        ("Fennesz", "Endless Summer"),
        ("Stars of the Lid", "And Their Refinement of the Decline"),
        ("Grouper", "Dragging a Dead Deer Up a Hill"),
        ("Grouper", "Ruins"),
        ("Coil", "Musick to Play in the Dark"),
        ("Lustmord", "The Place Where the Black Stars Hang"),
        ("Biosphere", "Substrata"),
        ("Pan Sonic", "A"),
    ],
    # Pirate radio electronics - breaks, techno, jungle, dancehall, UK bass
    "pirate_electronic": [
        # UK Jungle / Drum & Bass classics
        ("Goldie", "Timeless"),
        ("Roni Size", "New Forms"),
        ("LTJ Bukem", "Logical Progression"),
        ("Photek", "Modus Operandi"),
        ("DJ Shadow", "Endtroducing"),

        # Breaks / Big Beat era
        ("The Prodigy", "Music for the Jilted Generation"),
        ("The Prodigy", "The Fat of the Land"),
        ("The Chemical Brothers", "Exit Planet Dust"),
        ("The Chemical Brothers", "Dig Your Own Hole"),
        ("Fatboy Slim", "You've Come a Long Way Baby"),
        ("The Avalanches", "Since I Left You"),
        ("Amon Tobin", "Bricolage"),
        ("Amon Tobin", "Supermodified"),

        # Detroit / Berlin Techno
        ("Drexciya", "Neptune's Lair"),
        ("Underground Resistance", "Revolution for Change"),
        ("Jeff Mills", "Waveform Transmission Vol. 1"),
        ("Surgeon", "Force + Form"),
        ("Richie Hawtin", "Decks EFX & 909"),
        ("Basic Channel", "BCD"),

        # UK Garage / 2-Step / Grime foundations
        ("Burial", "Untrue"),
        ("The Streets", "Original Pirate Material"),
        ("Wiley", "Treddin on Thin Ice"),
        ("Dizzee Rascal", "Boy in da Corner"),

        # Dancehall / Sound System
        ("King Tubby", "Dub From the Roots"),
        ("Lee Scratch Perry", "Super Ape"),
        ("Scientist", "Scientist Rids the World of the Evil Curse of the Vampires"),
        ("Mad Professor", "Dub Me Crazy"),
        ("The Bug", "London Zoo"),

        # Leftfield / IDM bangers
        ("Leftfield", "Leftism"),
        ("Underworld", "Dubnobasswithmyheadman"),
        ("Orbital", "Orbital 2"),
        ("Squarepusher", "Feed Me Weird Things"),
        ("808 State", "Ninety"),
        ("A Guy Called Gerald", "Black Secret Technology"),

        # Modern UK Bass / Post-dubstep
        ("Skream", "Skream!"),
        ("Mount Kimbie", "Crooks & Lovers"),
        ("Four Tet", "Rounds"),
        ("Four Tet", "There Is Love in You"),
        ("Caribou", "Swim"),
        ("SOPHIE", "Oil of Every Pearl's Un-Insides"),
        ("Floating Points", "Crush"),
        ("Floating Points", "Elaenia"),

        # Acid House / Rave essentials
        ("808 State", "808:88:98"),
        ("Phuture", "Acid Tracks"),
        ("Mr. Fingers", "Amnesia"),
        ("Orbital", "In Sides"),
    ],
}

def get_token():
    req = urllib.request.Request(
        BASE + "/session",
        data=json.dumps({"username": "slskd", "password": "slskd"}).encode(),
        headers={"Content-Type": "application/json"}
    )
    return json.loads(urllib.request.urlopen(req, timeout=10).read())["token"]

def search_and_get_responses(token, query):
    req = urllib.request.Request(
        BASE + "/searches",
        data=json.dumps({"searchText": query, "fileLimit": 100}).encode(),
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {token}"}
    )
    d = json.loads(urllib.request.urlopen(req, timeout=10).read())
    sid = d["id"]
    for _ in range(8):
        time.sleep(3)
        req = urllib.request.Request(
            BASE + f"/searches/{sid}",
            headers={"Authorization": f"Bearer {token}"}
        )
        status = json.loads(urllib.request.urlopen(req, timeout=10).read())
        if status.get("isComplete") or "Completed" in str(status.get("state", "")):
            break
    req = urllib.request.Request(
        BASE + f"/searches/{sid}/responses",
        headers={"Authorization": f"Bearer {token}"}
    )
    try:
        r = json.loads(urllib.request.urlopen(req, timeout=10).read())
        return r if isinstance(r, list) else []
    except:
        return []

def score_response(response, artist, album):
    files = response.get("files", [])
    if not files:
        return 0, []
    score = 0
    all_names = " ".join(f.get("filename", "").lower() for f in files)
    has_flac = any(f.get("filename","").lower().endswith(".flac") for f in files)
    has_mp3 = any(f.get("filename","").lower().endswith(".mp3") for f in files)
    if has_flac:
        score += 100
    elif has_mp3:
        bitrates = [f.get("bitRate", 0) for f in files if f.get("bitRate")]
        score += 70 if (bitrates and max(bitrates) >= 320) else 40
    else:
        return 0, []
    a_clean = artist.lower().replace(" ", "").replace("the", "")
    al_clean = album.lower().replace(" ", "")
    if a_clean in all_names.replace(" ", "").replace("the", ""):
        score += 25
    if al_clean in all_names.replace(" ", ""):
        score += 25
    score += min(len(files) * 2, 20)
    speed = response.get("uploadSpeed", 0)
    score += 15 if speed > 200000 else (8 if speed > 50000 else 0)
    if response.get("freeUploadSlots", 0) > 0:
        score += 10
    return score, files

def queue_files(token, username, files, dry_run=False):
    audio = [f for f in files if f.get("filename","").lower().endswith((".flac",".mp3"))]
    if not audio:
        return 0
    if dry_run:
        fmts = set(f["filename"].split(".")[-1].upper() for f in audio)
        print(f"  [DRY] {len(audio)} {'/'.join(fmts)} files from {username}")
        return len(audio)
    queued = 0
    for f in audio:
        payload = [{"filename": f["filename"], "size": f.get("size", 0)}]
        req = urllib.request.Request(
            BASE + f"/transfers/downloads/{username}",
            data=json.dumps(payload).encode(),
            headers={"Content-Type": "application/json", "Authorization": f"Bearer {token}"}
        )
        try:
            urllib.request.urlopen(req, timeout=10)
            queued += 1
        except urllib.error.HTTPError as e:
            if e.code == 409:
                queued += 1
    return queued

def process_batch(batch_name, items, dry_run=False):
    print(f"\n{'='*60}")
    print(f"BATCH: {batch_name} ({len(items)} albums)")
    if dry_run:
        print("  *** DRY RUN ***")
    print(f"{'='*60}")
    token = get_token()
    log = []
    for i, (artist, album) in enumerate(items):
        print(f"\n[{i+1}/{len(items)}] {artist} - {album}")
        try:
            responses = search_and_get_responses(token, f"{artist} {album}")
            if not responses:
                print(f"  [!] No responses")
                log.append((artist, album, "no_results"))
                continue
            scored = [(score_response(r, artist, album)[0], r.get("username","?"), score_response(r, artist, album)[1])
                      for r in responses]
            scored = [(s,u,f) for s,u,f in scored if s > 0]
            if not scored:
                print(f"  [!] {len(responses)} responses but no audio")
                log.append((artist, album, "no_audio"))
                continue
            scored.sort(key=lambda x: x[0], reverse=True)
            best_score, best_user, best_files = scored[0]
            fmt = "FLAC" if any(f.get("filename","").lower().endswith(".flac") for f in best_files) else "MP3"
            print(f"  [+] {best_user}: {len(best_files)} files {fmt} (score={best_score})")
            count = queue_files(token, best_user, best_files, dry_run)
            status = "queued" if count > 0 else "failed"
            if not dry_run:
                print(f"  [{'OK' if count > 0 else '!!'}] {count} files queued")
            log.append((artist, album, status))
        except Exception as e:
            print(f"  [ERR] {e}")
            log.append((artist, album, f"error"))
        if (i + 1) % 10 == 0:
            try: token = get_token()
            except: pass
        time.sleep(2)
    print(f"\n{'─'*60}")
    ok = [l for l in log if l[2] == "queued"]
    fail = [l for l in log if l[2] != "queued"]
    print(f"DONE {batch_name}: {len(ok)}/{len(items)} queued")
    if fail:
        for a, al, s in fail:
            print(f"  - {a} - {al}: {s}")
    return log

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="kpab.fm slskd batch downloader")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--batch", default="uk_bangers",
                        help=f"Batch or 'all'. Options: {', '.join(BATCHES.keys())}")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()
    if args.list:
        for name, items in BATCHES.items():
            print(f"  {name}: {len(items)} albums")
        sys.exit(0)
    batches_to_run = BATCHES if args.batch == "all" else {args.batch: BATCHES.get(args.batch)}
    if None in batches_to_run.values():
        print(f"Unknown batch. Options: {', '.join(BATCHES.keys())}")
        sys.exit(1)
    for name, items in batches_to_run.items():
        process_batch(name, items, args.dry_run)
