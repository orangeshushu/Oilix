# Oilix

Oilix is an integrated water/oil contamination sampling and management system. The project includes an iOS app for field sampling, a web console for administrative review, and a Tornado backend that stores users, uploaded samples, metadata, and analysis results.

The system is designed around a simple workflow: a field user captures or selects a sample image, confirms the sample time and GPS location, adds notes when needed, and uploads the sample to the backend. The backend stores the image and related metadata, runs or records the analysis result, and exposes the data to the mobile history screen and the web console. Administrators can use the website to review uploaded samples, search/filter records, edit sample metadata, manage tags and notes, and view registered users.

This repository keeps the mobile app and website/server code together so the project can be rebuilt, reviewed, and handed off from one place. Production-only data and secrets are intentionally excluded from Git.

## System Components

- iOS app: field sampling, image selection/capture, GPS metadata, notes, upload progress, searchable history with image previews, history map, and built-in instructions.
- Website frontend: browser-based console for administrator login, sample review, filtering, editing, and user review.
- Backend server: Tornado API service for authentication, upload handling, history retrieval, admin operations, user profile data, and database access.

## Repository Structure

```text
Oilix.xcodeproj              iOS Xcode project
Oilix/                       iOS app source code
OilixTests/                  Isolated iOS unit tests
OilixUITests/                UI checks and opt-in store screenshot capture
AppStoreAssets/              Versioned App Store screenshots and capture instructions
ReleaseNotes/                Version-specific release and verification records
server/                      Website frontend and backend code
server/static/console/       Website frontend console
server/main.py               Tornado server entry point
server/handlers/             Backend API handlers
server/settings/             Backend routes, models, and configuration
server/utils/                Backend utility code
```

## iOS App

- Source version: `2.0.6`
- Build: `24`
- Bundle ID: `com.mizzou.gcycaas.Oilix`
- Minimum iOS version: `15.0`
- Backend URL used by the app: `https://wateroil.covlab.tech/`

Version 2.0.6 contains the redesigned app, Jeff's step-by-step instructions, and the first-use app tour introduced in 2.0.5. The 2.0.6 release refreshes the App Store screenshots and retains the same app functionality. See [release notes](ReleaseNotes/2.0.6.md) for the dated submission record and verification results, and [store screenshots](AppStoreAssets/Screenshots/2.0.6/README.md) for the submitted images and capture steps.

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
  CODE_SIGNING_ALLOWED=NO \
  build
```

Notes:

- The app backend URL is defined in `Oilix/OilixApp.swift` as `https://wateroil.covlab.tech/`.
- Xcode resolves the pinned Alamofire 5.4.4 dependency. The two bundled Core ML model files and the shared Oilix scheme are included.
- A physical-device build may require a valid Apple Developer Team and signing setup.
- The Oilix camera workflow expects the camera access point/device constants defined in `Oilix/OilixApp.swift`.

### App Workflow

History reads the same production database and image files as the web console. Administrators start in All Samples and can use the scope menu to switch to My Samples; ordinary users only receive their own history. All Samples includes uploader names and supports searching by uploader, notes, or tags. The selected scope applies to both List and Map. Every server page is fetched before sorting records newest first, and changing scope clears the previous records so a failed request cannot show another scope's data.

1. Sign in using the default User mode, or select Admin for an administrator account.
2. Open Sampling and choose images from the photo library, Files, or Oilix Cam.
3. Review each image and update its notes or GPS coordinates before uploading. Removing the last selected image returns to the sampling start screen and keeps the original photo.
4. Upload the selected images. The app displays progress and prediction results, keeps failed images available for review, and excludes successfully uploaded images from subsequent uploads.
5. Open History to browse previews in newest-first order, search notes or tags, refresh records, and explore sample locations on the map.

After sign-in, the bottom navigation contains four tabs in workflow order: Sampling, History, Instructions, and Settings. Sampling is the initial tab, with centered image selection and a large, tappable Oilix Cam button. Instructions puts the app tour and three procedural guides first, followed by shortcuts and a collapsed About Oilix introduction. Each guide opens in Step by Step mode with a step count, reading progress, and Previous/Next controls; All Steps shows the complete procedure. Reading progress is not a record of completed lab work and is not saved between visits. Its detail pages use standard back navigation and remain inside the tab; switching tabs does not reset the selected images.

The first signed-in session presents a five-step, skippable app tour. It highlights image selection, Oilix Cam, history search, the profile group, and instructions. Next/Back moves between these screens without opening image pickers, capturing photos, changing profile data, or uploading anything. Completion or Skip is remembered locally across launches and sign-outs. Selecting another tab exits the tour and keeps that tab selected. Replay App Tour in the Instructions tab starts it again without clearing selected images. At accessibility text sizes and in short landscape layouts, the tour uses a scrollable explanation with persistent navigation controls instead of a spotlight that could overlap the text.

Settings groups personal details and Edit Profile under Personal Profile, map/deletion preferences under Map & Deletion, and account deletion under Account Management. Each group expands on demand. Profile editing still uses a separate page with Save and Cancel; sign-out remains directly accessible. Administrators retain access to Registered Users. Acknowledgements is available from Settings and Instructions and lists the project institutions shown on the login screen.

Instructions are also available before sign-in, from the Sampling menu, from History, and in Settings. These secondary entries open a dismissible sheet with a Done action. The web database opens at `https://wateroil.web.app`.

The Sampling start screen opens the preparation guide directly with standard back navigation. The Instructions tab and relevant guide details link directly to Sampling and upload History without clearing the current image selection. These authenticated shortcuts are not shown in the pre-sign-in guide. The analysis steps name the current image-source controls; the preparation quantities and times retain the supplied procedure.

### Tests

Select the `Oilix` scheme in Xcode and use Product > Test. The shared scheme includes `OilixTests` for upload behavior, account validation and failure recovery, history pagination, import cancellation, image metadata, location authorization and freshness, camera cancellation and duplicate-capture prevention, and first-use guide completion, skipping, back navigation, and replay. `OilixUITests` covers login modes, centered logos, aligned credential fields, password visibility, username clearing without losing the password draft, instruction navigation, step-by-step reading and its boundaries, full-procedure mode, registration validation, password-reset draft protection, and landscape login and instruction access. The optional signed-in tour/settings UI check also verifies the large camera button's size, alignment, and ability to open and dismiss Oilix Cam without capturing. It is skipped unless the test runner receives `OILIX_LIVE_QA=1` and owner-supplied `OILIX_TEST_USERNAME` / `OILIX_TEST_PASSWORD`; it only logs in, reads records/profile data and camera connection status, and navigates without capturing, saving, or uploading. Supply those as runtime environment variables, never source files.

For command-line live checks, prefix each variable with `TEST_RUNNER_` when invoking `xcodebuild`, for example `TEST_RUNNER_OILIX_LIVE_QA=1`. Xcode passes these values to the test runner without the prefix. The store screenshot instructions include a complete example. Live checks remain opt-in for normal local test runs.

To run the tests from the command line, choose an available simulator:

```sh
xcodebuild -project Oilix.xcodeproj \
  -scheme Oilix \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  test
```

Network unit tests use isolated fixtures and do not modify production accounts or upload images to the production server. UI tests never submit the registration or password-reset forms.

The opt-in `testSharedDatabaseHistoryAndImages` check uses the same runtime credentials to verify administrator All Samples/My Samples switching, record counts, whole-row navigation, and loading a real database image in Sample Details. It reads existing production data without changing records. Backend path and administrator-access checks are documented in `server/README.md`.

### Usability and Recovery

- Registration and password reset validate inputs and require matching new passwords of 8 to 255 characters. Existing users can still sign in with their existing passwords. Name fields match the server's 50-character limit.
- Profile editing opens separately with explicit Save and Cancel actions. Failed saves keep the draft; leaving a changed form requires confirmation.
- Photo and Files imports preserve selection order, read metadata away from the main UI thread, show progress, and support cancellation. Uploading is disabled until import finishes.
- Signing out requires confirmation and warns about unuploaded selections. Account actions are disabled during image import or upload, and only confirmed server success clears the signed-in account.
- History retrieves all server pages before publishing its sorted snapshot. Failed refreshes keep the previous in-memory records visible; this is not persistent offline storage.
- History previews distinguish loading from an unavailable image. An unavailable preview does not hide the record or prevent opening its details. Missing image files on the server need to be restored separately; the app does not fabricate replacement previews.
- Sample details show the upload date without inventing a capture time, handle missing GPS safely, support image retry and full-screen pinch zoom, and can open valid coordinates in Apple Maps.
- Passwords are no longer written to preferences or logged by the mobile login flow. Any old preference-stored password is removed after a successful sign-in.

These are client-side improvements. They do not change or certify the backend authentication, password-reset, or account-storage security; those require a separate production security review before a commercial release.

### iPhone Compatibility

The interface uses native navigation, tabs, and grouped account forms. Login retains the original oil-on-water photograph as its full-screen background, centers larger university logos above the app name, and uses a two-row credential form with persistent inline labels, equal-width input areas, and fixed trailing controls. A light photo overlay keeps the dark app name and subtitle readable in either appearance. The native User/Admin control uses a solid dark-blue selected segment with white text and dark text for the unselected segment; this styling is local to login and does not alter other segmented controls. Accessibility text sizes place labels above the fields and stack account actions. Sampling opens directly to image-source actions; image review uses an equal-width tool strip and a separate upload action. History keeps the search field above both List and Map. Details emphasize the prediction and group the remaining metadata into consistent rows. Primary actions share one button style rather than oversized rounded pills.

- The deployment target remains iOS 15.0. iOS 16 and later use `NavigationStack` and interactive scroll-to-dismiss keyboards; iOS 15 retains the compatible navigation and explicit Done controls.
- iPhone portrait and both landscape orientations are supported. On short-height screens or with accessibility text sizes, upload actions scroll with the sample instead of covering the preview.
- Oilix Cam uses an adaptive, scrollable capture screen with a persistent shutter area at standard text sizes. Accessibility text sizes keep the shutter in the scrollable content. Requests have timeouts, duplicate captures are blocked, and leaving the screen or entering the background cancels pending camera requests.
- The app declares Local Network access for Oilix Cam and enables only the local-network ATS exception. It does not disable transport security globally; the cloud backend continues to use HTTPS.
- Location is requested when needed. Denied or restricted access does not repeatedly prompt; users can enter coordinates manually. Invalid readings or readings older than two minutes are not used as current GPS data, and hidden location screens stop requesting updates.
- Map markers use semantic system colors and adaptive sizing, with full result values available to accessibility rather than a five-character prefix.

The available simulator matrix is iPhone SE (3rd generation) on iOS 26.5, iPhone 16e on iOS 26.2, and iPhone 17 Pro Max on iOS 26.5. Simulator checks cover portrait/landscape, keyboard and navigation, dark appearance, and accessibility text sizes. iOS 15 through 18 are covered by the deployment target and API availability guards, but still need runtime checks on older systems. Physical Oilix Cam connectivity, Local Network permission prompts, GPS accuracy, and real iCloud imports require device testing.

This repository is a native iPhone app. It does not contain an Android app or a dedicated iPad interface.

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
