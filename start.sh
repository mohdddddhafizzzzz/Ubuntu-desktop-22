#!/bin/bash

mkpass() { head -c 64 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 8; }

# ---------- Password (VNC dan root asing) ----------
VPW="${VNC_PASSWORD:-$PASSWORD}"
RPW="${ROOT_PASSWORD:-$PASSWORD}"

if [ "${#VPW}" -lt 6 ]; then
  VPW="$(mkpass)"
  echo "=============================================="
  echo "VNC_PASSWORD kosong/pendek. VNC password acak: $VPW"
  echo "=============================================="
fi
VPW="${VPW:0:8}"

if [ -z "$RPW" ]; then
  RPW="$(mkpass)"
  echo "=============================================="
  echo "ROOT_PASSWORD kosong. Root password acak: $RPW"
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
echo "root:$RPW" | chpasswd
printf 'PermitRootLogin yes\nPasswordAuthentication yes\nPubkeyAuthentication yes\n' > /etc/ssh/sshd_config.d/railway.conf
/usr/sbin/sshd || echo "[warn] sshd gagal start"

# ---------- VNC password file ----------
echo "[start] VNC password"
rm -f "$HOME/.vnc/passwd"
echo "$VPW" | vncpasswd -f > "$HOME/.vnc/passwd" 2>/tmp/vncpw.err
if [ ! -s "$HOME/.vnc/passwd" ]; then
  echo "[warn] cara 1 gagal, cuba cara 2"
  printf '%s\n%s\nn\n' "$VPW" "$VPW" | vncpasswd "$HOME/.vnc/passwd" >>/tmp/vncpw.err 2>&1
fi
chmod 600 "$HOME/.vnc/passwd"
echo "[vnc] saiz fail passwd: $(stat -c %s "$HOME/.vnc/passwd" 2>/dev/null || echo 0) bait"
cat /tmp/vncpw.err
if [ ! -s "$HOME/.vnc/passwd" ]; then
  echo "[error] fail password VNC kosong, tidak dijalankan tanpa password"
  sleep 3600
  exit 1
fi

# ---------- Xvnc ----------
echo "[start] Xvnc"
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

echo "[error] websockify berhenti"
sleep 3600
