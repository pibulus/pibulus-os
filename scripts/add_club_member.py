#!/usr/bin/env python3
import hashlib, os, uuid, base64, sqlite3, sys

if len(sys.argv) < 2:
    print('Usage: add_club_member.py username [password]')
    sys.exit(1)

user = sys.argv[1].lower()
pw = sys.argv[2] if len(sys.argv) > 2 else f'{user}123!'
email = f'{user}@quickcat.club'

dbs = {
    'JF': '/home/pibulus/.config/jellyfin/data/jellyfin.db',
    'CW': '/home/pibulus/.config/calibre-web/app.db',
    'KV': '/home/pibulus/.config/kavita/kavita.db',
    'ND': '/home/pibulus/.config/navidrome/navidrome.db'
}

def add_jf(conn, user, pw):
    uid, salt = uuid.uuid4().hex.upper(), os.urandom(16)
    hash_val = hashlib.pbkdf2_hmac('sha512', pw.encode(), salt, 210000)
    jf_hash = f'$PBKDF2-SHA512$iterations=210000${salt.hex().upper()}${hash_val.hex().upper()}'
    conn.execute("""INSERT INTO Users (Id, Username, Password, AuthenticationProviderId, PasswordResetProviderId,
        DisplayCollectionsView, DisplayMissingEpisodes, EnableAutoLogin, EnableLocalPassword,
        EnableNextEpisodeAutoPlay, EnableUserPreferenceAccess, HidePlayedInLatest, InternalId,
        InvalidLoginAttemptCount, MaxActiveSessions, MustUpdatePassword, RowVersion,
        PlayDefaultAudioTrack, RememberAudioSelections, RememberSubtitleSelections, SubtitleMode, SyncPlayAccess
    ) VALUES (?, ?, ?, 'Jellyfin.Server.Implementations.Users.DefaultAuthenticationProvider', 
    'Jellyfin.Server.Implementations.Users.DefaultPasswordResetProvider', 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1)""", 
    (uid, user, jf_hash))

def add_cw(conn, user, pw, email):
    salt = b'salt_' + os.urandom(8)
    hash_val = hashlib.scrypt(pw.encode(), salt=salt, n=32768, r=8, p=1, dklen=64, maxmem=256*1024*1024)
    cw_hash = f'scrypt:32768:8:1${salt.decode("latin1", "ignore")}${hash_val.hex()}'
    conn.execute("INSERT INTO user (name, email, password, role) VALUES (?, ?, ?, 1)", (user, email, cw_hash))

def add_kv(conn, user, pw, email):
    salt = os.urandom(16)
    hash_val = hashlib.pbkdf2_hmac('sha256', pw.encode(), salt, 100000)
    kv_hash = base64.b64encode(b'\x01\x00\x00\x00\x02\x00\x01\x86\xa0\x00\x00\x00\x10' + salt + hash_val).decode()
    conn.execute("""INSERT INTO AspNetUsers (UserName, NormalizedUserName, Email, NormalizedEmail, PasswordHash, SecurityStamp, ConcurrencyStamp, Created, CreatedUtc, LastActive, LastActiveUtc, EmailConfirmed, PhoneNumberConfirmed, TwoFactorEnabled, LockoutEnabled, AccessFailedCount, RowVersion, AgeRestriction, AgeRestrictionIncludeUnknowns) 
    VALUES (?, ?, ?, ?, ?, ?, ?, '2026-03-30 00:00:00', '2026-03-30 00:00:00', '2026-03-30 00:00:00', '2026-03-30 00:00:00', 1, 0, 0, 1, 0, 1, 0, 0)""",
    (user, user.upper(), email, email.upper(), kv_hash, str(uuid.uuid4()), str(uuid.uuid4())))

def add_nd(conn, user, pw, email):
    uid, salt = str(uuid.uuid4()), os.urandom(4)
    nd_hash = base64.b64encode(salt + hashlib.sha256(salt + pw.encode()).digest()).decode()
    conn.execute("INSERT INTO user (id, user_name, name, email, password, is_admin, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
    (uid, user, user, email, nd_hash))

for label, path in dbs.items():
    try:
        conn = sqlite3.connect(path)
        if label == 'JF': add_jf(conn, user, pw)
        elif label == 'CW': add_cw(conn, user, pw, email)
        elif label == 'KV': add_kv(conn, user, pw, email)
        elif label == 'ND': add_nd(conn, user, pw, email)
        conn.commit(); conn.close()
        print(f'✅ {label}: {user} added.')
    except Exception as e: print(f'❌ {label}: {e}')

# RomM (API-based, not SQLite)
try:
    import urllib.request
    auth_str = base64.b64encode(b'pibulus:meringue').decode()
    romm_headers = {'Authorization': f'Basic {auth_str}', 'Content-Type': 'application/json'}
    payload = json.dumps({'username': user, 'password': pw, 'email': email, 'role': 'viewer'}).encode()
    req = urllib.request.Request('http://localhost:8095/api/users', headers=romm_headers, method='POST', data=payload)
    urllib.request.urlopen(req)
    print(f'✅ RM: {user} added.')
except Exception as e: print(f'❌ RM: {e}')
