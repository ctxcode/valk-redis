#!/usr/bin/env bash
# Starts or stops the Redis servers the tests run against: a plain one, one that only accepts
# TLS, with a self-signed certificate generated here, and one that also wants a client
# certificate signed by a test CA generated here. Also a primary with a replica behind a sentinel,
# and a cluster of three primaries with a replica each.
set -e

NAME=valk-redis-test
TLS_NAME=valk-redis-test-tls
MTLS_NAME=valk-redis-test-mtls
MASTER_NAME=valk-redis-master
REPLICA_NAME=valk-redis-replica
SENTINEL_NAME=valk-redis-sentinel
PORT=${REDIS_PORT:-6399}
TLS_PORT=${REDIS_TLS_PORT:-6400}
MTLS_PORT=${REDIS_MTLS_PORT:-6404}
MASTER_PORT=${REDIS_MASTER_PORT:-6401}
REPLICA_PORT=${REDIS_REPLICA_PORT:-6402}
SENTINEL_PORT=${REDIS_SENTINEL_PORT:-6403}
CLUSTER_NAME=valk-redis-cluster
CLUSTER_PORT=${REDIS_CLUSTER_PORT:-7101} # six nodes from here, bus ports 10000 higher
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

        # A client certificate for the tests, its key also stored encrypted (password: secret)
        if [ ! -f "${CERTS}/client.crt" ]; then
            openssl req -new -x509 -days 3650 -nodes -subj "/CN=valk-redis client CA" \
                -keyout "${CERTS}/client-ca.key" -out "${CERTS}/client-ca.crt" 2>/dev/null
            openssl req -new -nodes -subj "/CN=valk-redis test client" \
                -keyout "${CERTS}/client.key" -out "${CERTS}/client.csr" 2>/dev/null
            openssl x509 -req -in "${CERTS}/client.csr" -CA "${CERTS}/client-ca.crt" \
                -CAkey "${CERTS}/client-ca.key" -CAcreateserial -days 3650 \
                -out "${CERTS}/client.crt" 2>/dev/null
            openssl pkey -in "${CERTS}/client.key" -aes256 -passout pass:secret \
                -out "${CERTS}/client-encrypted.key"
            rm -f "${CERTS}/client.csr"
        fi
        if [ -n "$(docker ps -aq -f name=^${MTLS_NAME}$)" ]; then
            docker start ${MTLS_NAME} >/dev/null
        else
            docker run -d --name ${MTLS_NAME} -p ${MTLS_PORT}:6379 \
                -v "${CERTS}":/certs:ro ${IMAGE} \
                redis-server --port 0 --tls-port 6379 \
                --tls-cert-file /certs/server.crt \
                --tls-key-file /certs/server.key \
                --tls-ca-cert-file /certs/client-ca.crt \
                --tls-auth-clients yes >/dev/null
        fi
        echo "redis over tls with client certificates listening on 127.0.0.1:${MTLS_PORT}"

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

        # A cluster of three primaries with a replica each
        NODES=""
        for i in 0 1 2 3 4 5; do
            port=$((CLUSTER_PORT + i))
            NODES="${NODES} 127.0.0.1:${port}"
            if [ -n "$(docker ps -aq -f name=^${CLUSTER_NAME}-${i}$)" ]; then
                docker start ${CLUSTER_NAME}-${i} >/dev/null
            else
                docker run -d --name ${CLUSTER_NAME}-${i} --network host ${IMAGE} \
                    redis-server --port ${port} --cluster-enabled yes \
                    --cluster-node-timeout 2000 --cluster-announce-ip 127.0.0.1 \
                    --repl-ping-replica-period 1 \
                    --appendonly no --save "" >/dev/null
            fi
        done
        for i in $(seq 50); do
            docker exec ${CLUSTER_NAME}-0 redis-cli -p ${CLUSTER_PORT} ping >/dev/null 2>&1 && break
            sleep 0.2
        done
        if ! docker exec ${CLUSTER_NAME}-0 redis-cli -p ${CLUSTER_PORT} cluster info | grep -q "cluster_slots_assigned:16384"; then
            for i in $(seq 50); do
                ok=1
                for n in ${NODES}; do
                    docker exec ${CLUSTER_NAME}-0 redis-cli -p ${n##*:} ping >/dev/null 2>&1 || ok=0
                done
                [ $ok = 1 ] && break
                sleep 0.2
            done
            docker exec ${CLUSTER_NAME}-0 redis-cli --cluster create ${NODES} \
                --cluster-replicas 1 --cluster-yes >/dev/null
        fi
        for i in $(seq 100); do
            docker exec ${CLUSTER_NAME}-0 redis-cli -p ${CLUSTER_PORT} cluster info | grep -q "cluster_state:ok" && break
            sleep 0.2
        done
        # Until every node lists all six in CLUSTER SLOTS, which leaves out a replica that has
        # not replicated anything yet
        PORTS="^($(seq -s '|' ${CLUSTER_PORT} $((CLUSTER_PORT + 5))))$"
        for i in $(seq 150); do
            ready=0
            for n in ${NODES}; do
                [ "$(docker exec ${CLUSTER_NAME}-0 redis-cli -p ${n##*:} cluster slots | grep -cE "${PORTS}")" = 6 ] && ready=$((ready + 1))
            done
            [ $ready = 6 ] && break
            sleep 0.2
        done
        echo "redis cluster on 127.0.0.1:${CLUSTER_PORT}-$((CLUSTER_PORT + 5))"
        ;;
    down)
        docker rm -f ${NAME} ${TLS_NAME} ${MTLS_NAME} ${MASTER_NAME} ${REPLICA_NAME} ${SENTINEL_NAME} \
            ${CLUSTER_NAME}-0 ${CLUSTER_NAME}-1 ${CLUSTER_NAME}-2 ${CLUSTER_NAME}-3 ${CLUSTER_NAME}-4 ${CLUSTER_NAME}-5 >/dev/null 2>&1 || true
        rm -rf "${CERTS}"
        echo "removed the test servers"
        ;;
    *)
        echo "usage: $0 [up|down]" >&2
        exit 1
        ;;
esac
