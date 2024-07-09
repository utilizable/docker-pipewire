############################################################
# Copyright (c) 2024 Utilizable 
# Released under the MIT license
############################################################
#
# ├─utilizable/docker-fakeroot
#   ├─utilizable/docker-pipewire

ARG DISTRIBUTION=24.04
FROM ghcr.io/utilizable/docker-fakeroot:latest

LABEL description="Ubuntu pipewire docker container" \
      maintainer="Utilizable http://github.com/utilizable"

ARG PULSEAUDIO_TCP_PORT=4713

# ---
# PipeWire and WirePlumber 
# ---

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        software-properties-common \
        curl && \

    mkdir -pm755 /etc/apt/trusted.gpg.d && \
    curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xFC43B7352BCC0EC8AF2EEB8B25088A0359807596" | \
      gpg --batch --no-tty --dearmor -o /etc/apt/trusted.gpg.d/pipewire-debian-ubuntu-pipewire-upstream.gpg && \

    mkdir -pm755 /etc/apt/sources.list.d && \
    echo "deb https://ppa.launchpadcontent.net/pipewire-debian/pipewire-upstream/ubuntu $(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"') main" \
      > "/etc/apt/sources.list.d/pipewire-debian-ubuntu-pipewire-upstream-$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"').list" && \

    mkdir -pm755 /etc/apt/sources.list.d && \ 
    echo "deb https://ppa.launchpadcontent.net/pipewire-debian/wireplumber-upstream/ubuntu $(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"') main" \
      > "/etc/apt/sources.list.d/pipewire-debian-ubuntu-wireplumber-upstream-$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"').list" && \

    apt-get update && \
    apt-get install --no-install-recommends -y \
        pipewire \
        pipewire-alsa \
        pipewire-audio-client-libraries \
        pipewire-jack \
        pipewire-locales \
        pipewire-v4l2 \
        pipewire-libcamera \
        gstreamer1.0-pipewire \
        libpipewire-0.3-modules \
        libpipewire-module-x11-bell \
        libspa-0.2-jack \
        libspa-0.2-modules \
        wireplumber \
        wireplumber-locales \
        gir1.2-wp-0.4 \
        dbus-user-session \
        dbus-x11 \
        supervisor && \

    # Clean up unnecessary files
    apt-get clean && \ 
    rm -rf \
      /var/lib/apt/lists/* \ 
      /var/cache/debconf/* \
      /var/log/* \
      /tmp/* \
      /var/tmp/* && \

    # Create directory for user specyfic pipewire configuration
    mkdir /usr/share/pipewire/pipewire.conf.d/ 

# ---
# COPY 
# ---

# supervisord config
COPY ./config/supervisord.conf \
      /etc/supervisord.conf

# pipewire pulse module configuration
COPY ./config/module_protocol_pulse.conf \
      /usr/share/pipewire/pipewire.conf.d/module_protocol_pulse.conf

# ---
# Setup 
# ---

ENV PIPEWIRE_LATENCY="32/48000" \
    DISPLAY=":0" \
    DISABLE_RTKIT="y" \
    XDG_RUNTIME_DIR="/tmp/" \
    PIPEWIRE_RUNTIME_DIR="/tmp/" \
    PULSE_RUNTIME_PATH="/tmp/"

# ---
# Execute 
# ---

ENTRYPOINT [ "/bin/bash", "-c" ]
CMD [ "dbus-run-session -- /usr/bin/supervisord" ]
