# Oilix 2.0.6 Store Screenshots

These are unmodified PNG captures of the actual iOS app, taken on October 12, 2026. They replace the outdated three-tab screenshots. No credentials, user profiles, or private sample records are shown.

## Files and Order

Each `en-US` device directory contains five screenshots in this order:

1. `Store-01-Sampling.png`: sampling start screen and four-tab navigation.
2. `Store-02-Instructions.png`: instructions and app tour entry points.
3. `Store-03-First-Use-Tour.png`: interactive image-selection guidance.
4. `Store-04-Sample-Guide.png`: step-by-step sample preparation.
5. `Store-05-Login.png`: sign-in screen with empty credential fields.

`iPhone-Medium` contains 1206 x 2622 captures from iPhone 17 Pro; `iPhone-Large` contains 1320 x 2868 captures from iPhone 17 Pro Max. Both use iOS 26.5, English, portrait orientation, standard text size, light appearance, and a 09:41 status bar. All PNGs have no alpha channel.

## Reproduce

Use a dedicated simulator without personal data. Supply an authorized test account through environment variables, never in source control. The test signs in but does not upload, edit, or delete server records.

```sh
TEST_RUNNER_OILIX_LIVE_QA=1 \
TEST_RUNNER_OILIX_STORE_SCREENSHOTS=1 \
TEST_RUNNER_OILIX_TEST_USERNAME="$OILIX_TEST_USERNAME" \
TEST_RUNNER_OILIX_TEST_PASSWORD="$OILIX_TEST_PASSWORD" \
xcodebuild test -project Oilix.xcodeproj -scheme Oilix \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath /tmp/OilixStoreCaptureBuild \
  -resultBundlePath "$RESULT_PATH" \
  -parallel-testing-enabled NO \
  '-only-testing:OilixUITests/InstructionsUITests/testAppStoreScreenshots()' \
  CODE_SIGNING_ALLOWED=NO

xcrun xcresulttool get test-results summary --path "$RESULT_PATH" --format json
xcrun xcresulttool export attachments --path "$RESULT_PATH" --output-path "$OUTPUT_PATH"
```

Use a new result path for each run. Verify one test passed, not just a successful command exit. Export only attachments named `Store-*`; failed-test diagnostics can contain account information. Inspect every image before upload. Preserve the PNG bytes and use the numbered filenames above for upload order.

## App Store Placement

Upload each set to its corresponding Dynamic Island display size in Media Manager. The old Face ID large-display and Home Button large-display placements were removed from the 2.0.6 draft so smaller-device listings can inherit the new screenshots. Old assets remain in Asset Library for recovery.

An uploaded screenshot is not yet a public screenshot. It becomes public with the approved and released 2.0.6 version; see `ReleaseNotes/2.0.6.md` for submission status.
