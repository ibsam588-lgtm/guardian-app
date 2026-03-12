# GuardIan — Parental Monitoring App
### Flutter Codebase · Parent App + Child App Architecture

---

## 📁 Project Structure

```
guardian_app/
├── lib/
│   ├── main.dart                         # Entry point + GoRouter
│   ├── theme/
│   │   └── app_theme.dart                # Colors, typography, component styles
│   ├── models/
│   │   └── models.dart                   # ChildProfile, ParentAccount, GeoFence, AppUsage, Alert
│   ├── services/
│   │   ├── auth_service.dart             # Firebase Auth + Google SSO
│   │   ├── child_service.dart            # Firestore CRUD, pairing, commands
│   │   └── subscription_service.dart     # RevenueCat $2.99/mo + 7-day trial
│   └── screens/
│       ├── auth/
│       │   ├── login_screen.dart         # Email + Google Sign-In
│       │   └── signup_screen.dart        # Registration + trial banner
│       ├── onboarding/
│       │   └── onboarding_screens.dart   # Child setup + pairing code + paywall
│       ├── home/
│       │   └── home_screen.dart          # Dashboard, map preview, quick actions
│       ├── activity/
│       │   └── activity_screen.dart      # Bar chart, app usage, time limits, sites
│       └── emergency/
│           └── emergency_screen.dart     # SOS, contacts, siren, listen live
├── pubspec.yaml
└── README.md
```

---

## 🚀 Setup Instructions

### 1. Prerequisites
```bash
flutter --version     # Requires Flutter 3.19+
java --version        # Requires Java 17+ for Android
```

### 2. Create Flutter project shell
```bash
flutter create --org com.yourcompany guardian_app
# Then replace the lib/ folder with this codebase
```

### 3. Firebase Setup
1. Go to https://console.firebase.google.com
2. Create project: **GuardIan**
3. Enable: **Authentication**, **Firestore**, **Cloud Messaging**
4. Add Android app → download `google-services.json` → place in `android/app/`
5. Add iOS app → download `GoogleService-Info.plist` → place in `ios/Runner/`

**Enable Auth providers in Firebase Console:**
- Email/Password ✓
- Google Sign-In ✓

### 4. Google Sign-In (Android)
```bash
# Get your SHA-1 fingerprint
cd android
./gradlew signingReport
# Add the SHA-1 to Firebase Console → Project Settings → Android app
```

### 5. RevenueCat (Subscriptions)
1. Create account at https://www.revenuecat.com
2. Create product in Google Play Console:
   - Product ID: `guardian_monthly_299`
   - Price: **$2.99/month**
   - Free trial: **7 days**
3. In RevenueCat dashboard:
   - Create Entitlement: `guardian_pro`
   - Create Offering with the monthly product
4. Add your API keys to `main.dart`:
```dart
await SubscriptionService.init(
  revenueCatApiKeyAndroid: 'YOUR_ANDROID_KEY',
  revenueCatApiKeyIos: 'YOUR_IOS_KEY',
);
```

### 6. Google Maps
```bash
# Add API key to android/app/src/main/AndroidManifest.xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_MAPS_API_KEY"/>
```

### 7. Install dependencies & run
```bash
flutter pub get
flutter run
```

---

## 👶 Child App Architecture

The **GuardIan Child App** is a **separate Flutter app** installed on the child's device.
It runs silently in the background and reports to the parent app via Firebase.

### How Child Pairing Works

```
Parent App                    Firebase               Child App
─────────────────────────────────────────────────────────────
1. Parent enters child name
   + age
2. Generates 6-digit code ──► Stores in               
   (valid 15 min)              pairing_codes/{code}
                               { parentUid, childName,
                                 childAge, expiresAt }

3. Parent shows code 
   to child / types it
   on child's phone

4.                                                ◄── Child enters code
5.                            Reads pairing doc  
6.                            Creates child doc  ◄── Device ID registered
                              in children/{id}
                              { parentUid, deviceId,
                                name, age, ... }

7. Parent app detects ◄──── pairing_codes/{code}
   pairing complete           .used = true
   → navigates to dashboard
```

### Child App: Required Permissions

| Permission | Platform | Purpose |
|---|---|---|
| `ACCESS_FINE_LOCATION` | Android | GPS tracking |
| `FOREGROUND_SERVICE` | Android | Background location |
| `READ_CALL_LOG` | Android | Call monitoring |
| `READ_SMS` | Android | Message monitoring |
| `USAGE_STATS` | Android | App usage (via AppOps) |
| `RECORD_AUDIO` | Android/iOS | Listen feature |
| `BIND_ACCESSIBILITY_SERVICE` | Android | Web monitoring |
| `SYSTEM_ALERT_WINDOW` | Android | App lock overlay |
| `NSLocationAlwaysUsageDescription` | iOS | Background GPS |
| `NSMicrophoneUsageDescription` | iOS | Listen feature |

### Child App: Firebase Commands (Remote Triggers)

The parent app sends commands to Firestore which the child app listens for:

```dart
// Firestore: child_commands/{autoId}
{
  "childId": "child123",
  "type": "siren",          // siren | listen_start | listen_stop | lock_app | unlock_app
  "timestamp": <serverTime>,
  "executed": false
}
```

The child app uses a `FirebaseMessaging` + Firestore listener to execute commands instantly.

### Child App: Data Reporting to Firebase

```
children/{childId}/
  ├── (document)           # name, age, isOnline, lastLocation, batteryLevel
  ├── app_usage/           # {appName, packageName, minutesUsed, dailyLimitMinutes}
  ├── app_limits/          # {packageName → limitMinutes}
  ├── geo_fences/          # {name, lat, lng, radiusMeters, isActive}
  ├── call_log/            # {contact, direction, duration, timestamp}
  ├── messages/            # {contact, preview, flagged, timestamp}
  └── web_history/         # {domain, visits, isSafe, timestamp}
```

---

## 💳 Subscription: $2.99/month

### Trial Period: 7 Days
- Account created → Firestore records `trialStartedAt` + `trialEndsAt`
- Full access to all features during trial
- No credit card required to start trial
- RevenueCat prompts for payment at end of trial

### What Happens After Trial Expires
1. User sees paywall screen (SubscriptionScreen)
2. Features are locked until subscription active
3. RevenueCat webhook → Firebase Function → update `subscription: 'expired'`

### Pricing Breakdown
| Plan | Price | Billing |
|---|---|---|
| Free Trial | $0 | 7 days |
| GuardIan Pro | $2.99 | Monthly |
| Annual (future) | ~$24.99 | Yearly (save 30%) |

### Firebase Function for Webhook (deploy separately)
```javascript
// functions/index.js
exports.revenuecatWebhook = functions.https.onRequest(async (req, res) => {
  const event = req.body;
  const uid = event.app_user_id;
  const type = event.type; // INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION
  
  let status = 'active';
  if (type === 'CANCELLATION') status = 'cancelled';
  if (type === 'EXPIRATION') status = 'expired';
  
  await admin.firestore().collection('parents').doc(uid).update({
    subscription: status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  res.status(200).send('ok');
});
```

---

## 🛡️ Security Rules (Firestore)

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Parents can only read/write their own account
    match /parents/{uid} {
      allow read, write: if request.auth.uid == uid;
    }

    // Parents can only access their children
    match /children/{childId} {
      allow read, write: if request.auth.uid == resource.data.parentUid;
      
      match /{subcollection}/{doc} {
        allow read, write: if request.auth.uid == 
          get(/databases/$(database)/documents/children/$(childId)).data.parentUid;
      }
    }

    // Pairing codes — child app can claim (write 'used')
    match /pairing_codes/{code} {
      allow read: if true; // Child app reads before auth
      allow write: if request.auth != null;
    }
  }
}
```

---

## 📱 Building for Google Play Store

```bash
# Generate release AAB
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

Upload to Google Play Console → Production track.

---

## 🔑 Environment Variables Checklist

Before releasing, confirm you have:
- [ ] `google-services.json` (Android Firebase config)
- [ ] `GoogleService-Info.plist` (iOS Firebase config)
- [ ] Google Maps API key (Android manifest)
- [ ] RevenueCat Android API key
- [ ] RevenueCat iOS API key
- [ ] SHA-1 fingerprint added to Firebase
- [ ] `guardian_monthly_299` product in Play Console
- [ ] Firestore security rules deployed
- [ ] Firebase Functions deployed (webhook)
