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
RUN chmod +x /start.sh

EXPOSE 22
CMD ["/start.sh"]
EOF_DOCKER

cat > start.sh <<'EOF_START'
#!/bin/bash
set -e

if [ -z "$PASSWORD" ]; then
  PASSWORD="$(head -c 12 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 12)"
  echo "=============================================="
  echo "PASSWORD tidak diset. Password acak: $PASSWORD"
  echo "=============================================="
fi
RESOLUTION="${RESOLUTION:-1280x720}"
PORT="${PORT:-6080}"

# ---------- SSH ----------
mkdir -p /run/sshd "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
ssh-keygen -A

if [ -n "$SSH_PUBLIC_KEY" ]; then
  echo "$SSH_PUBLIC_KEY" > "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
fi

echo "root:$PASSWORD" | chpasswd

cat > /etc/ssh/sshd_config.d/railway.conf <<CONF
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
CONF

/usr/sbin/sshd

# ---------- VNC / noVNC ----------
mkdir -p "$HOME/.vnc"
echo "$PASSWORD" | vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"

cat > "$HOME/.vnc/xstartup" <<'XEOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch --exit-with-session startxfce4
XEOF
chmod +x "$HOME/.vnc/xstartup"

vncserver -kill :1 >/dev/null 2>&1 || true
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

vncserver :1 -geometry "$RESOLUTION" -depth 24 -localhost yes

exec websockify --web=/usr/share/novnc "$PORT" localhost:5901
