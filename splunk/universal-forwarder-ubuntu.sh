#!/usr/bin/env bash
set -euo pipefail

SPLUNK_HOME="/opt/splunkforwarder"
VERSION="splunkforwarder-10.6.0.5-86587d4e3b27-linux-amd64.deb"

# for index choose one from [nginx, app, postgres, jenkins]
USAGE="Usage: $0 <forwarder_user> <forwarder_password> <receiver_ip> <log_path> <index> <host_name>"
FWD_USR="${1:?$USAGE}"
FWD_PASS="${2:?$USAGE}"
RECEIVER_ADDR="${3:?$USAGE}"
LOG_DIR="${4:?$USAGE}"
INDEX="${5:?$USAGE}"
HOST_NAME="${6:?$USAGE}"
RECEIVER_PORT=9997

# events for an unknown index are dropped silently, so stop early
case "$INDEX" in
    nginx|app|postgres|jenkins) ;;
    *) echo "index must be one of: nginx, app, postgres, jenkins"; exit 1 ;;
esac

# password check
[ "${#FWD_PASS}" -ge 8 ] || { echo "password must be at least 8 characters"; exit 1; }

# forwarder user
id splunkfwd >/dev/null 2>&1 || useradd -m splunkfwd

# install package if the binary is missing
if [ ! -x "$SPLUNK_HOME"/bin/splunk ]; then
    apt-get update
    apt-get install -y wget
    wget -O "$VERSION" "https://download.splunk.com/products/universalforwarder/releases/10.6.0.5/linux/$VERSION"
    dpkg -i "./$VERSION"
    chown -R splunkfwd:splunkfwd "$SPLUNK_HOME"
fi

# accept the license and create the admin user from the seed file
if [ ! -f "$SPLUNK_HOME"/etc/passwd ]; then
    umask 077
    tee "$SPLUNK_HOME"/etc/system/local/user-seed.conf > /dev/null <<EOF
[user_info]
USERNAME = ${FWD_USR:-admin}
PASSWORD = ${FWD_PASS}
EOF
    umask 022
    chown splunkfwd:splunkfwd "$SPLUNK_HOME"/etc/system/local/user-seed.conf

    sudo -u splunkfwd "$SPLUNK_HOME"/bin/splunk start --accept-license --answer-yes --no-prompt
    sudo -u splunkfwd "$SPLUNK_HOME"/bin/splunk stop # stop splunk to setup boot-start
  
fi

# run on boot
if ! systemctl cat SplunkForwarder >/dev/null 2>&1; then
    "$SPLUNK_HOME"/bin/splunk enable boot-start -user splunkfwd -systemd-managed 1
fi

# start the service if it is not running
if ! systemctl is-active --quiet SplunkForwarder; then
    systemctl start SplunkForwarder
    sleep 15
fi

# allow forwarder read the journal and application logs
usermod -aG systemd-journal,adm splunkfwd

# host name for Splunk
sudo -u splunkfwd "$SPLUNK_HOME"/bin/splunk set default-hostname "$HOST_NAME" -auth "${FWD_USR}:${FWD_PASS}"

# os log index
INPUTS="$SPLUNK_HOME/etc/system/local/inputs.conf"
if ! grep -qs '^\[journald://os\]' "$INPUTS"; then
    printf '\n[journald://os]\nindex = os\n' | sudo -u splunkfwd tee -a "$INPUTS" > /dev/null
fi

# apply the groups, the host name and the journal input changes
systemctl restart SplunkForwarder
sleep 10

# forwarding data
sudo -u splunkfwd "$SPLUNK_HOME"/bin/splunk add forward-server "${RECEIVER_ADDR}:${RECEIVER_PORT:-9997}" -auth "${FWD_USR}:${FWD_PASS}" \
    || echo "forward-server already configured"
sudo -u splunkfwd "$SPLUNK_HOME"/bin/splunk add monitor "$LOG_DIR" -index "$INDEX" -auth "${FWD_USR}:${FWD_PASS}" \
    || echo "monitor already configured"