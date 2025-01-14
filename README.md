# docker-fusiondirectory

Dockerfile to build a [FusionDirectory](https://www.fusiondirectory.org/)
container image.

[![Travis Build Status](https://travis-ci.org/Fekide/docker-fusiondirectory.svg?branch=master)](https://travis-ci.org/Fekide/docker-fusiondirectory)


## Quick Start

The easiest way to launch the container is using [docker-compose](https://docs.docker.com/compose/):

``` shell
wget https://raw.githubusercontent.com/fekide/docker-fusiondirectory/master/example/docker-compose.yml
docker-compose up
```

Otherwise, you can manually launch the container using the docker command:

``` shell
docker run -p 80:80 \
  -e LDAP_DOMAIN="example.org" \
  -e LDAP_HOST="ldap.example.org" \
  -e LDAP_ADMIN_PASSWORD="password" \
  -d fekide/fusiondirectory:latest
```

Alternatively, you can link this container with a previously launched LDAP
container image as follows:

``` shell
docker run --name ldap -p 389:389 \
  -e LDAP_ORGANISATION="Example Organization" \
  -e LDAP_DOMAIN="example.org" \
  -e LDAP_ADMIN_PASSWORD="password" \
  -e FD_ADMIN_PASSWORD="fdadminpassword" \
  -d fekide/fusiondirectory-openldap:latest

docker run --name fusiondirectory -p 80:80 --link ldap:ldap \
  -e LDAP_DOMAIN="example.org" \
  -e LDAP_HOST="ldap" \
  -e LDAP_ADMIN_PASSWORD="password" \
  -d fekide/fusiondirectory:latest
```

Access `http://localhost:80` with your browser and login using the
administrator account:

- username: fd-admin
- password: (the value you specified in FD_ADMIN_PASSWORD)
