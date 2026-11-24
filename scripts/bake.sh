#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
PROJ_DIR="$(readlink -f "$SCRIPT_DIR/..")"

echo -e "${BLUE}❯ ${CYAN}Docker bake: ${YELLOW}${*}${RESET}"

cd "${PROJ_DIR}" || exit 1

NOW="$(date '+%Y-%m-%d %T %Z')"
export NOW

trap cleanup EXIT
cleanup() {
	if [ "$?" -ne 0 ]; then
		echo -e "${RED}Bake FAILED - check output${RESET}"
	else
		echo -e "${BLUE}❯ ${GREEN}Bake Complete${RESET}"
	fi
	docker buildx rm "${BUILDX_NAME:-nginxfull}"
}

# Buildx Builder
docker buildx create --name "${BUILDX_NAME:-nginxfull}" || echo
docker buildx use "${BUILDX_NAME:-nginxfull}"
docker buildx bake --file docker/docker-bake.hcl --progress=plain $@
