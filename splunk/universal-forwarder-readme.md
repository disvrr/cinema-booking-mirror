# Splunk Universal Forwarder: install guide

The forwarder reads log files on a server and sends them to the Splunk server, where they can be searched and shown on dashboards. Run the install script once per log file on every server except the Splunk server itself. System logs (logins, sudo, service start and stop) are collected automatically into the `os` index, so you only provide the application log paths listed below.

## Before you run it

- The server runs Ubuntu 24.04 and can reach the internet (the script downloads packages and the forwarder).
- The Splunk server (`10.0.2.19`) accepts connections on port 9997 from this server. Test it:

  ```
  nc -vz -w 3 10.0.2.19 9997
  ```

  It should print `Connection to 10.0.2.19 9997 port [tcp/*] succeeded!`.

- The log file already exists on the server. Start the service that writes it first.
- Create any user name (for example `admin`) and a password of at least 8 characters that you can remember. They only protect the forwarder's local admin account on this server.

## How to run it

Run it from your home folder, with `sudo`:

```
sudo bash universal-forwarder-ubuntu-24.04.sh <forwarder_user> '<forwarder_password>' 10.0.2.19 <log_path> <index>
```

Put the password in single quotes. Give the full path of one log file, not a folder. If a machine has more than one log file, run the same command again for each one. The second run skips the install and only adds the new path, so repeating it is safe.

## What to use on each machine

If your server's log path is different from the one listed here, tell the Splunk owner before running the script.

### Nginx server

Two runs, both with the index `nginx`:

```
sudo bash universal-forwarder-ubuntu-24.04.sh <forwarder_user> '<forwarder_password>' 10.0.2.19 /var/log/nginx/access.log nginx
sudo bash universal-forwarder-ubuntu-24.04.sh <forwarder_user> '<forwarder_password>' 10.0.2.19 /var/log/nginx/error.log nginx
```

The access log must use the agreed key=value format with the upstream fields.

### Application servers (App 1 and App 2)

One run on each server, index `app`:

```
sudo bash universal-forwarder-ubuntu-24.04.sh <forwarder_user> '<forwarder_password>' 10.0.2.19 /var/log/cinema/app.log app
```

### PostgreSQL server

One run, index `postgres`:

```
sudo bash universal-forwarder-ubuntu-24.04.sh <forwarder_user> '<forwarder_password>' 10.0.2.19 /var/log/postgresql/postgresql-16-main.log postgres
```

This is the Ubuntu default path for PostgreSQL 16. If the logging collector writes to a different place, use that file instead. Check with `ls -l /var/log/postgresql/`.

### Jenkins server

One run, index `jenkins`:

```
sudo bash universal-forwarder-ubuntu-24.04.sh <forwarder_user> '<forwarder_password>' 10.0.2.19 /var/log/deploy-events.log jenkins
```

## Check that it works

On the server where you ran the script:

```
sudo systemctl is-active SplunkForwarder
sudo -u splunkfwd /opt/splunkforwarder/bin/splunk list forward-server -auth <forwarder_user>:'<forwarder_password>'
```

The first command should print `active`. The second should list `10.0.2.19:9997` under active forwards. Then tell the Splunk owner which server you did, so they can confirm the data arrives.

## If no data arrives

- Port 9997 not reachable: ask for the security group to be fixed.
- Permission denied on the log file: look for the word "permission" in `/opt/splunkforwarder/var/log/splunk/splunkd.log`. A common fix on Ubuntu is to give the forwarder's user read access to the logs:

  ```
  sudo usermod -aG adm splunkfwd
  sudo systemctl restart SplunkForwarder
  ```

- Anything else: send the last lines of that same `splunkd.log` to the Splunk owner.
