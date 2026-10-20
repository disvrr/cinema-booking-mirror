# Splunk Universal Forwarder: install guide

The forwarder reads log files on a server and sends them to the Splunk server, where they can be searched and shown on dashboards. Run the install script once per log file on every server except the Splunk server itself. System logs (logins, sudo, service start and stop) are collected automatically into the `os` index, so you only provide the application log path, index and host name listed below.

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
sudo bash universal-forwarder-ubuntu-24.04.sh <forwarder_user> '<forwarder_password>' 10.0.2.19 <log_path> <index> <host_name>
```

Put the password in single quotes. Give the full path of one log file, not a folder. The host name is the name this server shows under in Splunk (listed for each machine below); use the same one every time you run the script on the same server. If a machine has more than one log file, run the same command again for each one. The second run skips the install and only adds the new path, so repeating it is safe.

## What to use on each machine

If your server's log path is different from the one listed here, tell the Splunk owner before running the script.

### Nginx server

Two runs, both with the index `nginx` and the host name `nginx`:

```
sudo bash universal-forwarder-ubuntu-24.04.sh <forwarder_user> '<forwarder_password>' 10.0.2.19 /var/log/nginx/access.log nginx nginx
sudo bash universal-forwarder-ubuntu-24.04.sh <forwarder_user> '<forwarder_password>' 10.0.2.19 /var/log/nginx/error.log nginx nginx
```

The access log must use the agreed key=value format with the upstream fields.

### Application servers (App 1 and App 2)

**Before the script:** the application must write its log to `/var/log/cinema/app.log`. The service file needs these two lines under `[Service]`:

```
Environment="LOGGING_FILE_NAME=/var/log/cinema/app.log"
LogsDirectory=cinema
```

`LogsDirectory=cinema` makes systemd create `/var/log/cinema` for the service user on every start. Without the folder the application cannot create `app.log` and only logs to the journal. Add the lines that are missing to the template `/opt/cinema/cinema.service`, then run `sudo /opt/cinema/setup_app.sh` again to rebuild the service.

Then one run on each server, index `app`. The host name is `app1` on App 1 and `app2` on App 2:

```
# on App 1
sudo bash universal-forwarder-ubuntu-24.04.sh <forwarder_user> '<forwarder_password>' 10.0.2.19 /var/log/cinema/app.log app app1

# on App 2
sudo bash universal-forwarder-ubuntu-24.04.sh <forwarder_user> '<forwarder_password>' 10.0.2.19 /var/log/cinema/app.log app app2
```

### PostgreSQL server

One run, index `postgres`, host name `db`:

```
sudo bash universal-forwarder-ubuntu-24.04.sh <forwarder_user> '<forwarder_password>' 10.0.2.19 /var/log/postgresql/postgresql-16-main.log postgres db
```

This is the Ubuntu default path for PostgreSQL 16. If the logging collector writes to a different place, use that file instead. Check with `ls -l /var/log/postgresql/`.

### Jenkins server

**Before the script:** create the log file first. The pipeline appends one line to it after every deploy, so the `jenkins` user must be able to write to it:

```
sudo touch /var/log/deploy-events.log
sudo chown jenkins:jenkins /var/log/deploy-events.log
```

Then one run, index `jenkins`, host name `jenkins`:

```
sudo bash universal-forwarder-ubuntu-24.04.sh <forwarder_user> '<forwarder_password>' 10.0.2.19 /var/log/deploy-events.log jenkins jenkins
```

## Check that it works

On the server where you ran the script:

```
sudo systemctl is-active SplunkForwarder
sudo -u splunkfwd /opt/splunkforwarder/bin/splunk list forward-server -auth <forwarder_user>:'<forwarder_password>'
```

The first command should print `active`. The second should list `10.0.2.19:9997` under active forwards. Then tell the Splunk owner which server you did, so they can confirm the data arrives.
