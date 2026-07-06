# Oilix

Oilix is an integrated water/oil contamination sampling and management system. The project includes an iOS app for field sampling, a web console for administrative review, and a Tornado backend that stores users, uploaded samples, metadata, and analysis results.

The system is designed around a simple workflow: a field user captures or selects a sample image, confirms the sample time and GPS location, adds notes when needed, and uploads the sample to the backend. The backend stores the image and related metadata, runs or records the analysis result, and exposes the data to the mobile history screen and the web console. Administrators can use the website to review uploaded samples, search/filter records, edit sample metadata, manage tags and notes, and view registered users.

This repository keeps the mobile app and website/server code together so the project can be rebuilt, reviewed, and handed off from one place. Production-only data and secrets are intentionally excluded from Git.

## System Components

- iOS app: field sampling, image selection/capture, GPS metadata, notes, upload, history list, and history map.
- Website frontend: browser-based console for administrator login, sample review, filtering, editing, and user review.
- Backend server: Tornado API service for authentication, upload handling, history retrieval, admin operations, user profile data, and database access.

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

## Sync Audit

Audit status: at the time of this review, `main` was synced with `origin/main`.

Uploaded to GitHub:

- iOS app source, Xcode project, app assets, Core ML model files used by the app, and Swift Package resolution file.
- Website frontend files under `server/static/console/`.
- Website backend files under `server/main.py`, `server/handlers/`, `server/settings/`, and `server/utils/`.
- Server documentation and ignore rules.

Not uploaded because they are not source code or contain production/runtime data:

- macOS and Xcode local state files such as `.DS_Store` and `*.xcuserstate`.
- Server logs and Python cache files.
- Production uploaded sample images.
- Production cookie secret, database password, and SSL private key.
- Large server-side ML model weights and APK distribution artifacts.
- Old production backup files such as `*.bak`.

Conclusion: no active iOS app code or active website frontend/backend code is currently missing from GitHub. Full production restoration still requires the excluded runtime artifacts listed in `server/README.md`.

## iOS App

- Version: `2.0.4`
- Build: `22`
- Bundle ID: `com.mizzou.gcycaas.Oilix`
- Minimum iOS version: `15.0`
- Backend URL used by the app: `https://wateroil.covlab.tech/`

Reproduce locally:

1. Open `Oilix.xcodeproj` in Xcode.
2. Let Xcode resolve Swift Package dependencies from `Package.resolved`.
3. Select the `Oilix` scheme.
4. Choose an iOS simulator or a signed physical device.
5. Build and run.

Command-line build:

```sh
xcodebuild -project Oilix.xcodeproj \
  -scheme Oilix \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Notes:

- The app backend URL is defined in `Oilix/OilixApp.swift` as `https://wateroil.covlab.tech/`.
- A physical-device build may require a valid Apple Developer Team and signing setup.
- The Oilix camera workflow expects the camera access point/device constants defined in `Oilix/OilixApp.swift`.

## Website Code

The website code is in `server/`.

- Frontend: `server/static/console/`
- Backend: `server/main.py`, `server/handlers/`, `server/settings/`, `server/utils/`
- Website entry page: `/static/console/index.html#/login`

See `server/README.md` for exact server reproduction steps, required environment variables, database setup notes, and excluded runtime artifact names.

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
