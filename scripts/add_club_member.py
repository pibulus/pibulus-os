#!/usr/bin/env python3
import hashlib, os, uuid, base64, sqlite3, sys, json, urllib.request

if os.geteuid() != 0:
    os.execvp('sudo', ['sudo', sys.executable] + sys.argv)

if len(sys.argv) < 2:
    print('Usage: add_club_member.py username [password]')
    sys.exit(1)

user = sys.argv[1].lower()
pw = sys.argv[2] if len(sys.argv) > 2 else f'{user}123!'
email = f'{user}@quickcat.club'

dbs = {
    'CW': '/home/pibulus/.config/calibre-web/app.db',
    'KV': '/home/pibulus/.config/kavita/kavita.db',
    'ND': '/home/pibulus/.config/navidrome/navidrome.db'
}

KV_LIBRARY_ID = 1
KV_ROLE_IDS = {
    'Pleb': 2,
    'Login': 7,
}

def add_jf_api(user, pw):
    JF_KEY = '1980cdafcfec43b58b04b89c4d1f5b99'
    headers = {'Content-Type': 'application/json', 'X-Emby-Token': JF_KEY}
    # Create user
    payload = json.dumps({'Name': user}).encode()
    req = urllib.request.Request('http://localhost:8096/Users/New', data=payload, headers=headers, method='POST')
    d = json.loads(urllib.request.urlopen(req).read())
    uid = d['Id']
    # Set password
    payload2 = json.dumps({'NewPw': pw}).encode()
    req2 = urllib.request.Request(f'http://localhost:8096/Users/{uid}/Password', data=payload2, headers=headers, method='POST')
    urllib.request.urlopen(req2)

def add_cw(conn, user, pw, email):
    salt = b'salt_' + os.urandom(8)
    hash_val = hashlib.scrypt(pw.encode(), salt=salt, n=32768, r=8, p=1, dklen=64, maxmem=256*1024*1024)
    cw_hash = f'scrypt:32768:8:1${salt.decode("latin1", "ignore")}${hash_val.hex()}'
    conn.execute("INSERT INTO user (name, email, password, role, view_settings) VALUES (?, ?, ?, 1, '{}')", (user, email, cw_hash))

def add_kv(conn, user, pw, email):
    salt = os.urandom(16)
    hash_val = hashlib.pbkdf2_hmac('sha256', pw.encode(), salt, 100000)
    # ASP.NET Identity V3: format marker + PRF(HMACSHA256=1) + iterations + salt length + salt + subkey
    kv_hash = base64.b64encode(b'\x01\x00\x00\x00\x01\x00\x01\x86\xa0\x00\x00\x00\x10' + salt + hash_val).decode()
    conn.execute("""INSERT INTO AspNetUsers (UserName, NormalizedUserName, Email, NormalizedEmail, PasswordHash, SecurityStamp, ConcurrencyStamp, Created, CreatedUtc, LastActive, LastActiveUtc, EmailConfirmed, PhoneNumberConfirmed, TwoFactorEnabled, LockoutEnabled, AccessFailedCount, RowVersion, AgeRestriction, AgeRestrictionIncludeUnknowns) 
    VALUES (?, ?, ?, ?, ?, ?, ?, '2026-03-30 00:00:00', '2026-03-30 00:00:00', '2026-03-30 00:00:00', '2026-03-30 00:00:00', 1, 0, 0, 1, 0, 1, 0, 0)""",
    (user, user.upper(), email, email.upper(), kv_hash, str(uuid.uuid4()), str(uuid.uuid4())))
    user_id = conn.execute("SELECT Id FROM AspNetUsers WHERE UserName = ?", (user,)).fetchone()[0]
    template = conn.execute("SELECT * FROM AppUserPreferences WHERE AppUserId = 1").fetchone()
    if template:
        conn.execute("""
            INSERT INTO AppUserPreferences (
                AllowAutomaticWebtoonReaderDetection, AniListScrobblingEnabled, AppUserId, AutoCloseMenu,
                BackgroundColor, BlurUnreadSummaries, BookReaderFontFamily, BookReaderFontSize,
                BookReaderHighlightSlots, BookReaderImmersiveMode, BookReaderLayoutMode, BookReaderLineSpacing,
                BookReaderMargin, BookReaderReadingDirection, BookReaderTapToPaginate, BookReaderWritingStyle,
                BookThemeName, CollapseSeriesRelationships, ColorScapeEnabled, CustomKeyBinds, DataSaver,
                EmulateBook, GlobalPageLayoutMode, LayoutMode, Locale, NoTransitions, OpdsPreferences,
                PageSplitOption, PdfScrollMode, PdfSpreadMode, PdfTheme, PromptForDownloadSize,
                PromptForRereadsAfter, ReaderMode, ReadingDirection, ScalingOption, ShareReviews,
                ShowScreenHints, SocialPreferences, SwipeToPaginate, ThemeId, WantToReadSync
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            template[1], template[2], user_id, template[4], template[5], template[6], template[7], template[8],
            template[9], template[10], template[11], template[12], template[13], template[14], template[15],
            template[16], template[17], template[18], template[19], template[20], template[21], template[22],
            template[23], template[24], template[25], template[26], template[27], template[28], template[29],
            template[30], template[31], template[32], template[33], template[34], template[35], template[36],
            template[37], template[38], template[39], template[40], template[41], template[42]
        ))
    for role_id in KV_ROLE_IDS.values():
        conn.execute("INSERT INTO AspNetUserRoles (UserId, RoleId) VALUES (?, ?)", (user_id, role_id))
    conn.execute("INSERT INTO AppUserLibrary (AppUsersId, LibrariesId) VALUES (?, ?)", (user_id, KV_LIBRARY_ID))

def add_nd(conn, user, pw, email):
    uid, salt = str(uuid.uuid4()), os.urandom(4)
    nd_hash = base64.b64encode(salt + hashlib.sha256(salt + pw.encode()).digest()).decode()
    conn.execute("INSERT INTO user (id, user_name, name, email, password, is_admin, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
    (uid, user, user, email, nd_hash))

def add_abs_api(user, pw, email):
    login_payload = json.dumps({'username': 'pibulus', 'password': 'meringue'}).encode()
    login_req = urllib.request.Request('http://localhost:13378/login', data=login_payload, headers={'Content-Type': 'application/json'}, method='POST')
    login = json.loads(urllib.request.urlopen(login_req).read())
    token = login['user']['accessToken']
    headers = {'Content-Type': 'application/json', 'Authorization': f'Bearer {token}'}
    permissions = {
        'download': True, 'update': False, 'delete': False, 'upload': False, 'createEreader': False,
        'accessAllLibraries': True, 'accessAllTags': True, 'accessExplicitContent': True,
        'selectedTagsNotAccessible': False, 'librariesAccessible': [], 'itemTagsSelected': []
    }
    payload = json.dumps({'username': user, 'password': pw, 'email': email, 'type': 'user', 'isActive': True, 'permissions': permissions}).encode()
    req = urllib.request.Request('http://localhost:13378/api/users', data=payload, headers=headers, method='POST')
    urllib.request.urlopen(req)

# Jellyfin via API (direct DB writes cause EF Core UUID/RowVersion issues)
try:
    add_jf_api(user, pw)
    print(f'✅ JF: {user} added.')
except Exception as e: print(f'❌ JF: {e}')

dbs_sqlite = {k: v for k, v in dbs.items() if k != 'JF'}
for label, path in dbs_sqlite.items():
    try:
        conn = sqlite3.connect(path)
        if label == 'CW': add_cw(conn, user, pw, email)
        elif label == 'KV': add_kv(conn, user, pw, email)
        elif label == 'ND': add_nd(conn, user, pw, email)
        conn.commit(); conn.close()
        print(f'✅ {label}: {user} added.')
    except Exception as e: print(f'❌ {label}: {e}')

# Audiobookshelf
try:
    add_abs_api(user, pw, email)
    print(f'✅ ABS: {user} added.')
except Exception as e: print(f'❌ ABS: {e}')

# RomM (API-based, not SQLite)
try:
    auth_str = base64.b64encode(b'pibulus:meringue').decode()
    romm_headers = {'Authorization': f'Basic {auth_str}', 'Content-Type': 'application/json'}
    payload = json.dumps({'username': user, 'password': pw, 'email': email, 'role': 'viewer'}).encode()
    req = urllib.request.Request('http://localhost:8095/api/users', headers=romm_headers, method='POST', data=payload)
    urllib.request.urlopen(req)
    print(f'✅ RM: {user} added.')
except Exception as e: print(f'❌ RM: {e}')

# Jellyfin avatar — DiceBear thumbs in the club palette
try:
    import urllib.parse
    BG_COLORS = [
        'ffb3c6', 'ffd1dc', 'ffdfba', 'ffd6a5', 'fce4ec',
        'fff1a8', 'fde68a', 'ff9baa', 'ffcad4', 'ffddd2', 'ffc8dd', 'ffe5b4',
    ]
    SHAPE_COLORS = [
        'f4a261', 'e9c46a', 'ffb347', 'ff9a8b', 'ffa07a', 'e8a0bf', 'c9b1d0', 'ffcc99',
    ]
    def _pick(palette, seed):
        return palette[int(hashlib.md5(seed.encode()).hexdigest(), 16) % len(palette)]
    bg    = _pick(BG_COLORS,    user)
    shape = _pick(SHAPE_COLORS, user + 'shape')
    avatar_url = (f'https://api.dicebear.com/9.x/thumbs/png'
                  f'?seed={urllib.parse.quote(user)}'
                  f'&backgroundColor={bg}&shapeColor={shape}'
                  f'&backgroundType=gradientLinear&size=256')
    img = urllib.request.urlopen(avatar_url, timeout=15).read()
    # Jellyfin 10.11+ expects base64-encoded body, not raw binary
    import base64
    img_b64 = base64.b64encode(img)
    # look up the new user's JF id
    jf_users = json.loads(urllib.request.urlopen(
        urllib.request.Request('http://localhost:8096/Users',
        headers={'X-Emby-Token': '1980cdafcfec43b58b04b89c4d1f5b99'})).read())
    jf_uid = next((u['Id'] for u in jf_users if u['Name'].lower() == user), None)
    if jf_uid:
        urllib.request.urlopen(urllib.request.Request(
            f'http://localhost:8096/Users/{jf_uid}/Images/Primary', data=img_b64,
            headers={'X-Emby-Token': '1980cdafcfec43b58b04b89c4d1f5b99', 'Content-Type': 'image/png'},
            method='POST'))
    print(f'✅ AV: {user} avatar set.')
except Exception as e: print(f'❌ AV: {e}')
