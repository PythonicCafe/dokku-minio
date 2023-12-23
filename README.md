# dokku-minio

![](header.png)

[![MinIO Version](https://img.shields.io/badge/MinIO-latest-blue.svg)]() [![Dokku Version](https://img.shields.io/badge/Dokku-v0.11.2-blue.svg)]()

MinIO is an object storage server, and API compatible with Amazon S3 cloud storage service. Read more at the
[minio.io](https://www.minio.io/) website.

[Dokku](http://dokku.viewdocs.io/dokku/) is the smallest PaaS implementation you've ever seen - _Docker powered
mini-Heroku_.

## Create the app

Execute the following commands on your Dokku host to create the MinIO app and set nginx max upload size for this app.
Change the variable values to fit your case:

```bash
APP_NAME=myminio
ADMIN_EMAIL=admin@myminio.example.net
MINIO_DOMAIN=myminio.example.net
MINIO_REDIRECT_URL=https://myminio.example.net:9001
MINIO_UID=1000
MINIO_GID=1000
STORAGE_PATH=/var/lib/dokku/data/storage/$APP_NAME

dokku apps:create $APP_NAME
```

## Environment variables

```bash
dokku config:set --no-restart $APP_NAME MINIO_ROOT_USER=$(echo `openssl rand -base64 45` | tr -d \=+ | cut -c 1-20)
dokku config:set --no-restart $APP_NAME MINIO_ROOT_PASSWORD=$(echo `openssl rand -base64 45` | tr -d \=+ | cut -c 1-32)
dokku config:set --no-restart $APP_NAME MINIO_BROWSER_REDIRECT_URL=$MINIO_REDIRECT_URL
dokku config:set --no-restart $APP_NAME MINIO_DOMAIN=$MINIO_DOMAIN
```

You can retrieve above values at any time with the command `dokku config:show $APP_NAME`. You may use `MINIO_ROOT_USER`
and `MINIO_ROOT_PASSWORD` to authenticate on the Web interface.

## Persistent storage

To persists uploaded data between restarts, we create a folder on the host machine, add write permissions to the user
defined in `Dockerfile` and tell Dokku to mount it to the app container.

```bash
sudo mkdir -p "$STORAGE_PATH"
sudo chown $MINIO_UID:$MINIO_GID "$STORAGE_PATH"
dokku storage:mount $APP_NAME "$STORAGE_PATH:/data"
dokku nginx:set $APP_NAME client-max-body-size 1g
```

## Domain setup

To get the routing working, we need to apply a few settings. First we set the domain.

```bash
dokku domains:set $APP_NAME $MINIO_DOMAIN
```

The parent Dockerfile, provided by the [MinIO project](https://github.com/minio/minio), exposes port `9000` for Web
requests and `9001` for Web console. Dokku will set up this port for outside communication, as explained in [its
documentation](http://dokku.viewdocs.io/dokku/advanced-usage/proxy-management/#proxy-port-mapping). Because we want
MinIO to be available on the default port `80` (or `443` for SSL), we need to fiddle around with the proxy settings.

First add the correct port mapping for this project as defined in the parent `Dockerfile` and then remove the proxy
mapping added by Dokku.

```bash
dokku proxy:ports-add $APP_NAME http:80:9000 https:443:9000 https:9001:9001
dokku proxy:ports-remove $APP_NAME http:80:5000
```

## Push MinIO to Dokku

First clone this repository to your machine:

```bash
git clone git@github.com:PythonicCafe/dokku-minio.git
```

Now you need to set up your Dokku server as a remote. Run on your local machine:

```bash
git remote add dokku dokku@<dokku-host-machine>:<app-name>
```

Now we can push MinIO to Dokku (_before_ moving on to the [next part](#domain-and-ssl-certificate)):

```bash
git push dokku main
```

These are the only commands you'll need to run on your local machine.

## SSL certificate

Last but not least, we can go an grab the SSL certificate from [Let's Encrypt](https://letsencrypt.org/).
You'll need [dokku-letsencrypt plugin](https://github.com/dokku/dokku-letsencrypt) installed. If it's not, install by
running:

```bash
dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
```

Now get the SSL certificate:

```bash
dokku letsencrypt:set $APP_NAME email $ADMIN_EMAIL
dokku letsencrypt:enable $APP_NAME
```

> **Note**: you must execute these steps *after* pushing the app to Dokku host.

## Wrapping up

Your MinIO instance should now be available on `https://$MINIO_DOMAIN`. Enjoy! :)
