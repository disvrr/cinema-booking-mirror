#!/usr/bin/env bash
set -e

echo "=== [1/3] Preparing application directories and log path ==="
sudo mkdir -p /opt/cinema /var/log/cinema
sudo chown -R ubuntu:ubuntu /opt/cinema /var/log/cinema
sudo chmod 755 /var/log/cinema

echo "=== [2/3] Installing/Reloading cinema.service ==="
if [ -f cinema.service ]; then
    sudo cp cinema.service /etc/systemd/system/cinema.service
fi

sudo systemctl daemon-reload
sudo systemctl enable cinema

echo "=== [3/3] Restarting application if JAR exists ==="
if [ -f /opt/cinema/cinema-booking-1.0.0-SNAPSHOT.jar ]; then
    sudo systemctl restart cinema
fi

echo "=== App setup complete! ==="