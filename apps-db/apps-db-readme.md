# Database & Application Infrastructure Setup (Demo 2)

**Owner:** Anhelina Priadko  
**Target Architecture:** PostgreSQL Database Node, S3 Automated Backups, Application Servers (App1 & App2).

---

## 1. Overview & Inventory

| Instance Name | Private IP | Component | Responsible For |
|---|---|---|---|
| `demo2-postgresql` | `10.0.2.247` | PostgreSQL 16 | Primary relational database |
| `demo2-app1` | `10.0.2.209` | Spring Boot App | Backend application node 1 |
| `demo2-app2` | `10.0.2.138` | Spring Boot App | Backend application node 2 |

---

## 2. PostgreSQL & S3 Backups Setup

### PostgreSQL Installation & Security
The database was provisioned using `setup_postgres.sh`:
- Installed PostgreSQL and configured `postgresql.conf` to listen on internal interfaces.
- Updated `pg_hba.conf` to allow access from the private subnet (`10.0.0.0/24`).
- Created application database `cinema` and user `cinema_user`.

### Automated S3 Backups
- Script: `/usr/local/bin/backup_pg_to_s3.sh`
- Performs logical dumps via `pg_dump` and streams compressed backups to AWS S3 (`s3://demo2-postgres-backups/backups`).
- Uses AWS EC2 IAM Role (`demo2-postgres-s3-role`) for secure keyless authentication.
- Scheduled daily at 02:00 AM via system `crontab`.

---

## 3. Application Servers Provisioning (App1 & App2)

### Runtime & Systemd Configuration
- Installed OpenJDK 21 JRE.
- Environment variables configured in `/opt/cinema/cinema.env` (DB connection strings, profile settings, and file logging).
- Application managed as a native systemd service (`/etc/systemd/system/cinema.service`).
- App log output configured to `/var/log/cinema/app.log` for Splunk Universal Forwarder aggregation.

---

## 4. Verification & Health Checks

1. **Database Connectivity Test:**
   ```bash
   nc -zv 10.0.2.247 5432
   ```



2. **Application Health Endpoint Check:**

    ```bash
    curl -I http://localhost:8080/actuator/health
    ```

3. **S3 Backup Verification:**

    ```bash
    aws s3 ls s3://demo2-postgres-backups/backups/
    ```

4. **Service Status Check:**

    ```bash
    sudo systemctl status cinema
    ```