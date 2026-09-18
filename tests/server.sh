#!/usr/bin/env bash
# Starts or stops the Redis the tests run against.
set -e

NAME=valk-redis-test
PORT=${REDIS_PORT:-6399}
IMAGE=${REDIS_IMAGE:-redis:7-alpine}

case "${1:-up}" in
    up)
        if [ -n "$(docker ps -aq -f name=^${NAME}$)" ]; then
            docker start ${NAME} >/dev/null
        else
            docker run -d --name ${NAME} -p ${PORT}:6379 ${IMAGE} >/dev/null
        fi
        echo "redis listening on 127.0.0.1:${PORT}"
        ;;
    down)
        docker rm -f ${NAME} >/dev/null 2>&1 || true
        echo "removed ${NAME}"
        ;;
    *)
        echo "usage: $0 [up|down]" >&2
        exit 1
        ;;
esac
