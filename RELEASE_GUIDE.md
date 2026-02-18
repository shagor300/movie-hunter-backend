# MovieHub Release & App Signing Guide

This guide explains how to manage your app signing (Keystore) and generate release builds for MovieHub.

## 1. Important Files
- **Keystore File**: `android/app/upload-keystore.jks` - Contains your digital signature.
- **Key Properties**: `android/key.properties` - Contains passwords for automatically signing the app.

> [!CAUTION]
> **BACKUP THE KEYSTORE!**
> If you lose the `upload-keystore.jks` file, you will **NEVER** be able to update your existing app. Back it up to a secure offline location or private cloud storage (Google Drive/Dropbox).

## 2. Security
Both files are listed in `.gitignore` and **not pushed to GitHub**. This prevents unauthorized people from signing and releasing app updates in your name.

## 3. Versioning
Before building a new version of the app, you must increment the version number.
1. Open `pubspec.yaml`.
2. Locate the line: `version: 1.1.0+2`.
3. Increment the **Version Code** (the number after `+`).
   - Example: For the next update, change it to `1.1.0+3`.
   - The user-visible version name (`1.1.0`) can be changed whenever you want.

## 4. Building the APK
To generate a signed, production-ready APK, run the following command in your terminal:

```powershell
flutter build apk --release
```

The resulting file will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

## 5. Troubleshooting
If the build fails due to a Gradle error:
1. Run `flutter clean`.
2. Run `flutter pub get`.
3. Try the build command again.

---
*Created by Antigravity AI on 2026-02-15*
