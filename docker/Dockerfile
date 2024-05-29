#############
# Nginx Builder
#############

<<<<<<< HEAD
# docker build --build-arg OPENRESTY_VERSION=1.25.3.1 --build-arg LUA_VERSION=5.1.5 --build-arg LUAROCKS_VERSION=3.3.1 CROWDSEC_OPENRESTY_BOUNCER_VERSION=0.1.7 -t shuxiao9058/nginx-full:latest - < docker/Dockerfile
# docker buildx build --build-arg OPENRESTY_VERSION=1.25.3.1 --build-arg LUA_VERSION=5.1.5 --build-arg LUAROCKS_VERSION=3.3.1 --build-arg CROWDSEC_OPENRESTY_BOUNCER_VERSION=0.1.7 -t shuxiao9058/nginx-full:latest --platform linux/amd64 - < docker/Dockerfile
# docker buildx build --platform linux/arm64 -f Dockerfile .

FROM debian:bookworm-slim as nginxbuilder

ARG OPENRESTY_VERSION
ARG LUA_VERSION
ARG LUAROCKS_VERSION

RUN apt-get update \
	&& apt-get install -y \
	build-essential \
	ca-certificates \
	libncurses-dev \
	libpcre3-dev \
	libreadline-dev \
	libssl-dev \
	openssl unzip \
	wget \
	zlib1g-dev \
	libxslt-dev \
	git \
	libmaxminddb-dev

# Lua build
COPY ./scripts/build-lua /tmp/build-lua
RUN /tmp/build-lua

# Nginx build
COPY ./scripts/build-openresty /tmp/build-openresty
RUN /tmp/build-openresty

#############
# Final Image
#############

FROM debian:bookworm-slim as final
LABEL maintainer="Jamie Curnow <jc@jc21.com>"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG TARGETPLATFORM
RUN echo "Base: debian:bookworm-slim, ${TARGETPLATFORM:-linux/amd64}" > /built-for-arch

# OpenResty uses LuaJIT which has a dependency on GCC
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	apache2-utils \
	ca-certificates \
	curl \
	figlet \
	jq \
	libncurses6 \
	libpcre3 \
	libreadline8 \
	openssl \
	perl \
	tzdata \
	unzip \
	zlib1g \
	gettext \
	wget \
	libxslt-dev \
	xz-utils \
	libmaxminddb-dev \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/cache/* /var/log/* /tmp/* /var/lib/dpkg/status-old

COPY ./files/.bashrc /root/.bashrc

# Copy lua and luarocks builds from first image
COPY --from=nginxbuilder /tmp/lua /tmp/lua
COPY --from=nginxbuilder /tmp/luarocks /tmp/luarocks
COPY ./scripts/install-lua /tmp/install-lua

# Copy openresty build from first image
COPY --from=nginxbuilder /tmp/openresty /tmp/openresty
COPY ./scripts/install-openresty /tmp/install-openresty

# Copy crowdsec openresty bouncer install script
COPY ./scripts/install-crowdsec_openresty_bouncer /tmp/install-crowdsec_openresty_bouncer

ARG OPENRESTY_VERSION
ARG CROWDSEC_OPENRESTY_BOUNCER_VERSION
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
	OPENRESTY_VERSION=${OPENRESTY_VERSION} \
	CROWDSEC_OPENRESTY_BOUNCER_VERSION=${CROWDSEC_OPENRESTY_BOUNCER_VERSION}

# Install openresty, lua, then clean up file system
RUN apt-get update \
	&& apt-get install -y gcc make socat git vim procps \
	&& /tmp/install-lua \
	&& /tmp/install-openresty \
	&& apt-get remove -y make gcc git wget gettext \
	&& apt-get autoremove -y \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/cache/* /var/log/* /tmp/* /var/lib/dpkg/status-old

RUN groupadd -g 568 apps
RUN useradd apps -u 568 -g 568 -m -s /bin/bash
RUN mkdir -p /var/log/nginx
RUN chown apps:apps -R /var/log/nginx
RUN mkdir -p /var/cache/nginx/
RUN chown apps:apps -R /var/cache/nginx
RUN sed -i 's/#user  nobody;/user  apps apps;/g' /etc/nginx/nginx.conf

LABEL org.label-schema.schema-version="1.0" \
	org.label-schema.license="MIT" \
	org.label-schema.name="nginx-full" \
	org.label-schema.description="A base image for use by Nginx Proxy Manager" \
	org.label-schema.url="https://github.com/nginxproxymanager/docker-nginx-full" \
	org.label-schema.vcs-url="https://github.com/nginxproxymanager/docker-nginx-full.git" \
	org.label-schema.cmd="docker run --rm -ti nginxproxymanager/nginx-full:latest"
