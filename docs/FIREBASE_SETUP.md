# Firebase Setup & Tester Distribution Guide

To enable push notifications and distribute pre-release versions of the app to testers, we need to fully configure the Firebase project.

## 1. Create Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **"Add project"** and name it `ChessPersonalTrainer`.
3. Disable Google Analytics for now (simplifies setup) or enable if desired.
4. Click **"Create project"**.

## 2. Register Your Apps
Once the project is created, you need to add the Android and iOS apps.

### Android
1. Click the **Android icon** (bugdroid).
2. **Package name**: `com.mrswami.chess_trainer` (Check `android/app/build.gradle` `applicationId` to confirm).
3. **App nickname**: `Chess Trainer (Android)`.
4. Click **"Register app"**.
5. **Download `google-services.json`**.
6. Move this file to: `flutter/android/app/google-services.json`.

### iOS
1. In the Project Overview, click **"Add app"** > **iOS icon**.
2. **Bundle ID**: `com.example.chessTrainer` (Check `ios/Runner.xcodeproj` or open in Xcode to confirm).
3. **App nickname**: `Chess Trainer (iOS)`.
4. Click **"Register app"**.
5. **Download `GoogleService-Info.plist`**.
6. Move this file to: `flutter/ios/Runner/GoogleService-Info.plist` (Open the project in Xcode to ensure it's added to the target).

## 3. Set Up App Distribution (Testers)
Firebase App Distribution lets you send `.apk` (Android) and `.ipa` (iOS) files directly to testers.

1. In the Firebase Console left menu, go to **Release & Monitor** > **App Distribution**.
2. Accept the terms of service.
3. Click the **"Testers & Groups"** tab.
4. **Add testers**: Enter the email addresses of your testers (including yourself).
5. (Optional) Create a group called `Internal Testers`.

## 4. Distribute a Build
### Android
1. Build the APK:
   ```bash
   cd flutter
   flutter build apk --release
   ```
2. Upload the file `build/app/outputs/flutter-apk/app-release.apk` to the App Distribution dashboard.
3. Select your tester group and click **Distribute**.
4. Testers will receive an email with instructions to download the specific app tester app.

## 5. Test Account (Supabase Auth)
Since authentication is handled by Supabase, "testers" need a valid account to log in.

**Recommended Test Account:**
- **Email**: `tester@chess.com`
- **Password**: `password123`
- **Role**: Free (default) or upgrade to Premium/Admin using the separate Admin Dashboard.

Create this account manually via the app's Sign Up screen or the Supabase dashboard.
