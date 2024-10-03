![](header.png)

[![Minio Version](https://img.shields.io/badge/Minio-latest-blue.svg)]() [![Dokku Version](https://img.shields.io/badge/Dokku-v0.11.2-blue.svg)]()

# Run Minio on Dokku

## Perquisites

### What is Minio?

Minio is an object storage server, and API compatible with Amazon S3 cloud
storage service. Read more at the [minio.io](https://www.minio.io/) website.

### What is Dokku?

[Dokku](http://dokku.viewdocs.io/dokku/) is the smallest PaaS implementation
you've ever seen - _Docker powered mini-Heroku_.

### Requirements

* A working [Dokku host](http://dokku.viewdocs.io/dokku/getting-started/installation/)

# Setup

We are going to use the domain `minio.example.com` and Dokku app `minio` for
demonstration purposes. Make sure to replace it.

## Create the app

Log onto your Dokku Host to create the Minio app:

```bash
export APP_NAME="minio"
export APP_DOMAIN="minio.example.com"
export APP_ADMIN_EMAIL="admin@example.com"

dokku apps:create "$APP_NAME"
```

## Configuration

### Setting environment variables

Minio uses two access keys (`ACCESS_KEY` and `SECRET_KEY`) for authentication
and object management. The following commands sets a random strings for each
access key.

```bash
dokku config:set --no-restart "$APP_NAME" MINIO_ACCESS_KEY=$(echo `openssl rand -base64 45` | tr -d \=+ | cut -c 1-20)
dokku config:set --no-restart "$APP_NAME" MINIO_SECRET_KEY=$(echo `openssl rand -base64 45` | tr -d \=+ | cut -c 1-32)
```

To login in the browser or via API, you will need to supply both the
`ACCESS_KEY` and `SECRET_KEY`. You can retrieve these at any time while logged
in on your host running dokku via `dokku config:show "$APP_NAME"`.

> **Note:** if you do not set these keys, Minio will generate them during
> startup and output them to the log (check if via `dokku logs "$APP_NAME"`). You
> will still need to set them manually.

You'll also need to set another environment variable:

- `MINIO_DOMAIN`: used to tell Minio the domain name being used by the server.

```bash
dokku config:set --no-restart "$APP_NAME" MINIO_DOMAIN=$APP_DOMAIN
dokku nginx:set "$APP_NAME" client-max-body-size 50m
```

> **Note**: if you're using [s4cmd](https://github.com/bloomreach/s4cmd/)
> instead, be sure to pass the following parameters:
> `--multipart-split-size=15728640 --max-singlepart-upload-size=15728640`.


## Persistent storage

To persists uploaded data between restarts, we create a folder on the host
machine, add write permissions to the user defined in `Dockerfile` and tell
Dokku to mount it to the app container.

```bash
sudo mkdir -p /var/lib/dokku/data/storage/$APP_NAME
sudo chown 32769:32769 /var/lib/dokku/data/storage/$APP_NAME
dokku storage:mount "$APP_NAME" /var/lib/dokku/data/storage/${APP_NAME}:/home/dokku/data
```

## Domain setup

To get the routing working, we need to apply a few settings. First we set
the domain.

```bash
dokku domains:set "$APP_NAME" "$APP_DOMAIN"
```

The parent Dockerfile, provided by the [Minio
project](https://github.com/minio/minio), exposes port `9000` for web requests.
Dokku will set up this port for outside communication, as explained in [its
documentation](http://dokku.viewdocs.io/dokku/advanced-usage/proxy-management/#proxy-port-mapping).
Because we want Minio to be available on the default port `80` (or `443` for
SSL), we need to fiddle around with the proxy settings.

First add the correct port mapping for this project as defined in the parent
`Dockerfile`.

```bash
dokku proxy:ports-add "$APP_NAME" http:80:9000
```

Next remove the proxy mapping added by Dokku.

```bash
dokku proxy:ports-remove "$APP_NAME"http:80:5000
```

## Push Minio to Dokku

### Grabbing the repository

First clone this repository onto your machine.

#### Via SSH

```bash
git clone git@github.com:slypix/minio-dokku.git
```

#### Via HTTPS

```bash
git clone https://github.com/slypix/minio-dokku.git
```

### Set up git remote

Now you need to set up your Dokku server as a remote.

```bash
git remote add dokku dokku@example.com:<APP_NAME>
```

### Push Minio

Now we can push Minio to Dokku (_before_ moving on to the [next
part](#domain-and-ssl-certificate)).

```bash
git push dokku master
```

## SSL certificate

Last but not least, we can go an grab the SSL certificate from [Let's
Encrypt](https://letsencrypt.org/).

```bash
dokku letsencrypt:set "$APP_NAME" email "$APP_ADMIN_EMAIL"
dokku letsencrypt:enable "$APP_NAME"
dokku proxy:ports-set "$APP_NAME" https:443:9000
```

> **Note**: you must execute these steps *after* pushing the app to Dokku
> host.

## Wrapping up

Your Minio instance should now be available on
[minio.example.com](https://minio.example.com).
