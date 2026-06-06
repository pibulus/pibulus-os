# Tunarr Restore Checklist

This is for moving the existing Tunarr state to a future server. It is not an instruction to start Tunarr on the Pi.

## Known Source

Pi app-data path:

```text
/media/pibulus/passport/app-data/tunarr
```

Important surviving files and folders:

- `db.db`
- `settings.json`
- `channel-lineups/`
- `images/` if present
- `cache/` if present
- `*.xml`

The search index can be rebuilt. Do not treat `data.ms/` as precious.

## Minimal Copy

From the Pi, copy only the known Tunarr app-data directory, not the whole Passport:

```bash
rsync -a --info=progress2 \
  pibulus@192.168.0.40:/media/pibulus/passport/app-data/tunarr/ \
  ./data/tunarr/
```

## New Server Mount

In `docker-compose.dormant.yml`, mount that directory to:

```text
/config/tunarr
```

## First Boot Checks

1. Start privately on localhost only.
2. Confirm the web UI sees channels 1-4.
3. Update the Jellyfin media source URL. The old source was Docker-bridge-local to the Pi:

```text
http://172.17.0.1:8096
```

Use the new server's reachable Jellyfin URL instead.

4. Confirm each channel can generate an HLS stream locally.
5. Check CPU/GPU load during one stream before trying multiple streams.

## Known Old Channel Shape

| Number | Name | Notes |
| --- | --- | --- |
| 1 | Quick Cat TV | General movie/channel mix |
| 2 | PIBULUS PRIME | Included ALF and classic show blocks |
| 3 | THE MARATHON | Film marathon channel |
| 4 | CHANNEL Z | Adventure Time-heavy channel |

## Backup Notes

Before changing the migrated data, create a backup from the Tunarr UI or API. A backup should include the SQLite DB, settings, lineups, media assets, and XMLTV files. If Meilisearch snapshots are excluded, Tunarr can rebuild them later.
