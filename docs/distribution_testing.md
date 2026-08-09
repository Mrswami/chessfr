# ChessFr App Distribution & Testing Guide

This guide details how to build, distribute, and install the **ChessFr** app on your physical mobile device for QA testing.

---

## 🚀 1. The Build Pipeline

We have an automated CI/CD pipeline set up via GitHub Actions.
Every push to the `master` or `main` branches triggers the **Build Android APK** workflow (`.github/workflows/build_apk.yml`).

### What the build pipeline does:
1. Compiles a universal **Release APK** (`app-release.apk`).
2. Uploads the build output to GitHub as a workflow run artifact.
3. Automatically pushes the APK to **Firebase App Distribution** for instant tester access.

---

## 📱 2. How to Get the App on Your Phone (Android)

There are two main methods to install the app on your physical device:

### Method A: Firebase App Distribution (Recommended)
1. **Request an Invitation**: Ensure your email address (the one used on your Android phone) is added to the `testers` group in the Firebase Console under **App Distribution**.
2. **Accept the Invite**: You will receive an email from Firebase App Distribution. Tap the **Accept Invitation** link.
3. **Install Firebase App Tester**: Follow the prompts to download the *Firebase App Tester* app (or sign in via web).
4. **Download ChessFr**: Inside the App Tester app, you will see **Chess FR**. Tap **Download** and then **Install**.

> [!NOTE]
> When installing, Android might show a "Blocked by Play Protect" or "Unknown Sources" warning. Since this is a custom-signed test build, tap **Install Anyway** or enable "Install unknown apps" for the App Tester app.

---

### Method B: Direct APK Download (Fastest)
If you do not want to set up Firebase, you can download the APK directly from the GitHub repository:
1. Go to your GitHub repository in your desktop or phone browser.
2. Navigate to the **Actions** tab.
3. Select the latest run of the **Build Android APK** workflow.
4. Scroll down to the **Artifacts** section at the bottom.
5. Download the `release-apk` zip archive, extract the `app-release.apk` file, and copy it to your phone (or download it directly on your phone).
6. Open the `.apk` file on your phone using a File Manager and install it.

---

## 🧪 3. QA Testing Accounts & RBAC

Once the app is running on your phone, you can test our Role-Based Access Control (RBAC) setup:

1. **Create an Account / Sign In**:
   - Sign up with a test email. By default, new accounts start on the **FREE** tier.
2. **Access Premium Features**:
   - Tap **Cognitive Synthesis** on the main dashboard.
   - Since you are on the `FREE` tier, a dialog will alert you that the feature is locked.
3. **Simulate Role Promotion**:
   - Tap **My Profile** in the main list.
   - Look for the **RBAC ROLE SIMULATOR** panel at the top/center of the settings.
   - Tap **PREMIUM** or **ADMIN**. Your database profile will update instantly.
   - Return to the Home Screen. Tap **Cognitive Synthesis** again—it will now open the full dynamic Carlsbad Tabiya and Mutations workshop!
