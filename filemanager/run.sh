#!/bin/sh
# Starts the server with the add-on options (/data/options.json) as FM_* settings.
set -eu

OPTIONS=${OPTIONS:-/data/options.json}
SUPERVISOR=${SUPERVISOR:-http://supervisor}

# opt prints an option; lists are joined with commas, a missing option prints nothing.
opt() { jq -r --arg k "$1" '.[$k] | if . == null then empty elif type == "array" then join(",") else tostring end' "$OPTIONS"; }

supervisor() {
	[ -n "${SUPERVISOR_TOKEN:-}" ] || return 1
	curl -fsS --max-time 5 -H "Authorization: Bearer $SUPERVISOR_TOKEN" "$SUPERVISOR$1"
}

# Home addresses the phone tries first (direct at home, the relay elsewhere): the ones set in the
# options, otherwise the host's addresses and the port published for 8080/tcp.
local_urls() {
	urls=$(opt local_urls)
	if [ -n "$urls" ]; then
		echo "$urls"
		return
	fi
	port=$(supervisor /addons/self/info | jq -r '.data.network["8080/tcp"] // empty') || return 0
	[ -n "$port" ] || return 0
	supervisor /network/info | jq -r --arg port "$port" '
		[.data.interfaces[] | select(.enabled and .connected) | .ipv4.address[]? | split("/")[0]
		 | "http://\(.):\($port)"] | join(",")' || true
}

FM_DATA_DIR=/data/filemanager
FM_BLOB_DIR="$(opt storage_dir)/blobs"
FM_ALLOW_SIGNUP=$(opt allow_signup)
FM_TRASH_DAYS=$(opt trash_days)
FM_LOG_LEVEL=$(opt log_level)
FM_LOCAL_URLS=$(local_urls)
export FM_DATA_DIR FM_BLOB_DIR FM_ALLOW_SIGNUP FM_TRASH_DAYS FM_LOG_LEVEL FM_LOCAL_URLS

relay_url=$(opt relay_url)
relay_token=$(opt relay_token)
if [ -n "$relay_url" ] && [ -n "$relay_token" ]; then
	export FM_RELAY_URL="$relay_url" FM_RELAY_TOKEN="$relay_token"
elif [ -n "$relay_url$relay_token" ]; then
	echo "relay_url and relay_token go together; relay is off" >&2
fi

# Files written by the server belong to 65532. Fix ownership only when it is wrong: walking a
# large photo library on every start would take minutes on a Raspberry Pi.
for dir in "$FM_DATA_DIR" "$FM_BLOB_DIR"; do
	mkdir -p "$dir"
	if [ "$(stat -c %u "$dir")" != 65532 ]; then
		chown -R 65532:65532 "$dir"
	fi
done

echo "FileManager: data in $FM_DATA_DIR, files in $FM_BLOB_DIR, home addresses: ${FM_LOCAL_URLS:-none}"
exec su-exec 65532:65532 filemanager
