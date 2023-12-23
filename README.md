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
dokku apps:create minio
```

## Configuration

### Setting environment variables

Minio uses two access keys (`ACCESS_KEY` and `SECRET_KEY`) for authentication
and object management. The following commands sets a random strings for each
access key.

```bash
dokku config:set --no-restart minio MINIO_ROOT_USER=$(echo `openssl rand -base64 45` | tr -d \=+ | cut -c 1-20)
dokku config:set --no-restart minio MINIO_ROOT_PASSWORD=$(echo `openssl rand -base64 45` | tr -d \=+ | cut -c 1-32)
```

To login in the browser or via API, you will need to supply `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`. The following commands set random strings for each variable.

```bash
dokku config:set minio MINIO_ROOT_USER=$(echo `openssl rand -base64 45` | tr -d \=+ | cut -c 1-20)
dokku config:set minio MINIO_ROOT_PASSWORD=$(echo `openssl rand -base64 45` | tr -d \=+ | cut -c 1-32)
```

You can retrieve above values at any time with `dokku config:show minio` command.

## Persistent storage

To persists uploaded data between restarts, we create a folder on the host
machine, add write permissions to the user defined in `Dockerfile` and tell
Dokku to mount it to the app container.

```bash
sudo mkdir -p /var/lib/dokku/data/storage/minio
sudo chown 1000:1000 /var/lib/dokku/data/storage/minio
dokku storage:mount minio /var/lib/dokku/data/storage/minio:/data
```

## Domain setup

To get the routing working, we need to apply a few settings. First we set
the domain.

```bash
dokku domains:set minio minio.example.com
```

The parent Dockerfile, provided by the [Minio
project](https://github.com/minio/minio), exposes port `9000` for web requests and `9001` for web console.
Dokku will set up this port for outside communication, as explained in [its
documentation](http://dokku.viewdocs.io/dokku/advanced-usage/proxy-management/#proxy-port-mapping).
Because we want Minio to be available on the default port `80` (or `443` for
SSL), we need to fiddle around with the proxy settings.

First add the correct port mapping for this project as defined in the parent
`Dockerfile`.

```bash
dokku proxy:ports-add minio http:80:9000 https:443:9000 https:9001:9001
```

Next remove the proxy mapping added by Dokku.

```bash
dokku proxy:ports-remove minio http:80:5000
```

### Application environment variables

```
dokku config:set minio MINIO_BROWSER_REDIRECT_URL=https://minio.example.com:9001
dokku config:set minio MINIO_DOMAIN=minio.example.com
```

## Push Minio to Dokku

### Grabbing the repository

First clone this repository onto your machine.

#### Via SSH

```bash
git clone git@github.com:turicas/minio-dokku.git
```

#### Via HTTPS

```bash
git clone https://github.com/turicas/minio-dokku.git
```

### Set up git remote

Now you need to set up your Dokku server as a remote.

```bash
git remote add dokku dokku@example.com:minio
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
You'll need [dokku-letsencrypt plugin](https://github.com/dokku/dokku-letsencrypt) installed. If it's not, install by running:

```bash
dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
```

Now get the SSL certificate:

```bash
dokku letsencrypt:set minio email you@example.com
dokku letsencrypt:enable minio
```

> **Note**: you must execute these steps *after* pushing the app to Dokku
> host.

## Wrapping up

Your Minio instance should now be available on
[minio.example.com](https://minio.example.com).
