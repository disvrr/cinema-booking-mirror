#!/usr/bin/env bash
set -e

echo "=== Installing PostgreSQL ==="
sudo apt-get update -y
sudo apt-get install -y postgresql postgresql-contrib awscli

echo "=== Configuring Network Access ==="
PG_CONF=$(ls /etc/postgresql/*/main/postgresql.conf)
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" "$PG_CONF"

PG_HBA=$(ls /etc/postgresql/*/main/pg_hba.conf)
if ! grep -q "10.0.0.0/16" "$PG_HBA"; then
    echo "host    all             all             10.0.0.0/16             scram-sha-256" | sudo tee -a "$PG_HBA"
fi

echo "=== Creating Database & Roles ==="
sudo -u postgres psql << 'EOF'
CREATE DATABASE cinema;
CREATE USER cinema_user WITH ENCRYPTED PASSWORD 'cinema_password';
GRANT ALL PRIVILEGES ON DATABASE cinema TO cinema_user;
ALTER DATABASE cinema OWNER TO cinema_user;
EOF

sudo systemctl restart postgresql
echo "=== PostgreSQL Setup Complete ==="