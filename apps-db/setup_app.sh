#!/usr/bin/env bash
set -e

# Creating necessary directories for the application
sudo mkdir -p /opt/cinema /var/log/cinema
sudo chown -R ubuntu:ubuntu /opt/cinema /var/log/cinema

# Restarting the service if the JAR file already exists in /opt/cinema
if [ -f /opt/cinema/app.jar ] || [ -f /opt/cinema/cinema-booking-1.0.0-SNAPSHOT.jar ]; then
    sudo systemctl restart cinema || true
fi