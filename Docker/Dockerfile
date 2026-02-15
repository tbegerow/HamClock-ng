ARG BASE_IMAGE=alpine:3.21
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Thorsten Begerow DG5YIM"
LABEL org.opencontainers.image.description="Dockerized HamClock-NG (community-maintained fork of HamClock by WB0OEW, sk)"
LABEL org.opencontainers.image.source="https://github.com/tbegerow/hamclock-ng"

# Configuration. Will be overwritten using the config.yaml file or docker run configuration. 
ENV CALLSIGN="AB1CDE"
ENV LOCATOR="JJ00aa"
ENV LAT="00"
ENV LONG="00"
ENV UTC_OFFSET="2"
ENV VOACAP_MODE="38"
ENV VOACAP_POWER="100"
ENV CALLSIGN_BACKGROUND_COLOR="100,100,100"
ENV CALLSIGN_BACKGROUND_RAINBOW="0"
ENV CALLSIGN_COLOR="0,0,0"
ENV FLRIG_PORT="12345"
ENV FLRIG_HOST="localhost"
ENV USE_FLRIG="0"
ENV USE_METRIC="1"

USER root

# HamClock supported resolutions are 800x480, 1600x960, 2400x1440 and 3200x1920 as of v3.02
ARG HAMCLOCK_RESOLUTION=2400x1440

# Install updates and required packages
# ---- packages ----
RUN apk update && apk upgrade && \
    apk add --no-cache \
      bash \
      curl \
      busybox-suid \
      make \
      g++ \
      libx11-dev \
      openssl \
      unzip \
      perl \
      linux-headers \
      yq \
      gawk

RUN mkdir /hamclock
WORKDIR /hamclock

# Download HamClock source
# Sort-of following Desktop build steps from https://www.clearskyinstitute.com/ham/HamClock/
RUN curl -O https://raw.githubusercontent.com/tbegerow/HamClock-ng/main/dist/ESPHamClock.tgz
RUN tar xf ESPHamClock.tgz && \
    rm ESPHamClock.tgz
WORKDIR /hamclock/ESPHamClock

# Change optimization level to -O2
# Fixes build failure on ARM64
RUN chmod 664 Makefile
RUN ls -alh Makefile
RUN sed -i 's/-O3/-O2/g' Makefile

# Let's build it
RUN make -j 4 hamclock-web-${HAMCLOCK_RESOLUTION}
RUN make install

RUN /usr/local/bin/hamclock >/dev/null 2>&1 & \
    PID=$! && \
    sleep 15 && \
    kill -INT $PID || true

# Install hceeprom to hamclock directory
RUN cd /hamclock/ESPHamClock && \
    curl -O curl -O https://raw.githubusercontent.com/tbegerow/HamClock-ng/main/Docker/hceeprom.pl
WORKDIR /hamclock/ESPHamClock
RUN chmod +x hceeprom.pl

# HamClock REST API
EXPOSE 8080/tcp
# HamClock Web UI
EXPOSE 8081/tcp
# HamClock Web UI (ro)
EXPOSE 8082/tcp

# Persist HamClock settings outside of container
VOLUME /root/.hamclock

# Healtheck - call REST API, give it 2 mins to get through setup
HEALTHCHECK --interval=30s --timeout=10s --start-period=2m --retries=3 CMD curl -f http://localhost:8080/get_sys.txt || exit 1

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Start HamClock
#WORKDIR /hamclock/ESPHamClock
#CMD ["/usr/local/bin/hamclock", "-o"]
