#!/usr/bin/env bash
# Starts or stops the Redis servers the tests run against: a plain one, and one that only
# accepts TLS, with a self-signed certificate generated here.
set -e

NAME=valk-redis-test
TLS_NAME=valk-redis-test-tls
PORT=${REDIS_PORT:-6399}
TLS_PORT=${REDIS_TLS_PORT:-6400}
IMAGE=${REDIS_IMAGE:-redis:7-alpine}
CERTS="$(cd "$(dirname "$0")" && pwd)/certs"

case "${1:-up}" in
    up)
        if [ -n "$(docker ps -aq -f name=^${NAME}$)" ]; then
            docker start ${NAME} >/dev/null
        else
            docker run -d --name ${NAME} -p ${PORT}:6379 ${IMAGE} >/dev/null
        fi
        echo "redis listening on 127.0.0.1:${PORT}"

        if [ ! -f "${CERTS}/server.crt" ]; then
            mkdir -p "${CERTS}"
            openssl req -new -x509 -days 3650 -nodes -subj "/CN=localhost" \
                -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" \
                -keyout "${CERTS}/server.key" -out "${CERTS}/server.crt" 2>/dev/null
            chmod 644 "${CERTS}/server.key"
        fi
        if [ -n "$(docker ps -aq -f name=^${TLS_NAME}$)" ]; then
            docker start ${TLS_NAME} >/dev/null
        else
            docker run -d --name ${TLS_NAME} -p ${TLS_PORT}:6379 \
                -v "${CERTS}":/certs:ro ${IMAGE} \
                redis-server --port 0 --tls-port 6379 \
                --tls-cert-file /certs/server.crt \
                --tls-key-file /certs/server.key \
                --tls-ca-cert-file /certs/server.crt \
                --tls-auth-clients no >/dev/null
        fi
        echo "redis over tls listening on 127.0.0.1:${TLS_PORT}"
        ;;
    down)
        docker rm -f ${NAME} ${TLS_NAME} >/dev/null 2>&1 || true
        rm -rf "${CERTS}"
        echo "removed ${NAME} and ${TLS_NAME}"
        ;;
    *)
        echo "usage: $0 [up|down]" >&2
        exit 1
        ;;
esac
