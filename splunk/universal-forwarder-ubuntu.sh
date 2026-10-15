#!/usr/bin/env bash
set -euo pipefail

SPLUNK_HOME="/opt/splunkforwarder"
VERSION="splunkforwarder-10.6.0.5-86587d4e3b27-linux-amd64.deb"

# for index choose one from [nginx, app, postgres, jenkins]
USAGE="Usage: $0 <forwarder_user> <forwarder_password> <receiver_ip> <log_path> <index>"
FWD_USR="${1:?$USAGE}"
FWD_PASS="${2:?$USAGE}"
RECEIVER_ADDR="${3:?$USAGE}"
LOG_DIR="${4:?$USAGE}"
INDEX="${5:?$USAGE}"
RECEIVER_PORT=9997

#installing forwarder if not installed
if [ ! -x $SPLUNK_HOME/bin/splunk ]; then
    apt-get update
    apt-get install -y wget
    wget -O "$VERSION" "https://download.splunk.com/products/universalforwarder/releases/10.6.0.5/linux/$VERSION"

    id splunkfwd >/dev/null 2>&1 || useradd -m splunkfwd
    dpkg -i "./$VERSION"

    umask 077
    tee "$SPLUNK_HOME"/etc/system/local/user-seed.conf > /dev/null <<EOF
[user_info]
USERNAME = ${FWD_USR:-admin}
PASSWORD = ${FWD_PASS}
EOF
    umask 022
    chown -R splunkfwd:splunkfwd "$SPLUNK_HOME"

    sudo -u splunkfwd "$SPLUNK_HOME"/bin/splunk start --accept-license --answer-yes --no-prompt
    rm -f "$SPLUNK_HOME"/etc/system/local/user-seed.conf

    # run on boot
    sudo -u splunkfwd "$SPLUNK_HOME/bin/splunk" stop
    "$SPLUNK_HOME"/bin/splunk enable boot-start -user splunkfwd -systemd-managed 1
    systemctl start SplunkForwarder
    sleep 15


else
    echo "Install already completed"
fi

# forwarding data
sudo -u splunkfwd "$SPLUNK_HOME"/bin/splunk add forward-server "${RECEIVER_ADDR}:${RECEIVER_PORT:-9997}" -auth "${FWD_USR}:${FWD_PASS}" \
    || echo "forward-server already configured"
sudo -u splunkfwd "$SPLUNK_HOME"/bin/splunk add monitor "$LOG_DIR" -index "$INDEX" -auth "${FWD_USR}:${FWD_PASS}" 

# os log index
INPUTS="$SPLUNK_HOME/etc/system/local/inputs.conf"
if ! grep -qs '^\[journald://os\]' "$INPUTS"; then
    usermod -aG systemd-journal,adm splunkfwd
    printf '\n[journald://os]\nindex = os\n' | sudo -u splunkfwd tee -a "$INPUTS" > /dev/null
    systemctl restart SplunkForwarder
fi