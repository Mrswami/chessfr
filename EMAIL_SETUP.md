# Quick Setup: Email Delivery for CI/CD

## Step-by-Step Guide to Receive APK Builds via Email

### 1. Create Gmail App Password

1. Go to your Google Account: https://myaccount.google.com/
2. Click **Security** (left sidebar)
3. Enable **2-Step Verification** if not already enabled
4. Go back to Security page
5. Click **App passwords** (under "How you sign in to Google")
6. Click **Select app** → Choose "Mail"
7. Click **Select device** → Choose "Other (Custom name)"
8. Type: `ChessUp Pro CI/CD`  
9. Click **Generate**
10. **Copy the 16-character password** (you won't see it again!)

### 2. Add GitHub Secrets

1. Go to your repository: https://github.com/Mrswami/chessup-pro-mobile
2. Click **Settings** tab
3. Click **Secrets and variables** → **Actions** (left sidebar)
4. Click **New repository secret**

Add these 3 secrets:

#### Secret 1: EMAIL_USERNAME
- **Name:** `EMAIL_USERNAME`
- **Value:** Your Gmail address (e.g., `your.email@gmail.com`)
- Click **Add secret**

#### Secret 2: EMAIL_PASSWORD
- **Name:** `EMAIL_PASSWORD`
- **Value:** The 16-character app password from Step 1
- Click **Add secret**

#### Secret 3: EMAIL_TO
- **Name:** `EMAIL_TO`
- **Value:** Email where you want to receive builds (can be same as EMAIL_USERNAME)
- Click **Add secret**

### 3. Verify Setup

Your secrets should look like this:

```
EMAIL_USERNAME = your.email@gmail.com
EMAIL_PASSWORD = abcd efgh ijkl mnop (16 chars)
EMAIL_TO = your.email@gmail.com
```

### 4. Test the Workflow

**Option A: Push a change**
```bash
git add .
git commit -m "test: Trigger CI/CD"
git push
```

**Option B: Manual trigger**
1. Go to https://github.com/Mrswami/chessup-pro-mobile/actions
2. Click **Build and Release Android APK**
3. Click **Run workflow** (right side)
4. Select `master` branch
5. Click **Run workflow** button

### 5. Check Your Email

Within 5-10 minutes, you should receive:

**Subject:** ChessUp Pro v1.0.0 - New Build Available

**Attachment:** `ChessUpPro-v1.0.0-2026-02-11.apk`

### Troubleshooting

#### Email not received?
1. Check spam/junk folder
2. Verify secrets are correct (no typos)
3. Check GitHub Actions logs for errors
4. Ensure workflow ran on `master` branch

#### Build failed?
1. Go to Actions tab
2. Click on the failed workflow
3. Check the error logs
4. Common issues:
   - Flutter version mismatch
   - Missing dependencies
   - Code analysis errors

#### App password not working?
1. Make sure 2-Step Verification is enabled
2. Generate a new app password
3. Update the `EMAIL_PASSWORD` secret

### Security Notes

✅ **App passwords are safe** - They only work for the specific app  
✅ **Never share your app password** - Treat it like a regular password  
✅ **Revoke if compromised** - You can revoke app passwords anytime  
✅ **Use different passwords** - Create separate app passwords for different services  

### Next Steps

Once setup is complete:
- Every push to `master` triggers a build
- APK is automatically emailed to you
- Download from email and install on your Android device
- Test the latest features!

### Alternative: Download from GitHub

If you don't want email delivery:
1. Go to Actions tab
2. Click on any successful workflow
3. Scroll to **Artifacts** section
4. Download the APK

---

**Need help?** Check `CI_CD_GUIDE.md` for detailed documentation.
