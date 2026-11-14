FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/root \
    USER=root \
    DISPLAY=:1

RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 xfce4-terminal xfce4-goodies \
    tigervnc-standalone-server tigervnc-common \
    novnc websockify \
    dbus-x11 x11-utils xauth \
    mousepad thunar \
    openssh-server \
    ca-certificates curl wget nano sudo gnupg \
    fonts-dejavu fonts-liberation xdg-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update && apt-get install -y /tmp/chrome.deb \
    && rm -f /tmp/chrome.deb && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mv /opt/google/chrome/chrome /opt/google/chrome/chrome-bin \
    && printf '#!/bin/sh\nexec /opt/google/chrome/chrome-bin --no-sandbox --disable-dev-shm-usage --disable-gpu "$@"\n' > /opt/google/chrome/chrome \
    && chmod +x /opt/google/chrome/chrome \
    && update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/google-chrome-stable 200 \
    && update-alternatives --set x-www-browser /usr/bin/google-chrome-stable

RUN ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html \
    && mkdir -p /run/sshd

COPY start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

EXPOSE 6080
CMD ["/start.sh"]
