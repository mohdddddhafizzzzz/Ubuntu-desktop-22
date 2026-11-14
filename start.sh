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
PASS_AUTH="yes"

cat > /etc/ssh/sshd_config.d/railway.conf <<CONF
PermitRootLogin yes
PasswordAuthentication $PASS_AUTH
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
