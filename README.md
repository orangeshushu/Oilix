# Oilix

Oilix is an iOS app for sampling water/oil images, uploading samples, and reviewing upload history with list and map views.

## Current Version

- App version: 2.0.4
- Build number: 22
- Bundle identifier: `com.mizzou.gcycaas.Oilix`
- Minimum iOS version: iOS 15.0
- Backend server: `https://wateroil.covlab.tech/`

## Recent Updates

- Added normal user and administrator login modes.
- Administrators can view the registered user list.
- Normal users cannot access the user list.
- All users can view their profile and edit profile details on a separate profile edit page.
- Settings now displays profile fields as `Name:` and `Email:`.
- Improved selected-image deletion before upload.
- When a user selects an image and taps `Delete Image` before uploading, the selected image is removed and the user returns to the sampling home screen.
- Improved the upload flow so users are moved to the result/detail experience more quickly after upload.
- History list items now include thumbnail previews.
- History list is sorted by sample time from newest to oldest.
- History map now defaults to the user's current location when available.
- Uploaded image metadata, notes, location, and sample time remain editable before upload.

## Main Screens

- Login: supports normal user login, administrator login, registration, and password reset.
- Sampling: supports camera capture, photo library import, image preview, delete, note editing, location editing, and upload.
- History: supports list and map views for uploaded samples.
- Settings: supports delete confirmation preference, profile display, profile editing, account deletion, logout, and administrator-only user list access.

## Running Locally

1. Open `Oilix.xcodeproj` in Xcode.
2. Select the `Oilix` scheme.
3. Choose an iOS simulator or a signed physical device.
4. Build and run.

Command-line build example:

```sh
xcodebuild -project Oilix.xcodeproj \
  -scheme Oilix \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## GitHub Sync

This repository is synced to:

```text
git@github.com:orangeshushu/Oilix.git
```

Current branch:

```text
main
```

The current source code has been built successfully with Xcode and pushed to GitHub.

