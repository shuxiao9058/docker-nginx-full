#!/bin/bash
set -e

if [ -z "$1" ]; then
	echo "Usage: $0 <image>"
	exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
PROJ_DIR="$(cd "$SCRIPT_DIR/../../test" && pwd)"
cd "$PROJ_DIR"

export IMAGE_TAG="$1"
export COMPOSE_PROJECT_NAME="nginxfulltest"

# Colors
RED='\E[1;31m'
GREEN='\E[1;32m'
RESET='\E[0m'

start_containers() {
	docker compose pull
	docker compose up -d
}

stop_containers() {
	docker compose down --remove-orphans
}

dump_logs() {
	local dump_dir="$1"
	local service="$2"
	docker compose logs --no-color "$service" &>"$dump_dir/docker_$service.log.txt" || true
	echo "========================="
	cat "$dump_dir/docker_$service.log.txt"
	echo "========================="
}

run_dumps() {
	local dump_dir="$PROJ_DIR/results"
	rm -rf "$dump_dir"
	mkdir -p "$dump_dir"
	dump_logs "$dump_dir" 'nginx'
}

cleanup() {
	if [ "$?" != 0 ]; then
		echo
		echo -e "${RED}Something went wrong, Docker logs may provide some insight:${RESET}"
		run_dumps
	fi
	stop_containers
}

run_test_a() {
	local result
	result="$(docker compose exec -T nginx curl -s 'http://127.0.0.1:8080')"
	# check if result contains "Test page"
	if [[ "$result" != *"Test Page"* ]]; then
		echo -e "❌ ${RED}Test A failed${RESET}"
		echo "Unexpected result: $result"
		exit 1
	fi
	echo -e "✅ ${GREEN}Test A passed${RESET}"
}

run_test_b() {
	local result
	result="$(docker compose exec -T nginx curl -s 'http://127.0.0.1:8080/lua')"
	# check if result contains "Test page"
	if [[ "$result" != *"Test Page"* ]]; then
		echo -e "❌ ${RED}Test B failed${RESET}"
		echo "Unexpected result: $result"
		exit 1
	fi
	echo -e "✅ ${GREEN}Test B passed${RESET}"
}

trap 'cleanup' EXIT

echo "========================="
docker compose config
echo "========================="
start_containers
run_test_a
run_test_b
stop_containers
