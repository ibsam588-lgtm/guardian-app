# Contributing to GuardIan

## Branch Strategy

```
main          ← production releases only
develop       ← integration branch
feature/*     ← new features (branch from develop)
fix/*         ← bug fixes
hotfix/*      ← urgent production fixes (branch from main)
```

## Workflow

```bash
# Start a new feature
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name

# Make changes, commit often
git add .
git commit -m "feat: describe your change"

# Push and open PR against develop
git push origin feature/your-feature-name
```

## Commit Message Format

```
feat: add geo-fence breach notification
fix: resolve app limit not saving on Android 13
chore: update firebase_auth to 4.18.0
docs: add child app setup instructions
```

## GitHub Secrets to Configure

Go to: **Settings → Secrets and variables → Actions**

| Secret | What it is | How to get it |
|---|---|---|
| `GOOGLE_SERVICES_JSON` | Firebase Android config | Firebase Console → Project Settings → Android app |
| `KEYSTORE_BASE64` | Signing keystore (base64) | `base64 -i guardian.keystore` |
| `KEY_ALIAS` | Keystore alias | Set when creating keystore |
| `KEY_PASSWORD` | Key password | Set when creating keystore |
| `STORE_PASSWORD` | Store password | Set when creating keystore |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Google Play service account | Play Console → Setup → API access |
| `FIREBASE_TOKEN` | Firebase CI token | `firebase login:ci` |

## Generating an Android Keystore (first time only)

```bash
keytool -genkey -v \
  -keystore guardian.keystore \
  -alias guardian \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# Encode for GitHub secret
base64 -i guardian.keystore | pbcopy   # macOS
base64 -i guardian.keystore | xclip    # Linux
```

**Store the keystore file safely — losing it means you can never update the app on Play Store.**
