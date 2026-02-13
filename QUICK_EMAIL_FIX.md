# Quick Email Setup Fix

## 🔧 Step-by-Step Fix

### 1. Create/Verify Gmail App Password

1. Go to: **https://myaccount.google.com/apppasswords**
2. If you see "App passwords aren't available", enable **2-Step Verification** first:
   - Go to: https://myaccount.google.com/security
   - Enable "2-Step Verification"
   - Then return to app passwords page

3. Create new app password:
   - Click **Select app** → Choose **"Mail"**
   - Click **Select device** → Choose **"Other (Custom name)"**
   - Type: `ChessUp Pro CI/CD`
   - Click **Generate**
   - **Copy the 16-character password** (it looks like: `abcd efgh ijkl mnop`)
   - **Remove all spaces** → `abcdefghijklmnop`

### 2. Add/Update GitHub Secrets

Go to: **https://github.com/Mrswami/chessup-pro-mobile/settings/secrets/actions**

#### Secret 1: EMAIL_USERNAME
- Click **New repository secret**
- Name: `EMAIL_USERNAME`
- Value: Your Gmail address (e.g., `yourname@gmail.com`)
- Click **Add secret**

#### Secret 2: EMAIL_PASSWORD
- Click **New repository secret**
- Name: `EMAIL_PASSWORD`
- Value: The 16-character app password from Step 1 (NO SPACES)
- Example: `abcdefghijklmnop`
- Click **Add secret**

#### Secret 3: EMAIL_TO
- Click **New repository secret**
- Name: `EMAIL_TO`
- Value: Email where you want to receive builds (can be same as EMAIL_USERNAME)
- Click **Add secret**

### 3. Verify Secrets

Your secrets page should show:
```
EMAIL_USERNAME    (hidden)
EMAIL_PASSWORD    (hidden)
EMAIL_TO          (hidden)
```

### 4. Test the Setup

**Option A: Manual Trigger (Recommended)**
1. Go to: https://github.com/Mrswami/chessup-pro-mobile/actions/workflows/build-and-release.yml
2. Click **Run workflow** (right side)
3. Select `master` branch
4. Click **Run workflow**
5. Wait ~8-10 minutes
6. Check your email (and spam folder)

**Option B: Push a Test Commit**
```bash
git commit --allow-empty -m "test: Verify email configuration"
git push
```

### 5. Check Results

**If email arrives:**
✅ Setup is correct! Future builds will email you automatically.

**If email doesn't arrive:**
1. Check spam/junk folder
2. Go to Actions tab → Click latest workflow → Check "Send APK via Email" step
3. Look for error messages in the logs
4. Verify all 3 secrets are set correctly

---

## ⚠️ Common Mistakes

❌ **Using regular Gmail password** → Must use app password  
❌ **App password has spaces** → Remove all spaces  
❌ **Secret names have typos** → Must be exact: `EMAIL_USERNAME`, `EMAIL_PASSWORD`, `EMAIL_TO`  
❌ **Wrong branch** → Email only sends on `master` branch pushes  
❌ **2-Step Verification not enabled** → Required for app passwords  

---

## 🔍 Verify Setup Checklist

- [ ] 2-Step Verification enabled on Google Account
- [ ] App password created (16 characters, no spaces)
- [ ] `EMAIL_USERNAME` secret added (your Gmail address)
- [ ] `EMAIL_PASSWORD` secret added (app password, no spaces)
- [ ] `EMAIL_TO` secret added (email to receive builds)
- [ ] Tested with manual workflow trigger
- [ ] Checked spam folder

---

**Need more help?** See `EMAIL_TROUBLESHOOTING.md` for detailed troubleshooting.
