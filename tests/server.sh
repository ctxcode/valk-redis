#!/usr/bin/env bash
# Starts or stops the Redis servers the tests run against: a plain one, and one that only
# accepts TLS, with a self-signed certificate generated here.
set -e

NAME=valk-redis-test
TLS_NAME=valk-redis-test-tls
MASTER_NAME=valk-redis-master
REPLICA_NAME=valk-redis-replica
SENTINEL_NAME=valk-redis-sentinel
PORT=${REDIS_PORT:-6399}
TLS_PORT=${REDIS_TLS_PORT:-6400}
MASTER_PORT=${REDIS_MASTER_PORT:-6401}
REPLICA_PORT=${REDIS_REPLICA_PORT:-6402}
SENTINEL_PORT=${REDIS_SENTINEL_PORT:-6403}
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

        # A primary, a replica of it, and a sentinel watching them, for connect_sentinel
        if [ -n "$(docker ps -aq -f name=^${MASTER_NAME}$)" ]; then
            docker start ${MASTER_NAME} >/dev/null
        else
            docker run -d --name ${MASTER_NAME} --network host ${IMAGE} \
                redis-server --port ${MASTER_PORT} >/dev/null
        fi
        if [ -n "$(docker ps -aq -f name=^${REPLICA_NAME}$)" ]; then
            docker start ${REPLICA_NAME} >/dev/null
        else
            docker run -d --name ${REPLICA_NAME} --network host ${IMAGE} \
                redis-server --port ${REPLICA_PORT} --replicaof 127.0.0.1 ${MASTER_PORT} >/dev/null
        fi
        if [ -n "$(docker ps -aq -f name=^${SENTINEL_NAME}$)" ]; then
            docker start ${SENTINEL_NAME} >/dev/null
        else
            # Sentinel writes to its own config, so it gets a copy of its own
            mkdir -p "${CERTS}"
            cat > "${CERTS}/sentinel.conf" <<CONF
port ${SENTINEL_PORT}
sentinel monitor valk-test 127.0.0.1 ${MASTER_PORT} 1
sentinel down-after-milliseconds valk-test 1000
sentinel failover-timeout valk-test 5000
CONF
            chmod 666 "${CERTS}/sentinel.conf"
            docker run -d --name ${SENTINEL_NAME} --network host \
                -v "${CERTS}/sentinel.conf":/etc/sentinel.conf ${IMAGE} \
                redis-sentinel /etc/sentinel.conf >/dev/null
        fi
        echo "redis primary on 127.0.0.1:${MASTER_PORT}, replica on ${REPLICA_PORT}, sentinel on ${SENTINEL_PORT}"
        ;;
    down)
        docker rm -f ${NAME} ${TLS_NAME} ${MASTER_NAME} ${REPLICA_NAME} ${SENTINEL_NAME} >/dev/null 2>&1 || true
        rm -rf "${CERTS}"
        echo "removed the test servers"
        ;;
    *)
        echo "usage: $0 [up|down]" >&2
        exit 1
        ;;
esac
