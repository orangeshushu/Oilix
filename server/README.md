# Oilix Web Console and Server

This directory contains the deployed Oilix website/server code copied from the production host at `54.145.223.218`.

## Contents

- `main.py`: Tornado application entry point.
- `http_redirect_80.py`: HTTP redirect helper.
- `handlers/`: API request handlers for login, registration, uploads, history, admin photo management, user management, and search filters.
- `settings/`: Tornado routes, application setup, database models, Redis helper, and configuration.
- `static/console/`: Browser console served from `/static/console/index.html`.
- `utils/`: Database initialization, model helpers, logging, and string utilities.

## Excluded From Git

The following production/runtime data is intentionally not committed:

- Cookie secret file: `.cookie_secret`
- Logs: `*.log`, `apacheAccess.log`, `apacheError.log`
- Python cache files: `__pycache__/`, `*.pyc`
- Uploaded sample images: `static/images/`
- Runtime ML model weights: `model/`, `*.pt`, `*.pth`, `*.pkl`
- APK distribution files under `static/console/public/assets/*.apk`

These files should be restored from the deployment environment or artifact storage when deploying a production server.

## Required Environment Variables

Sensitive values are read from environment variables instead of being stored in Git:

```sh
export WATEROIL_DB_HOST=127.0.0.1
export WATEROIL_DB_PORT=3306
export WATEROIL_DB_NAME=waterOil
export WATEROIL_DB_USER=waterOil
export WATEROIL_DB_PASSWORD='replace-with-production-password'
export WATEROIL_COOKIE_SECRET='replace-with-cookie-secret'
```

Optional SSL overrides:

```sh
export WATEROIL_SSL_CERTFILE=/etc/letsencrypt/live/wateroil.covlab.tech/fullchain.pem
export WATEROIL_SSL_KEYFILE=/etc/letsencrypt/live/wateroil.covlab.tech/privkey.pem
```

## Running

Install dependencies from `requirement.txt`, configure the environment variables above, restore the runtime model files if prediction endpoints are needed, and run:

```sh
python3 main.py
```

The production process currently serves HTTPS on port `443` and exposes the console at:

```text
/static/console/index.html#/login
```
