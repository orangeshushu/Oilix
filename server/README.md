# Oilix Website and Server

This directory contains the website frontend and Tornado backend copied from the production server.

Production host used for this sync:

```text
54.145.223.218:/wateroil
```

## Directory Structure

```text
main.py                  Tornado HTTPS entry point
http_redirect_80.py      HTTP-to-HTTPS redirect helper
handlers/                API handlers
settings/                Routes, config, SQLAlchemy models
utils/                   Shared backend utilities
static/console/          Website frontend console
```

## Frontend

Frontend files are stored in:

```text
static/console/
```

Production URL path:

```text
/static/console/index.html#/login
```

## Backend

Backend entry point:

```sh
python3 main.py
```

The backend uses Tornado, MySQL, SQLAlchemy, and optional Redis. Dependencies are listed in `requirement.txt`.

## Required Environment Variables

Production secrets are not stored in Git. Set them before running the server:

```sh
export WATEROIL_DB_HOST=127.0.0.1
export WATEROIL_DB_PORT=3306
export WATEROIL_DB_NAME=waterOil
export WATEROIL_DB_USER=waterOil
export WATEROIL_DB_PASSWORD='replace-with-production-password'
export WATEROIL_COOKIE_SECRET='replace-with-cookie-secret'
```

Optional SSL paths:

```sh
export WATEROIL_SSL_CERTFILE=/etc/letsencrypt/live/wateroil.covlab.tech/fullchain.pem
export WATEROIL_SSL_KEYFILE=/etc/letsencrypt/live/wateroil.covlab.tech/privkey.pem
```

## Files Excluded From Git

These production/runtime files are intentionally excluded:

```text
.cookie_secret
*.log
__pycache__/
*.pyc
static/images/
model/
*.pt
*.pth
*.pkl
static/console/public/assets/*.apk
```

Notes:

- `static/images/` contains uploaded sample images.
- `model/` and model weight files are required for prediction endpoints but must be restored outside Git.
- Database credentials and cookie secrets must come from environment variables.
