FROM alpine:3.23

ARG BUILD_DATE
ARG GIT_BUILD_HASH
ARG VERSION
ENV GIT_BUILD_HASH=$GIT_BUILD_HASH

# first, a bit about this container
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.authors="Henry Stadthagen <h.stadthagen@me.com>" \
      org.opencontainers.image.documentation="https://github.com/henryhst/ha-chronyd" \
      org.opencontainers.image.version=${VERSION} \
      org.opencontainers.image.revision=${GIT_BUILD_HASH}

# default configuration
ENV NTP_DIRECTIVES="ratelimit\nrtcsync"

# install chrony
RUN apk add --no-cache chrony tzdata && \
    rm /etc/chrony/chrony.conf && \
    chmod 1750 /etc/chrony && \
    mkdir /run/chrony && \
    chown -R chrony:chrony /etc/chrony /run/chrony /var/lib/chrony && \
    chmod 1750 /etc/chrony /run/chrony /var/lib/chrony

# script to configure/startup chrony (ntp)
COPY --chmod=0755 assets/startup.sh /bin/startup

# ntp port
EXPOSE 123/udp

# marking volumes that need to be writable
# this will also create unnamed volumes on the host system
VOLUME /etc/chrony /run/chrony /var/lib/chrony

# let docker know how to test container health
HEALTHCHECK CMD chronyc -n tracking || exit 1

# start chronyd in the foreground
USER chrony:chrony
ENTRYPOINT [ "/bin/startup" ]
