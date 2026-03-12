@echo off
:: ============================================================
::  GuardIan - Firebase Setup Script
::  Run this on YOUR machine after cloning the repo
::  Prerequisites: Node.js + Firebase CLI installed
::  firebase login:ci already done (you have the token)
:: ============================================================

setlocal enabledelayedexpansion

echo.
echo ====================================================
echo   GuardIan Firebase Setup
echo ====================================================
echo.

:: ── Set your Firebase token ──────────────────
set FIREBASE_TOKEN=PASTE_YOUR_FIREBASE_TOKEN_HERE

set PROJECT_ID=guardian-app-ibsam
set PROJECT_DISPLAY=GuardIan

echo [1/6] Creating Firebase project...
firebase projects:create %PROJECT_ID% --display-name "%PROJECT_DISPLAY%" --token "%FIREBASE_TOKEN%"
if errorlevel 1 (
  echo Project may already exist, continuing...
)

echo.
echo [2/6] Setting default project...
firebase use %PROJECT_ID% --token "%FIREBASE_TOKEN%"

echo.
echo [3/6] Enabling Firestore (Native mode)...
firebase firestore:databases:create --location=us-central --token "%FIREBASE_TOKEN%"

echo.
echo [4/6] Deploying Firestore security rules + indexes...
firebase deploy --only firestore --token "%FIREBASE_TOKEN%" --project %PROJECT_ID%

echo.
echo [5/6] Installing Cloud Function dependencies...
cd firebase\functions
npm install
cd ..\..

echo.
echo [6/6] Deploying Cloud Functions...
firebase deploy --only functions --token "%FIREBASE_TOKEN%" --project %PROJECT_ID%

echo.
echo ====================================================
echo   DONE! Firebase backend is live.
echo ====================================================
echo.
echo Next manual steps (must be done in Firebase Console):
echo.
echo 1. Enable Authentication providers:
echo    https://console.firebase.google.com/project/%PROJECT_ID%/authentication/providers
echo    - Enable: Email/Password
echo    - Enable: Google (set support email)
echo.
echo 2. Download google-services.json (Android):
echo    https://console.firebase.google.com/project/%PROJECT_ID%/settings/general/android
echo    - Add Android app: com.guardian.app
echo    - Download google-services.json
echo    - Place at: android/app/google-services.json
echo.
echo 3. Download GoogleService-Info.plist (iOS - when ready):
echo    Same page, add iOS app: com.guardian.app
echo.
echo 4. Set RevenueCat webhook URL in RevenueCat dashboard:
echo    https://app.revenuecat.com ^> your app ^> Integrations ^> Webhooks
echo    URL: https://us-central1-%PROJECT_ID%.cloudfunctions.net/revenuecatWebhook
echo.
echo 5. Add GitHub Secrets for CI/CD auto-deploy:
echo    https://github.com/ibsam588-lgtm/guardian-app/settings/secrets/actions
echo    - GOOGLE_SERVICES_JSON  ^(paste contents of google-services.json^)
echo    - FIREBASE_TOKEN        ^(your token above^)
echo    - PLAY_STORE_SERVICE_ACCOUNT_JSON ^(from Play Console^)
echo    - KEYSTORE_BASE64       ^(run: certutil -encodehex guardian.keystore out.b64 1^)
echo    - KEY_ALIAS             guardian
echo    - KEY_PASSWORD          ^(your keystore password^)
echo    - STORE_PASSWORD        ^(your keystore password^)
echo.
pause
