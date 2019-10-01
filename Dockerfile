FROM nginx:latest
LABEL maintainer="it@feki.de" \
	version="0.3.0"

ENV FUSIONDIRECTORY_VERSION=1.3-1

RUN apt-get update && \
	apt-get install -y gnupg \
	ca-certificates && \
	set -e; \
	export GNUPGHOME="/tmp/gnupg_home" && \
	mkdir -p "$GNUPGHOME" && \
	chmod 700 "$GNUPGHOME" && \
	rm -f /etc/apt/sources.list.d/* && \
	echo "disable-ipv6" >> "$GNUPGHOME/dirmngr.conf" && \
	found=''; \
	for server in \
		ha.pool.sks-keyservers.net \
		hkp://keyserver.ubuntu.com:80 \
		hkp://p80.pool.sks-keyservers.net:80 \
		pgp.mit.edu \
		keys.gnupg.net \
	; do \
		echo "  trying $server"; \
		apt-key adv --keyserver "$server" --keyserver-options timeout=10 --receive-keys D744D55EACDA69FF && found=yes && break; \
		apt-key adv --keyserver "$server" --keyserver-options timeout=10 --receive-keys D744D55EACDA69FF && found=yes && break; \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch $key from several disparate servers -- network issues?" && exit 1; \
	exit 0

RUN (echo "deb http://repos.fusiondirectory.org/fusiondirectory-current/debian-stretch stretch main"; \
	echo "deb http://repos.fusiondirectory.org/fusiondirectory-extra/debian-stretch stretch main") \
	> /etc/apt/sources.list.d/fusiondirectory-stretch.list && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y \
	argonaut-server \
	fusiondirectory=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-plugin-argonaut=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-plugin-autofs=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-plugin-certificates=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-plugin-gpg=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-plugin-ldapdump=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-plugin-ldapmanager=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-plugin-mail=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-plugin-postfix=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-plugin-ssh=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-plugin-sudo=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-plugin-systems=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-plugin-weblink=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-plugin-webservice=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-smarty3-acl-render=${FUSIONDIRECTORY_VERSION} \
	fusiondirectory-webservice-shell=${FUSIONDIRECTORY_VERSION} \
	php-mdb2 \
	php-mbstring \
	php-fpm && \
	rm -rf /var/lib/apt/lists/*

RUN export TARGET=/etc/php/7.3/fpm/php.ini && \
	sed -i -e "s:^;\(opcache.enable\) *=.*$:\1=1:" ${TARGET} && \
	sed -i -e "s:^;\(opcache.enable_cli\) *=.*$:\1=0:" ${TARGET} && \
	sed -i -e "s:^;\(opcache.memory_consumption\) *=.*$:\1=1024:" ${TARGET} && \
	sed -i -e "s:^;\(opcache.max_accelerated_files\) *=.*$:\1=65407:" ${TARGET} && \
	sed -i -e "s:^;\(opcache.validate_timestamps\) *=.*$:\1=0:" ${TARGET} && \
	sed -i -e "s:^;\(opcache.revalidate_path\) *=.*$:\1=1:" ${TARGET} && \
	sed -i -e "s:^;\(opcache.error_log\) *=.*$:\1=/dev/null:" ${TARGET} && \
	sed -i -e "s:^;\(opcache.log_verbosity_level\) *=.*$:\1=1:" ${TARGET} && \
	unset TARGET

RUN export TARGET=/etc/php/7.3/fpm/pool.d/www.conf && \
	sed -i -e "s:^\(listen *= *\).*$:\1/run/php7.3-fpm.sock:" ${TARGET} && \
	sed -i -e "s:^\(user *= *\).*$:\1nginx:" ${TARGET} && \
	unset TARGET

RUN export TARGET=/etc/nginx/nginx.conf && \
	sed -i -e "s:^\(user \).*;$:\1 nginx www-data;:" ${TARGET} && \
	unset TARGET

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh
COPY cmd.sh /sbin/cmd.sh
RUN chmod 755 /sbin/cmd.sh
COPY default.conf /etc/nginx/conf.d/

# Already defined in nginx
# EXPOSE 80
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["/sbin/cmd.sh"]
