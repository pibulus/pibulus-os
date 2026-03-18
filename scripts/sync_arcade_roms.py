#!/usr/bin/env python3
import json
import re
from pathlib import Path

OUTPUTS = [
    Path('/media/pibulus/passport/www/html/arcade/games.json'),
    Path('/media/pibulus/passport/www/html/arcade/retro/games.json'),
    Path('/home/pibulus/pibulus-os/www/html/arcade/games.json'),
    Path('/home/pibulus/pibulus-os/www/html/arcade/retro/games.json'),
]

LIMITS = {}

SYSTEMS = [
    {
        'id': 'megadrive',
        'source': Path('/media/pibulus/passport/Roms/megadrive/openemu'),
        'allowed_exts': {'.zip', '.bin', '.gen', '.md'},
        'cue_only': False,
    },
    {
        'id': 'psx',
        'source': Path('/media/pibulus/passport/Roms/psx'),
        'allowed_exts': {'.chd', '.cue', '.pbp', '.PBP', '.iso', '.bin', '.7z'},
        'cue_only': False,
    },
    {
        'id': 'gb',
        'source': Path('/media/pibulus/MEMBOT/Roms/Game Boy'),
        'allowed_exts': {'.zip', '.gb', '.gbc'},
        'cue_only': False,
    },
    {
        'id': 'gba',
        'source': Path('/media/pibulus/MEMBOT/Roms/Game Boy Advance'),
        'allowed_exts': {'.zip', '.gba'},
        'cue_only': False,
    },
    {
        'id': 'nes',
        'source': Path('/media/pibulus/MEMBOT/Roms/Nintendo (NES)'),
        'allowed_exts': {'.zip', '.nes'},
        'cue_only': False,
    },
    {
        'id': 'n64',
        'source': Path('/media/pibulus/MEMBOT/Roms/Nintendo 64'),
        'allowed_exts': {'.zip', '.n64', '.z64', '.v64'},
        'cue_only': False,
    },
    {
        'id': 'snes',
        'source': Path('/media/pibulus/MEMBOT/Roms/Super Nintendo (SNES)'),
        'allowed_exts': {'.zip', '.sfc', '.smc'},
        'cue_only': False,
    },
    {
        'id': 'tg16',
        'source': Path('/media/pibulus/MEMBOT/Roms/TurboGrafx-16'),
        'allowed_exts': {'.zip', '.pce'},
        'cue_only': False,
    },
]

REGION_RE = re.compile(r'\(([^)]*)\)')
STRIP_TRAIL_RE = re.compile(r'\s*(\([^)]*\)|\[[^]]*\])+$')


def infer_region(name: str) -> str:
    for match in REGION_RE.findall(name):
        for token in [part.strip() for part in match.split(',')]:
            if token in {'USA', 'Europe', 'Japan', 'World', 'Australia'}:
                return token
            if token in {'U', 'US'}:
                return 'USA'
            if token == 'EU':
                return 'Europe'
            if token == 'JP':
                return 'Japan'
    return ''


def prettify_title(stem: str) -> str:
    title = STRIP_TRAIL_RE.sub('', stem).strip()
    title = title.replace('_', ' ')
    return re.sub(r'\s+', ' ', title)


def file_entry(system_id: str, base: Path, path: Path):
    rel = '/'.join([system_id, *path.relative_to(base).parts])
    return {
        'file': rel,
        'title': prettify_title(path.stem),
        'system': system_id,
        'region': infer_region(path.name),
    }


def collect_system(spec):
    source = spec['source']
    allowed = spec['allowed_exts']
    cue_only = spec['cue_only']
    items = []
    if not source.exists():
        return items
    for path in sorted(source.rglob('*')):
        if not path.is_file():
            continue
        if path.name.startswith('._'):
            continue
        if path.suffix.lower() not in allowed:
            continue
        if cue_only and path.suffix.lower() != '.cue':
            continue
        items.append(file_entry(spec['id'], source, path))
    return items


def atomic_write(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + '.tmp')
    tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n')
    tmp.replace(path)


def main():
    games = []
    for spec in SYSTEMS:
        games.extend(collect_system(spec))
    games.sort(key=lambda g: (g['system'], g['title'].lower(), g['file'].lower()))

    limited = []
    counters = {}
    for game in games:
        limit = LIMITS.get(game['system'])
        count = counters.get(game['system'], 0)
        if limit is not None and count >= limit:
            continue
        counters[game['system']] = count + 1
        limited.append(game)
    games = limited
    for out in OUTPUTS:
        atomic_write(out, games)
    counts = {}
    for game in games:
        counts[game['system']] = counts.get(game['system'], 0) + 1
    print(json.dumps({'total': len(games), 'counts': counts}, indent=2))


if __name__ == '__main__':
    main()
