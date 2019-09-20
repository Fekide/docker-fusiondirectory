#!/usr/bin/env bats

@test "initialize" {
    docker swarm init
    run docker run --label bats-type="test" -p 8085:80 \
        -e LDAP_DOMAIN="example.org" \
        -e LDAP_HOST="ldap.example.org" \
        -e LDAP_ADMIN_PASSWORD="password" \
        -d fekide/fusiondirectory:bats
    [ "${status}" -eq 0 ]
    until curl --head localhost:8085/fusiondirectory
    do
        sleep 1
    done
}

@test "missing arguments" {
    run docker run --label bats-type="test" -p 8085:80 \
        -e LDAP_DOMAIN="example.org" \
        -e LDAP_HOST="ldap.example.org" \
        fekide/fusiondirectory:bats
    [ "${status}" -eq 1 ]
    run docker run --label bats-type="test" -p 8085:80 \
        -e LDAP_DOMAIN="example.org" \
        fekide/fusiondirectory:bats
    [ "${status}" -eq 1 ]
    run docker run --label bats-type="test" -p 8085:80 \
        fekide/fusiondirectory:bats
    [ "${status}" -eq 1 ]
}

@test "secret" {
    printf "secret_password" | docker secret create bats_secret_pwd -l bats-type="test" -

    run docker service create --label bats-type="test" -p 8085:80 \
        -e LDAP_DOMAIN="example.org" \
        -e LDAP_HOST="ldap.example.org" \
        -e LDAP_ADMIN_PASSWORD_FILE="/run/secrets/bats_secret_pwd"\
        --secret bats_secret_pwd \
        --name fd_bats_secrets\
        -d fekide/fusiondirectory:bats
    
    until docker service ps --format "{{.CurrentState}}" fd_bats_secrets | grep Running
    do
        sleep 1
    done
}

function teardown() {
    SERVICE_IDS="$(docker service ls -q --filter label=bats-type)"
    if [ ${#SERVICE_IDS[@]} -gt 0 ]; then
        echo "docker service rm ${SERVICE_IDS[@]}"
        docker service rm ${SERVICE_IDS[@]}
    fi
    CONTAINER_IDS="$(docker ps -q --filter label=bats-type)"
    if [ ${#CONTAINER_IDS[@]} -gt 0 ]; then
        echo "docker stop ${CONTAINER_IDS[@]}"
        docker stop ${CONTAINER_IDS[@]}
    fi
    CONTAINER_IDS="$(docker ps -q -a --filter label=bats-type)"
    if [ ${#CONTAINER_IDS[@]} -gt 0 ]; then
        echo "docker rm ${CONTAINER_IDS[@]}"
        docker rm ${CONTAINER_IDS[@]}
    fi
    SECRET_IDS="$(docker secret ls -q -f label=bats-type)"
    if [ ${#SECRET_IDS[@]} -gt 0 ]; then
        echo "docker secret rm ${SECRET_IDS[@]}"
        docker secret rm ${SECRET_IDS[@]}
    fi

    SERVICE_IDS=/dev/null
    CONTAINER_IDS=/dev/null
    SECRET_IDS=/dev/null
}
