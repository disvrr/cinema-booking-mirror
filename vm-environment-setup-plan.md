# Demo 2 — AWS Network and Access Plan

**Project:** Cinema Booking · **Region:** AWS Europe (Frankfurt) · **Environment:** Demo

## 1. Architecture

The environment runs in one VPC with a public subnet and a private subnet. Six Ubuntu EC2 instances are used.

```text
                    Internet
                       |
                Internet Gateway
                       |
                  Public subnet
                       |
          Nginx (HTTP LB / SSH Bastion / NAT*)
                       |
                  Private subnet
          +------------+------------+----------+
          |            |            |          |
        Jenkins     APP1 / APP2  PostgreSQL   Splunk
```

*For this cost-constrained demo, Nginx also provides temporary outbound NAT. Combining these roles is not a production recommendation. Jenkins and all application/data/monitoring hosts have no public IP addresses.*

## 2. Ownership and server roles

| Component | Location | Responsibility | Owner |

| Nginx LB / Bastion / temporary NAT | Public subnet | HTTP entry point, balancing, admin access, outbound NAT | Ilaria |
| Jenkins | Private subnet | Build, test, deploy | Diana |
| APP1, APP2 | Private subnet | Spring Boot application replicas | Anhelina |
| PostgreSQL | Private subnet | Application database and S3 backups | Anhelina |
| Splunk Enterprise | Private subnet | Log ingestion, dashboards, alerts | Yaroslav |

## 3. Network access matrix

| From | To | Protocol / port | Purpose |

| Internet | Nginx | TCP 80 | Application HTTP traffic |
| Approved team IPs | Bastion | TCP 22 | Restricted SSH administration |
| Bastion | Assigned private EC2 | TCP 22 | SSH ProxyJump |
| Nginx | APP1 / APP2 | TCP 8080 | Reverse proxy and failover |
| APP1 / APP2 | PostgreSQL | TCP 5432 | Database connection |
| Jenkins | APP1 / APP2 | TCP 22 | Deployment over SSH |
| Universal Forwarders | Splunk | TCP 9997 | Log forwarding |
| Private EC2 | Internet (via temporary NAT) | Outbound as needed | Dependency and package downloads |

Security Groups restrict inbound traffic to required sources. Jenkins, database, Splunk Web and application backend ports are not publicly exposed. The temporary NAT requires the Nginx EC2 instance to be running.

## 4. SSH access model

Each teammate uses their own SSH key pair and a separate Linux account. The infrastructure owner installs the **public** key on the bastion and the assigned private EC2 instance, and allowlists the teammate's current public IPv4 `/32` on the bastion Security Group.

The teammate connects using OpenSSH `ProxyJump`:

```sshconfig
Host demo2-bastion
    HostName <BASTION_PUBLIC_IP_FROM_PRIVATE_TEAM_CHANNEL>
    User <YOUR_LINUX_USERNAME>
    IdentityFile ~/.ssh/<YOUR_PRIVATE_KEY>
    IdentitiesOnly yes

Host demo2-target
    HostName <TARGET_PRIVATE_IP_FROM_PRIVATE_TEAM_CHANNEL>
    User <YOUR_LINUX_USERNAME>
    IdentityFile ~/.ssh/<YOUR_PRIVATE_KEY>
    IdentitiesOnly yes
    ProxyJump demo2-bastion
```

Then run `ssh demo2-target`. Actual IP addresses, individual account names, and key distribution are shared **privately**, not stored in this public repository. The personal login key is separate from any Jenkins deployment credential.

## 5. Dependencies and responsibilities

- **Application:** Nginx forwards HTTP requests to APP1/APP2. Both application instances use the private PostgreSQL service. Upstream health/failover tests require running application services.
- **CI/CD:** Jenkins deploys to APP1 and APP2 through private-network SSH using a dedicated deployment identity. Deploy permissions and health checks are configured jointly by Diana and Anhelina.
- **Backups:** PostgreSQL uploads backups to a private S3 bucket using an attached EC2 IAM role; no static AWS credentials are stored on disk. Restore testing is part of backup validation.
- **Monitoring:** Yaroslav provides a Splunk Universal Forwarder installation script. Ilaria installs it on Nginx; Diana on Jenkins; Anhelina on APP1, APP2 and PostgreSQL. Forwarders send logs to Splunk over TCP 9997.

## 6. Operating procedure and cost controls

**Start:** Agree on a work window; start the Nginx/bastion/NAT instance first, then only the private EC2 instances needed for that session. Verify SSH, outbound connectivity where required, and application/service health.

**Stop:** Confirm no active builds, deployments, backups or tests; stop unneeded private EC2 instances first and Nginx/bastion/NAT **last**. Verify `Stopped` in EC2 Console. Do not terminate instances as part of a routine shutdown.

Stopped EC2 instances still incur storage and public IPv4 charges. Monitor AWS Budgets and remove all demo resources after final approval and teardown.

## 7. Verification status

| Item | Status |

| VPC, subnets, routing, Security Groups, six EC2 | Provisioned |
| SSH via bastion | Verified by infrastructure owner; team onboarding ongoing |
| NAT outbound internet | Verified from Jenkins EC2 |
| Nginx upstream and failover | Pending application deployment and integration tests |
| PostgreSQL S3 IAM role | Configured; upload/restore test pending |
| Splunk forwarders, dashboards, alerts | Pending |
| Final failover drill and teardown | Pending |

## 8. Repository safety

Never commit SSH private keys (`.pem` or otherwise), `.env` files, passwords, tokens, AWS credentials, personal public IP allowlists or unredacted console screenshots. Keep the detailed resource inventory and actual connection endpoints in a private team channel or restricted-access document. Review screenshots and terminal logs before including them in a presentation.
