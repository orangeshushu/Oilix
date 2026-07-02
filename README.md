# Oilix Code Repository

This repository contains the Oilix iOS app code and the website/server code currently synced from production.

## Repository Structure

```text
Oilix.xcodeproj              iOS Xcode project
Oilix/                       iOS app source code
server/                      Website frontend and backend code
server/static/console/       Website frontend console
server/main.py               Tornado server entry point
server/handlers/             Backend API handlers
server/settings/             Backend routes, models, and configuration
server/utils/                Backend utility code
```

## iOS App

- Version: `2.0.4`
- Build: `22`
- Bundle ID: `com.mizzou.gcycaas.Oilix`
- Minimum iOS version: `15.0`
- Backend URL used by the app: `https://wateroil.covlab.tech/`

Run locally:

```sh
xcodebuild -project Oilix.xcodeproj \
  -scheme Oilix \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Or open `Oilix.xcodeproj` in Xcode and run the `Oilix` scheme.

## Website Code

The website code is in `server/`.

- Frontend: `server/static/console/`
- Backend: `server/main.py`, `server/handlers/`, `server/settings/`, `server/utils/`
- Website entry page: `/static/console/index.html#/login`

See `server/README.md` for server environment variables and deployment notes.

## Not Included

The repository does not include production-only or sensitive files:

- Database password
- Cookie secret
- SSL private key
- Server logs
- Uploaded user/sample images
- Runtime ML model weight files
- APK distribution artifacts
- Python cache files

These files must be restored from the production environment or artifact storage when deploying the server.

## GitHub

Repository:

```text
git@github.com:orangeshushu/Oilix.git
```

Main branch:

```text
main
```
