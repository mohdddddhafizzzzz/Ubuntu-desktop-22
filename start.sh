#!/bin/bash

if [ -z "$PASSWORD" ]; then
  PASSWORD="$(head -c 12 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 12)"
  echo "=============================================="
  echo "PASSWORD tidak diset. Password acak: $PASSWORD"
  echo "=============================================="
fi
RESOLUTION="${RESOLUTION:-1280x720}"
PORT="${PORT:-6080}"

export HOME=/root
export DISPLAY=:1
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p "$XDG_RUNTIME_DIR" /tmp/.X11-unix /run/sshd /etc/ssh/sshd_config.d "$HOME/.ssh" "$HOME/.vnc"
chmod 700 "$XDG_RUNTIME_DIR" "$HOME/.ssh"
chmod 1777 /tmp/.X11-unix

# ---------- SSH ----------
echo "[start] SSH"
ssh-keygen -A
if [ -n "$SSH_PUBLIC_KEY" ]; then
  echo "$SSH_PUBLIC_KEY" > "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
fi
echo "root:$PASSWORD" | chpasswd
printf 'PermitRootLogin yes\nPasswordAuthentication yes\nPubkeyAuthentication yes\n' > /etc/ssh/sshd_config.d/railway.conf
/usr/sbin/sshd || echo "[warn] sshd gagal start"

# ---------- VNC ----------
echo "[start] Xvnc"
echo "$PASSWORD" | vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

Xvnc :1 -geometry "$RESOLUTION" -depth 24 \
  -rfbport 5901 -localhost \
  -rfbauth "$HOME/.vnc/passwd" \
  -SecurityTypes VncAuth &

for i in $(seq 1 30); do
  xdpyinfo -display :1 >/dev/null 2>&1 && break
  sleep 1
done

echo "[start] XFCE"
dbus-launch --exit-with-session startxfce4 &

# ---------- noVNC ----------
echo "[start] websockify di port $PORT"
websockify --web=/usr/share/novnc "$PORT" localhost:5901

# kalau sampai sini, websockify mati: tahan container supaya log bisa dibaca
echo "[error] websockify berhenti"
sleep 3600
