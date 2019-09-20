#!/usr/bin/env bats

@test "initialize" {
    run docker run --label bats-type="test" -p 8084:80 \
        -e LDAP_DOMAIN="example.org" \
        -e LDAP_HOST="ldap.example.org" \
        -e LDAP_ADMIN_PASSWORD="password" \
        -d fekide/fusiondirectory:bats
    [ "${status}" -eq 0 ]
    until curl --head localhost:8084
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
@test "cleanup" {
    CIDS=$(docker ps -q --filter "label=bats-type")
    if [ ${#CIDS[@]} -gt 0 ]; then
        run docker stop ${CIDS[@]}
    fi
    CIDS=$(docker ps -q -a --filter "label=bats-type")
    if [ ${#CIDS[@]} -gt 0 ]; then
        run docker rm ${CIDS[@]}
    fi
}
