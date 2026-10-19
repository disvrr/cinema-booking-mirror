# DEMO2 — Nginx Load Balancer

Nginx reverse proxy and HTTP load balancer running on an Ubuntu 24.04 EC2 instance. It forwards requests to two private EC2 application servers and writes structured access logs suitable for collection by Splunk Universal Forwarder.

## Architecture

```text
Client / approved ingress
          |
          | HTTP :80
          v
   Nginx Load Balancer (EC2)
          |
          | Round Robin + passive retry
          +------------------+
          |                  |
          v                  v
 APP1 {ip}:8080  APP2 {ip}:8080
```

These private IPs are from the DEMO2 setup. **Confirm the application listening port and current private IPs before deployment** (the application owner may change them).

## Repository contents

| File | Purpose |
| --- | --- |
| `nginx.conf` | Main Nginx configuration, structured Splunk access logging and error logging |
| `load_balancer.conf` | Upstream APP1/APP2, HTTP reverse proxy, Round Robin and passive failover |
| `setup_nginx.sh` | Installs Nginx, backs up existing config, deploys files and reloads service |

## Configuration behavior

- **Load balancing:** Round Robin (default Nginx upstream algorithm).
- **Passive failure detection:** `max_fails=3` and `fail_timeout=10s` on each backend.
- **Retry:** `proxy_next_upstream error timeout http_500 http_502 http_503` may retry a request on another backend; retries are subject to Nginx request/response safety limitations.
- **Timeouts:** 5 seconds to connect, 60 seconds to send/read.
- **Access logs:** `/var/log/nginx/access.log` with client, method, URI, response status, total request time, upstream address/status/connect time/response time.
- **Error logs:** `/var/log/nginx/error.log` includes upstream connection failures.
- **HTTP only:** Port 80 is configured; TLS is not enabled by this deployment.

## Prerequisites

1. Ubuntu EC2 instance with sudo privileges and package repository access.
2. APP1 and APP2 in reachable private subnets, with the application bound to the instance network interface (for example `0.0.0.0:8080`).
3. APP Security Groups permit inbound TCP on the application port **from the Nginx EC2 Security Group**.
4. Nginx Security Group permits the intended inbound TCP/80 clients and outbound TCP to APP1/APP2 on the application port. Check NACLs and host firewalls if necessary.
5. If collecting logs, configure Splunk Universal Forwarder separately to read `/var/log/nginx/access.log` and `/var/log/nginx/error.log` as required. Confirm Splunk field extraction after log format changes.

## Deployment

Copy the three config/script files to the same directory on the Nginx EC2 instance. Review `load_balancer.conf` IP addresses and port, then:

```bash
chmod +x setup_nginx.sh
./setup_nginx.sh
```

**Caution:** The script replaces `/etc/nginx/nginx.conf`, replaces `/etc/nginx/conf.d/load_balancer.conf`, and disables the Ubuntu default site. It makes timestamped backups under `/etc/nginx/backup-demo2-*`, but does not automatically restore them if validation fails. Run only on the designated DEMO2 load balancer and review any other active Nginx virtual hosts first.

For manual updates after editing either configuration file:

```bash
sudo nginx -t && sudo systemctl reload nginx
sudo systemctl status nginx --no-pager
```

## Verification

### 1. Verify each backend independently

From the Nginx EC2 instance:

```bash
curl -v --connect-timeout 5 http://{ip}:8080/
curl -v --connect-timeout 5 http://{ip}:8080/
```

If you see `Connection refused`, check the application process, its port and listening address on the relevant APP instance:

```bash
sudo ss -lntp
curl -v http://127.0.0.1:8080/
```

### 2. Verify the load balancer

```bash
curl -i http://localhost/
for i in $(seq 1 10); do curl -s -o /dev/null -w '%{http_code}\n' http://localhost/; done
sudo tail -n 20 /var/log/nginx/access.log
sudo tail -n 20 /var/log/nginx/error.log
```

Inspect `upstream_addr` in the access log to see which backend handled each request. When retries occur, it may contain multiple addresses. For visible Round Robin behavior, both APPs must serve requests successfully; the backend response or logs can include an instance identifier.

### 3. Failover drill

With both applications healthy, temporarily stop **one application service** in coordination with its owner (do not terminate the EC2 instance). Send requests through Nginx and verify the other backend continues serving them. Restore the service and confirm both backends can receive traffic again. Retry behavior is not guaranteed for every request type, especially non-idempotent requests or responses already sent to clients.

## Status (2026-10-18)

- Nginx service running and `nginx -t` passed in the interactive setup.
- Nginx attempted connections to both configured upstream IPs; logs showed connection refusal from both on port 8080.
- APP2 was confirmed not listening on port 8080 at the time of inspection. APP1 requires separate application-side confirmation.
- A previous missing `50x.html` error-page dependency was identified; this repository configuration removes that dependency.
- End-to-end Round Robin, healthy-backend failover, and Splunk ingestion are **not yet verified**.
- These files are a reproducible repository version of the intended configuration; the exact live EC2 configuration should be compared before claiming deployment matches this version.

## Useful troubleshooting commands

```bash
sudo nginx -t
sudo nginx -T
sudo systemctl status nginx --no-pager
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

Avoid committing SSH keys, credentials, passwords, or sensitive logs to this repository.
