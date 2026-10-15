# Oilix Website and Server

This directory contains the website frontend and Tornado backend copied from the production server.

Production source used for this sync:

```text
54.145.223.218:/wateroil
```

## What Is Included

```text
main.py                  Tornado HTTPS entry point
http_redirect_80.py      HTTP-to-HTTPS redirect helper
handlers/                API handlers
settings/                Routes, config, SQLAlchemy models
utils/                   Shared backend utilities
static/console/          Website frontend console
requirement.txt          Python dependency list copied from production
```

The active website frontend and backend source files are included. No separate React/Vue/Vite source project or `package.json` was found on the production host; the available frontend is the static console currently served from `static/console/`.

## What Is Not Included

These production/runtime files were intentionally excluded from GitHub:

```text
.cookie_secret
apacheAccess.log
apacheError.log
log.txt
handlers/login.py.bak.
handlers/user.py.bak.
settings/urls.py.bak.
settings/urls.py.bak-chatan-apk-20260602
__pycache__/
*.pyc
static/images/
static/console/public/assets/ChatAn.apk
02_02_HUBER_COMBINED_E4000_conformal_params_mobilenetv3.pt
model/mobilenetv3_02_02_HUBER_E4000_conformal_COMBINED_trained.pth
model/water_model.pkl
```

Reason:

- Logs, cache files, and `.bak` files are not active source code.
- `static/images/` contains uploaded production sample images.
- `.cookie_secret`, database credentials, and SSL private keys must not be committed.
- Server-side model weights and APK artifacts are large runtime artifacts and should be restored from production or artifact storage.

## Frontend

Frontend files are stored in:

```text
static/console/
```

Production URL path:

```text
/static/console/index.html#/login
```

To serve the same frontend, deploy `static/console/` with the Tornado server or another static file server that exposes the same path.

The iOS app and web console use the same API and database at `https://wateroil.covlab.tech/`. Image paths returned by that API resolve against this origin. `/history` returns the signed-in account's samples; `/adminphotolist` returns all samples to an administrator, with page, minimum-date, and maximum-date parameters. The mobile administrator view defaults to All Samples and can switch to My Samples. Each view fetches every page before presenting its date-sorted list and map.

Static and template directories are resolved from `settings/configs.py`, not the process entry point. This matters when the service is started by a wrapper outside the application directory: a wrapper must still serve `server/static/`, including both `console/` and uploaded `images/`. Keep the process working directory at the backend root for the existing relative upload and model paths.

Run the isolated path and access-control regression checks without a database or model weights:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s server/tests -v
```

## Backend Requirements

Core dependencies are listed in `requirement.txt`. The copied production dependency file does not fully capture every import used by the model and maintenance scripts. For a fresh environment, also make sure these packages are available:

```text
torch
torchvision
Pillow
numpy
mysql-connector-python
```

`torch` and `torchvision` installation can be platform-specific, especially if CUDA is required. Use the CPU or CUDA wheel appropriate for the deployment machine.

System services needed for a production-like deployment:

```text
Python 3
MySQL
Optional Redis, only if enable_redis is set to True
TLS certificate/key if HTTPS is enabled
```

## Environment Variables

Production secrets are not stored in Git. Set these before running the server:

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

## Runtime Artifacts To Restore

For upload and prediction endpoints to work like production, restore these files/directories outside Git:

```text
server/model/mobilenetv3_02_02_HUBER_E4000_conformal_COMBINED_trained.pth
server/model/water_model.pkl
server/02_02_HUBER_COMBINED_E4000_conformal_params_mobilenetv3.pt
server/static/images/
```

The current upload endpoint calls `utils.model.model_predict`, which expects:

```text
model/mobilenetv3_02_02_HUBER_E4000_conformal_COMBINED_trained.pth
```

`static/images/` must be writable by the server process because uploads are saved there.

## Database Setup

The SQLAlchemy models are defined in `settings/models.py`:

```text
accounts
photos
logs
```

On startup, `settings/application.py` calls `initDatebase(SQLALCHEMY_DATABASE_URI)`, which runs `Base.metadata.create_all(engine)`. For MySQL, create the database and user first, then start the server with the environment variables above.

At minimum, prepare MySQL with a database matching `WATEROIL_DB_NAME` and credentials matching `WATEROIL_DB_USER` / `WATEROIL_DB_PASSWORD`. Production data is not included in Git.

## Reproduce Locally

From the repository root:

```sh
cd server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirement.txt
# Install additional ML/runtime packages as needed:
pip install torch torchvision Pillow numpy mysql-connector-python
mkdir -p static/images model
export WATEROIL_DB_HOST=127.0.0.1
export WATEROIL_DB_PORT=3306
export WATEROIL_DB_NAME=waterOil
export WATEROIL_DB_USER=waterOil
export WATEROIL_DB_PASSWORD='replace-with-local-password'
export WATEROIL_COOKIE_SECRET='replace-with-local-cookie-secret'
python3 main.py
```

For local HTTP-only testing, set `enable_HTTPS = False` in `settings/configs.py` or provide local TLS certificate paths through the SSL environment variables.

## Production Notes

- Production currently serves HTTPS on port `443`.
- `http_redirect_80.py` is a separate HTTP-to-HTTPS redirect helper.
- The current code stores passwords as plain strings in the database model; handle the production database carefully.
- Model files and uploaded images should be managed as deployment artifacts, not Git source files.
