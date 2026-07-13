# Play Store Release

This document summarizes the steps and checklist to prepare CarScore for publishing on the Google Play Store.

## Key requirements

- Remove any dependency on `localhost` from the release build.
- Configure environment flavors (dev, staging, prod).
- Ensure release signing with keystore and correct versioning.
- Review and minimize Android permissions.
- Provide a public privacy policy URL and Data Safety answers.

## Release checklist

- Generate signed AAB and verify installation
- Fill Play Console Data Safety form
- Upload icon, screenshots and feature graphic
- Validate flows on physical Android device
- Run degradation tests for external providers (FIPE/offers)

## Build helpers

- See `mobile_app/PLAYSTORE_RELEASE.md` and `mobile_app/scripts/build-android-release.ps1` for detailed scripts used locally.
