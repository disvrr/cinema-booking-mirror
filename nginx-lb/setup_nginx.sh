#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo '[1/5] Install Nginx'
sudo apt-get update
sudo apt-get install -y nginx

echo '[2/5] Back up existing configuration'
BACKUP_DIR="/etc/nginx/backup-demo2-$(date +%Y%m%d-%H%M%S)"
sudo mkdir -p "$BACKUP_DIR"
sudo cp -a /etc/nginx/nginx.conf "$BACKUP_DIR/nginx.conf"
if [ -e /etc/nginx/conf.d/load_balancer.conf ]; then
  sudo cp -a /etc/nginx/conf.d/load_balancer.conf "$BACKUP_DIR/load_balancer.conf"
fi
if [ -L /etc/nginx/sites-enabled/default ]; then
  sudo cp -a /etc/nginx/sites-enabled/default "$BACKUP_DIR/default.link"
fi

echo '[3/5] Install configurations'
sudo install -m 644 "$SCRIPT_DIR/nginx.conf" /etc/nginx/nginx.conf
sudo install -m 644 "$SCRIPT_DIR/load_balancer.conf" /etc/nginx/conf.d/load_balancer.conf
# Disable the default HTTP site to avoid conflicts on port 80.
if [ -L /etc/nginx/sites-enabled/default ]; then
  sudo unlink /etc/nginx/sites-enabled/default
fi

echo '[4/5] Validate configuration'
if ! sudo nginx -t; then
  echo "Validation failed. Backups: $BACKUP_DIR" >&2
  exit 1
fi

echo '[5/5] Enable and reload Nginx'
sudo systemctl enable nginx
if sudo systemctl is-active --quiet nginx; then
  sudo systemctl reload nginx
else
  sudo systemctl start nginx
fi

echo "Deployment complete. Backups: $BACKUP_DIR"
