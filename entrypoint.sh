#!/bin/bash -e

echo "Starting FusionDirectory ... "

# Read environment variable from file -> for docker secrets 
# (Source: https://github.com/docker-library/wordpress/blob/master/docker-entrypoint.sh)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(<"${!fileVar}")"
	fi
	echo ${val}
	if [ -z ${val} ]; then
		echo >&2 "error: neither $var nor $fileVar are set but are required"
		exit 1
	fi
	export "$var"="$val"
	unset "$fileVar"
}

required_envs=(
	LDAP_DOMAIN
	LDAP_HOST
	LDAP_ADMIN_PASSWORD
)

for e in "${required_envs[@]}"; do
	file_env "$e"
done

BASE_DN="dc=$(echo ${LDAP_DOMAIN} | sed 's/^\.//; s/\.$//; s/\./,dc=/g')"

if [ -z ${LDAP_ADMIN_DN} ]; then
	: ${LDAP_ADMIN:="admin"}
	LDAP_ADMIN_DN="cn=${LDAP_ADMIN},${BASE_DN}"

	printf "\n\nLDAP_ADMIN_DN is not defined and set to '${LDAP_ADMIN_DN}'\n"
fi

file_env LDAP_TLS "false"
file_env LDAP_SCHEME "ldap"
file_env LDAP_COMM_PORT 389

if ${LDAP_TLS}; then
	LDAP_SCHEME="ldaps"
	LDAP_COMM_PORT=636
fi

cat <<EOF >/etc/fusiondirectory/fusiondirectory.conf
<?xml version="1.0"?>
<conf>
  <!-- Main section **********************************************************
       The main section defines global settings, which might be overridden by
       each location definition inside.

       For more information about the configuration parameters, take a look at
       the FusionDirectory.conf(5) manual page.
  -->
  <main default="default"
        logging="TRUE"
        displayErrors="FALSE"
        forceSSL="FALSE"
        templateCompileDirectory="/var/spool/fusiondirectory/"
        debugLevel="0"
    >

    <!-- Location definition -->
    <location name="default"
    >
        <referral URI="${LDAP_SCHEME}://${LDAP_HOST}:${LDAP_COMM_PORT}/${BASE_DN}"
                        adminDn="${LDAP_ADMIN_DN}"
                        adminPassword="${LDAP_ADMIN_PASSWORD}" />
    </location>
  </main>
</conf>
EOF

chmod 640 /etc/fusiondirectory/fusiondirectory.conf
chown root:www-data /etc/fusiondirectory/fusiondirectory.conf

yes Yes | fusiondirectory-setup --check-config

exec "/sbin/cmd.sh"