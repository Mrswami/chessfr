# CI/CD Setup Guide

## Overview
This project uses GitHub Actions for automated building, testing, and deployment of the ChessUp Pro mobile app.

## Workflows

### 1. **Build and Release** (`.github/workflows/build-and-release.yml`)
**Triggers:**
- Push to `master` or `main` branch
- Pull requests
- Manual trigger via GitHub UI

**What it does:**
1. ✅ Checks out code
2. ✅ Sets up Java 17 and Flutter 3.38.9
3. ✅ Installs dependencies (`flutter pub get`)
4. ✅ Runs tests (continues on failure)
5. ✅ Analyzes code (continues on warnings)
6. ✅ Builds release APK
7. ✅ Renames APK with version and date
8. ✅ Uploads APK as artifact (30-day retention)
9. ✅ **Emails APK to you** (on master branch pushes)

**Artifacts:**
- `ChessUpPro-v{version}-{date}.apk`

### 2. **Pull Request Checks** (`.github/workflows/pr-checks.yml`)
**Triggers:**
- Pull request opened, updated, or reopened

**What it does:**
1. ✅ Checks code formatting
2. ✅ Runs static analysis
3. ✅ Runs tests
4. ✅ Verifies debug build compiles

**Purpose:** Ensures code quality before merging

### 3. **Manual Release** (`.github/workflows/manual-release.yml`)
**Triggers:**
- Manual trigger only (via GitHub Actions UI)

**Inputs:**
- `version_bump`: Choose patch/minor/major
- `send_email`: Toggle email delivery

**What it does:**
1. ✅ Builds release APK
2. ✅ Builds App Bundle (AAB) for Play Store
3. ✅ Creates GitHub Release with both files
4. ✅ Optionally emails APK

**Use case:** Creating official releases for distribution

## Setup Instructions

### Step 1: Configure GitHub Secrets
Go to your GitHub repo → Settings → Secrets and variables → Actions

Add these secrets:

#### **EMAIL_USERNAME**
Your Gmail address (e.g., `your.email@gmail.com`)

#### **EMAIL_PASSWORD**
Gmail App Password (NOT your regular password):
1. Go to https://myaccount.google.com/apppasswords
2. Select "Mail" and "Other (Custom name)"
3. Name it "ChessUp Pro CI/CD"
4. Copy the 16-character password
5. Paste it as the secret value

#### **EMAIL_TO**
Email address where you want to receive builds (can be the same as EMAIL_USERNAME)

### Step 2: Enable GitHub Actions
1. Go to your repo on GitHub
2. Click "Actions" tab
3. If prompted, click "I understand my workflows, go ahead and enable them"

### Step 3: Test the Workflow
**Option A: Push to master**
```bash
git add .
git commit -m "feat: Add responsive design and auto-connect"
git push origin master
```

**Option B: Manual trigger**
1. Go to Actions tab
2. Select "Build and Release Android APK"
3. Click "Run workflow"
4. Select branch and click "Run workflow"

## How to Use

### Automatic Builds (Every Push)
Simply push to master:
```bash
git add .
git commit -m "Your commit message"
git push
```

Within 5-10 minutes, you'll receive an email with the APK attached!

### Manual Release Build
1. Go to GitHub → Actions
2. Select "Manual Release Build"
3. Click "Run workflow"
4. Choose version bump type
5. Toggle "Send APK via email"
6. Click "Run workflow"

### Download Previous Builds
1. Go to GitHub → Actions
2. Click on any successful workflow run
3. Scroll to "Artifacts" section
4. Download the APK

## Email Format

You'll receive an email like this:

```
Subject: ChessUp Pro v1.0.0 - New Build Available

🎉 New ChessUp Pro build is ready!

Version: 1.0.0+1
Build Date: 2026-02-11
Commit: abc1234
Branch: master

Changes in this build:
feat: Add responsive design and auto-connect

The APK is attached to this email.

Download and install on your Android device to test the latest features!
```

**Attachment:** `ChessUpPro-v1.0.0-2026-02-11.apk`

## Build Artifacts

### APK (Android Package)
- **File:** `.apk`
- **Use:** Direct installation on Android devices
- **Size:** ~20-50 MB
- **Distribution:** Email, direct download

### AAB (Android App Bundle)
- **File:** `.aab`
- **Use:** Google Play Store submission
- **Size:** Smaller than APK
- **Distribution:** Play Store only

## Troubleshooting

### Build Fails
**Check:**
1. Flutter version compatibility
2. Dependencies in `pubspec.yaml`
3. Code analysis errors
4. Build logs in Actions tab

### Email Not Received
**Check:**
1. GitHub Secrets are set correctly
2. Gmail App Password is valid
3. Spam/junk folder
4. Workflow ran on `master` branch

### APK Won't Install
**Check:**
1. "Install from Unknown Sources" is enabled
2. Previous version is uninstalled (if signature changed)
3. Device has enough storage
4. APK is not corrupted (re-download)

## Advanced Configuration

### Change Flutter Version
Edit `.github/workflows/build-and-release.yml`:
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.38.9'  # Change this
```

### Change Email Provider
Replace Gmail SMTP with your provider:
```yaml
server_address: smtp.gmail.com  # Change this
server_port: 465                # Change this
```

### Add Slack Notifications
Add this step after build:
```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Add Firebase App Distribution
```yaml
- name: Upload to Firebase
  uses: wzieba/Firebase-Distribution-Github-Action@v1
  with:
    appId: ${{ secrets.FIREBASE_APP_ID }}
    token: ${{ secrets.FIREBASE_TOKEN }}
    file: build/app/outputs/flutter-apk/app-release.apk
```

## Workflow Status Badges

Add to your README.md:

```markdown
![Build Status](https://github.com/Mrswami/chessup-pro-mobile/workflows/Build%20and%20Release%20Android%20APK/badge.svg)
```

## Cost & Limits

### GitHub Actions (Free Tier)
- **2,000 minutes/month** for private repos
- **Unlimited** for public repos
- Each build takes ~5-10 minutes
- **Estimate:** 200-400 builds/month (free)

### Gmail Sending Limits
- **500 emails/day** (Gmail free)
- **2,000 emails/day** (Google Workspace)
- Each build = 1 email
- **Estimate:** More than enough for development

## Security Best Practices

✅ **Never commit secrets** to the repository  
✅ **Use GitHub Secrets** for sensitive data  
✅ **Use App Passwords** instead of account passwords  
✅ **Rotate secrets** periodically  
✅ **Review workflow logs** for exposed data  

## Next Steps

### Recommended Additions
1. **Code Coverage Reports** - Track test coverage
2. **Automated Testing** - Add more unit/widget tests
3. **Performance Monitoring** - Firebase Performance
4. **Crash Reporting** - Firebase Crashlytics
5. **Beta Testing** - Firebase App Distribution
6. **Play Store Deployment** - Automated AAB upload

### Future Enhancements
- Automated version bumping
- Changelog generation
- Screenshot automation
- Multi-platform builds (iOS)
- Staged rollouts

## Support

**Issues with CI/CD?**
- Check GitHub Actions logs
- Review this documentation
- Check GitHub Actions status page
- Verify secrets are configured

**Questions?**
- GitHub Actions docs: https://docs.github.com/en/actions
- Flutter CI/CD guide: https://docs.flutter.dev/deployment/cd
