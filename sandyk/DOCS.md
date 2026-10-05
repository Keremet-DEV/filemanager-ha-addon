# Sandyk

Backup of photos, videos and files from phones to your Home Assistant, a duplicate finder,
and space freed on the phone. Phones at home connect directly; from outside — through a relay,
no public IP needed.

## Getting started

1. Start the add-on and open the web UI (**Open web UI**). Register: the first user becomes the
   admin. Registration then closes unless **Open registration** is on; the admin adds people in
   **Settings → Users**.
2. In the phone app connect to a server at `http://<Home Assistant address>:8080` and sign in.

## Options

- **Where to keep files** (`storage_dir`): photos, videos and files, by default
  `/share/sandyk`. An external drive works: mount it in **Settings → System → Storage**
  and point this to `/media/<drive>/sandyk`. Moving it later: stop the add-on, move the
  `blobs` folder, change the option, start.
- **Home addresses** (`local_urls`): left empty, the add-on announces the host's addresses with
  the published port, so phones at home skip the relay.
- **Relay** (`relay_url`, `relay_token`): access from outside without a public IP. The server
  then answers at `https://<name>.<relay domain>`; certificates are issued for your server, the
  relay only forwards encrypted traffic.
- **Days in trash** (`trash_days`), **Log level** (`log_level`).

## Backups

The database (accounts, folders, albums) lives in the add-on's data and is in Home Assistant
backups; the server also keeps 7 daily snapshots of it. The files in `storage_dir` are in a
backup only if the backup includes that folder (`share` or `media`) — a photo library may be
too big for that; keep a copy of the folder elsewhere instead.
