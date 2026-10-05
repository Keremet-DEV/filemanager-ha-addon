#!/bin/sh
# Builds the add-on and runs it the way the Supervisor does: options in /data/options.json,
# /share mapped, the Supervisor API answering with the host's addresses (a stub here).
#
#   scripts/test.sh [server image]   (default: the tag from sandyk/build.yaml)
set -eu
cd "$(dirname "$0")/.."

base=${1:-$(sed -n 's/^ *amd64: *//p' sandyk/build.yaml)}
name=fm-addon-test-$$
net=$name
work=$(mktemp -d)
cleanup() {
	docker rm -f "$name" "$name-supervisor" >/dev/null 2>&1 || true
	docker network rm "$net" >/dev/null 2>&1 || true
	docker run --rm -v "$work:/w" alpine:3.22 rm -rf /w/data /w/share >/dev/null 2>&1 || true
	rm -rf "$work"
}
trap cleanup EXIT

docker build -q --build-arg "BUILD_FROM=$base" -t "$name" sandyk >/dev/null
docker network create "$net" >/dev/null

# The Supervisor API stub: the published port and the host's network.
mkdir -p "$work/supervisor/addons/self" "$work/supervisor/network" "$work/data" "$work/share"
echo '{"data":{"network":{"8080/tcp":8123}}}' >"$work/supervisor/addons/self/info"
echo '{"data":{"interfaces":[
  {"enabled":true,"connected":true,"ipv4":{"address":["192.168.1.20/24"]}},
  {"enabled":true,"connected":false,"ipv4":{"address":["10.0.0.5/8"]}}]}}' >"$work/supervisor/network/info"
docker run -d --name "$name-supervisor" --network "$net" --network-alias supervisor \
	-v "$work/supervisor:/srv:ro" busybox:1.37 httpd -f -p 80 -h /srv >/dev/null

run() {
	echo "$1" >"$work/data/options.json"
	docker rm -f "$name" >/dev/null 2>&1 || true
	docker run -d --name "$name" --network "$net" -e SUPERVISOR_TOKEN=test \
		-v "$work/data:/data" -v "$work/share:/share" "$name" >/dev/null
	for _ in $(seq 1 30); do
		if docker exec "$name" sandyk healthcheck >/dev/null 2>&1; then return 0; fi
		sleep 1
	done
	docker logs "$name"
	echo "FAIL: the server did not start" >&2
	exit 1
}
server() { docker exec "$name" wget -qO- http://127.0.0.1:8080/api/v1/server; }
check() {
	if ! echo "$2" | grep -q -- "$3"; then
		echo "FAIL: $1: want $3 in: $2" >&2
		exit 1
	fi
	echo "ok: $1"
}

# Defaults: home address found through the Supervisor, files in /share, owned by the server.
run '{"storage_dir":"/share/sandyk","local_urls":[],"allow_signup":false,"trash_days":30,"log_level":"info"}'
check "home address from the Supervisor" "$(server)" '"local_urls":\["http://192.168.1.20:8123"\]'
check "first user may sign up" "$(server)" '"signup_open":true'
check "files in /share" "$(docker exec "$name" stat -c '%u %n' /share/sandyk/blobs)" '^65532 /share/sandyk/blobs'
check "database in /data/sandyk" "$(docker exec "$name" ls /data/sandyk)" 'filemanager.db'
check "runs as 65532" "$(docker exec "$name" sh -c 'stat -c %u /proc/$(pidof sandyk)')" '^65532$'

# Addresses set in the options win; a relay without a token is refused, not half-configured.
run '{"storage_dir":"/share/sandyk","local_urls":["http://ha.lan:8080","http://192.168.1.20:8080"],"allow_signup":true,"trash_days":7,"log_level":"debug","relay_url":"wss://r.example.org"}'
check "home addresses from the options" "$(server)" '"local_urls":\["http://ha.lan:8080","http://192.168.1.20:8080"\]'
check "relay needs a token" "$(docker logs "$name" 2>&1)" 'relay_url and relay_token go together'
echo "all ok"
