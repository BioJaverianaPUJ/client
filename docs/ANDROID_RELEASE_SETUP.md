# Android Release Build Setup Guide

This guide walks you through setting up everything needed for automated release APK builds on GitHub Actions.

---

## Table of Contents
1. [Generate a Keystore](#1-generate-a-keystore)
2. [Upload Secrets to GitHub](#2-upload-secrets-to-github)
3. [Verify the Workflow](#3-verify-the-workflow)
4. [How the Workflow Works](#4-how-the-workflow-works)
5. [Troubleshooting](#5-troubleshooting)

---

## 1. Generate a Keystore

You need a **keystore file** to sign your APK. Follow these steps:

### Step 1.1: Run the keytool command

Open **PowerShell** or **Command Prompt** and run:

```powershell
keytool -genkey -v -keystore %USERPROFILE%\release.keystore -alias biojaveriana -keyalg RSA -keysize 2048 -validity 10000
```

You will be prompted for:
- **Keystore password** (remember this!)
- **First/Last name** (your name or "biojaveriana")
- **Organization unit** (e.g., "Development")
- **Organization** (e.g., "Pontificia Universidad Javeriana")
- **City** (e.g., "Palmira")
- **State** (e.g., "Valle del Cauca")
- **Country code** (e.g., "CO")

### Step 1.2: Copy the keystore to your project


---

## 2. Upload Secrets to GitHub

You need to add 4 secrets to your GitHub repository.

### Step 2.1: Get the Base64-encoded keystore

Run this in PowerShell:

```powershell
$keystorePath = "c:\Users\zackd\Documents\bio-javeriana\client\android\app\release.keystore"
$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($keystorePath))
$base64 | Set-Clipboard
Write-Host "Keystore is now in your clipboard!" -ForegroundColor Green
Write-Host "Paste it as the ANDROID_KEYSTORE_BASE64 secret below." -ForegroundColor Yellow
```

### Step 2.2: Add secrets to your GitHub repo

1. Go to your repository on GitHub: `https://github.com/YOUR_USERNAME/bio-javeriana`
2. Click **Settings** (top right)
3. Click **Secrets and variables** -> **Actions** (left sidebar)
4. Click **New repository secret** for each of the following:

| Secret Name | Value | Description |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | Paste the Base64 string from your clipboard | The entire keystore file encoded as Base64 |
| `ANDROID_KEYSTORE_PASSWORD` | The keystore password you set | Password for the keystore file |
| `ANDROID_KEY_ALIAS` | `biojaveriana` (or whatever alias you chose) | The key alias name |
| `ANDROID_KEY_PASSWORD` | The key password you set | Password for the specific key inside the keystore |

> **Note:** `ANDROID_KEYSTORE_PASSWORD` and `ANDROID_KEY_PASSWORD` can be the same if you used the same password for both.


---

## 3. Verify the Workflow

### Step 3.1: Commit and push

```powershell
git add .
git commit -m "chore: add Android release build workflow"
git push origin main
```

### Step 3.2: Check the Actions tab

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. You should see a workflow run called **"Android Release Build"**
4. Wait for it to complete (usually 3-5 minutes)
5. If successful, you will see the APK as an artifact

### Step 3.3: Trigger a Release via Tag

To create a GitHub Release, push a tag:

```powershell
git tag v1.0.5
git push origin v1.0.5
```

This will:
- Build the release APK
- Create a **GitHub Release** with the APK attached
- Generate release notes automatically

---

## 4. How the Workflow Works

The workflow (`.github/workflows/android-release.yml`) triggers in two scenarios:

| Trigger | Behavior |
|---|---|
| **Push to `main`** | Builds the APK and uploads it as a temporary artifact (30-day retention) |
| **Push a tag** (e.g., `v1.0.5`) | Builds the APK and creates a **GitHub Release** with the APK attached |

### Build process:
1. **Checkout** the repository
2. **Setup Java 17** (required for Android build)
3. **Setup Flutter** (stable channel)
4. **Decode keystore** from the `ANDROID_KEYSTORE_BASE64` secret
5. **Read version** from `pubspec.yaml`
6. **Determine build version** based on trigger type
7. **Build release APK** with `flutter build apk --release`
8. **Create GitHub Release** (only for tags) or **upload artifact** (only for main branch)

---

## 5. Troubleshooting

### Build fails with "signing config not found"
- Verify all 4 secrets are correctly set in GitHub
- Check the keystore password and key alias match what you used when generating the keystore

### Build fails with "keystore not found"
- Ensure the Base64 encoding was done correctly (use the PowerShell command above)
- Check that the secret name is exactly `ANDROID_KEYSTORE_BASE64` (case-sensitive)

### APK does not install on device
- Make sure you uninstall any debug version first: `adb uninstall com.example.biolens`
- The release APK uses a different signature than debug

### Workflow does not trigger on push
- Ensure your branch protection rules allow workflow runs
- Check the GitHub Actions logs for any errors

### Need to rebuild a release
- Delete the existing tag and release, then recreate:
  ```powershell
  git tag -d v1.0.5
  git push origin :refs/tags/v1.0.5
  git tag v1.0.5
  git push origin v1.0.5
  ```

---

## Quick Reference

### Commands you will use:

```powershell
# Generate keystore (one-time setup)
keytool -genkey -v -keystore %USERPROFILE%\release.keystore -alias biojaveriana -keyalg RSA -keysize 2048 -validity 10000

# Encode keystore for GitHub secret
$keystorePath = "c:\Users\zackd\Documents\bio-javeriana\client\android\app\release.keystore"
[Convert]::ToBase64String([IO.File]::ReadAllBytes($keystorePath)) | Set-Clipboard

# Create a new release
git tag v1.0.5
git push origin v1.0.5

# Build locally for testing (requires key.properties)
flutter build apk --release
```

### Important files created:
- `.github/workflows/android-release.yml` - CI/CD workflow
- `android/app/key.properties` - Keystore config (gitignored)
- `android/app/release.keystore` - Keystore file (gitignored)
### Example of the secrets page:

```
+-----------------------------+------------------------------------------+
| Secret Name                 | Value                                    |
+-----------------------------+------------------------------------------+
| ANDROID_KEYSTORE_BASE64     | MII...[long base64 string]...==         |
| ANDROID_KEYSTORE_PASSWORD   | mySecurePassword123!                     |
| ANDROID_KEY_ALIAS           | biojaveriana                             |
| ANDROID_KEY_PASSWORD        | mySecurePassword123!                     |
+-----------------------------+------------------------------------------+
```

```powershell
copy %USERPROFILE%\release.keystore c:\Users\zackd\Documents\bio-javeriana\client\android\app\release.keystore
```

### Step 1.3: Update `key.properties`

Open `android/app/key.properties` and fill in the values you used:

```properties
storeFile=release.keystore
storePassword=YOUR_KEYSTORE_PASSWORD_HERE
keyAlias=biojaveriana
keyPassword=YOUR_KEY_PASSWORD_HERE
```

> **Important:** The `key.properties` file and `release.keystore` are already in `.gitignore`. Do NOT commit them.

