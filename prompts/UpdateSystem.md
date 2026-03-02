"Hi, we need to implement a robust Remote Version Control and In-App Update System since our app is distributed outside the Play Store. Please follow these technical specifications:

1. Versioning Strategy (pubspec.yaml)
Every build must follow the Major.Minor.Patch+BuildNumber format (e.g., 1.1.0+2).

The Build Number (the integer after +) must be incremented for every single release. This is what our update logic will compare.

2. Remote Configuration (The Source of Truth)
Host a small JSON file (e.g., on GitHub Gist, Firebase, or our own server) with the following structure:

JSON
{
  "latest_version_code": 2,
  "latest_version_name": "1.1.0",
  "update_url": "https://example.com/downloads/app-v1.1.0.apk",
  "is_force_update": false,
  "whats_new": [
    "Smart Incremental Sync added",
    "Fixed SkyMoviesHD link extraction",
    "Professional Download History UI",
    "Corrected file naming bug"
  ]
}
3. Flutter Implementation Logic
Package Requirements: Use package_info_plus to get the current app version and ota_update or url_launcher for downloading the new APK.

Startup Check: On onInit of the Splash screen or Home screen, fetch the remote JSON.

Comparison Logic: * If remote.latest_version_code > local.build_number:
* Show a custom Update Dialog.
* If is_force_update is true, make the dialog non-dismissible.

UI/UX: The dialog should display the whats_new list in bullet points so users know why they are updating.

4. The Update Process
When the user clicks 'Update Now', show a Linear Progress Bar or a notification indicating the download percentage.

Once downloaded, trigger the APK Intent to open the Android package installer automatically.

5. Persistence & Security
Ensure the Signing Key (JKS) used for this build is securely stored. Future updates will fail to install if the signing key changes."