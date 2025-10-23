# VintageVoice

**Voice-Only "Vintage Letter" iOS App for Long-Distance Couples**

VintageVoice is a vintage-styled mobile messenger that lets users record voice letters, choose future delivery times (1 hour to 1 year), seal them in wax, and surprise their partner when the envelope magically appears in their mailbox at exactly the right moment.

## Features

### Core Functionality

- **Voice Letters**: Record personal audio messages for your partner
- **Time Capsules**: Schedule delivery from 1 hour to 1 year in the future
- **Hidden Until Delivery**: Recipients see nothing until the exact delivery timestamp (FR-HIDE-01)
- **Beautiful Wax Seal**: Vintage-styled envelope sealing animation
- **Auto-Purge**: Audio files automatically purge after first full playback (FR-DEL-03)
- **Optional Transcripts**: View text transcripts with 24-hour grace period

### Daily Spark Engine (FR-ENG-04)

- **Daily Prompts**: Receive creative recording prompts each day
- **Timezone Aware**: Prompts arrive during your personal active window
- **Stamp Rewards**: Earn special Spark stamps for daily engagement
- **Streak Tracking**: Build consecutive day streaks
- **Quick Record**: Tap notification → record → auto-send with 24h delay

### Stamp Collection

- **Tiered Stamps**: Bronze, Silver, Gold, Platinum, Diamond based on letter delay
- **Daily Spark Stamps**: Special limited stamps for daily prompt responses
- **Postage Points**: Earn points for gamification
- **Collection Album**: View your vintage stamp collection

### Vintage UI/UX

- **Sepia Color Palette**: Warm vintage browns, parchment, and ink colors
- **Serif Typography**: Classic Baskerville and Georgia fonts
- **Envelope Visualization**: Beautiful envelope cards with wax seals
- **Animations**: Smooth wax seal dripping and envelope opening effects

## Architecture

### Technology Stack

- **Platform**: iOS (Swift + SwiftUI)
- **Backend**: Firebase
  - Authentication (Anonymous + Email/Password)
  - Firestore (NoSQL database)
  - Storage (Audio file hosting)
  - Cloud Functions (Letter delivery, Daily Spark cron)
  - Cloud Messaging (Push notifications)

### Project Structure

```
VintageVoice/
├── Models/              # Data models
│   ├── UserProfile.swift
│   ├── Letter.swift
│   ├── Prompt.swift
│   └── DelayPreset.swift
├── Views/               # SwiftUI views
│   ├── MailboxView.swift
│   ├── ComposeLetterView.swift
│   ├── LetterDetailView.swift
│   ├── DelayPickerView.swift
│   ├── DailySparkView.swift
│   └── StampCollectionView.swift
├── Services/            # Business logic
│   ├── AuthService.swift
│   ├── LetterService.swift
│   ├── StorageService.swift
│   ├── AudioRecorder.swift
│   ├── AudioPlayer.swift
│   ├── PushNotificationService.swift
│   └── DailySparkService.swift
├── Utils/               # Helpers
│   └── VintageTheme.swift
└── VintageVoiceApp.swift
```

### Data Models

#### UserProfile
```swift
{
  id: String,
  timezone: String,
  streakCount: Int,
  collectedStamps: [String],
  lastPromptAt: Date?,
  postagePoints: Int,
  partnerID: String?,
  activeWindowStart: Int,  // Default: 19:00
  activeWindowEnd: Int     // Default: 21:00
}
```

#### Letter
```swift
{
  id: String,
  senderID: String,
  recipientID: String,
  audioURL: String,
  transcript: String?,
  createdAt: Date,
  deliverAt: Date,
  promptID: String?,       // From Daily Spark
  status: LetterStatus,    // sent | delivered | opened | purged
  playbackProgress: Double
}
```

#### Prompt
```swift
{
  id: String,
  text: String,
  defaultDelayHours: Int,
  category: PromptCategory,
  seasonTag: String?,
  expiresAt: Date?         // 24h after creation
}
```

## Setup Instructions

### Prerequisites

1. **Xcode 15.0+** (for iOS 17.0+ support)
2. **CocoaPods** or **Swift Package Manager**
3. **Firebase Project**

### Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or select existing
3. Add an iOS app with bundle ID: `com.vintagevoice.app`
4. Download `GoogleService-Info.plist`
5. Replace the placeholder file in `VintageVoice/GoogleService-Info.plist`

### Firebase Services Configuration

Enable the following services in Firebase Console:

1. **Authentication**
   - Enable Anonymous sign-in
   - Enable Email/Password (optional)

2. **Firestore Database**
   - Create database in production mode
   - Add these collections:
     - `users`
     - `letters`
     - `dailyPrompts`
     - `stamps`

3. **Storage**
   - Enable Firebase Storage
   - Create bucket for audio files

4. **Cloud Messaging**
   - Enable FCM
   - Upload APNs authentication key

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Letters visible only after deliverAt timestamp
    match /letters/{letterId} {
      allow read: if request.auth.uid == resource.data.recipientID
                  && request.time >= resource.data.deliverAt;
      allow create: if request.auth.uid == request.resource.data.senderID;
      allow update: if request.auth.uid == resource.data.recipientID;
    }

    // Anyone can read daily prompts
    match /dailyPrompts/{promptId} {
      allow read: if request.auth != null;
    }
  }
}
```

### Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /audio/{audioFile} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Swift Package Dependencies

Add these Firebase packages via Xcode:

1. Go to **File > Add Packages...**
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select packages:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseStorage`
   - `FirebaseMessaging`

### Build & Run

1. Open `VintageVoice.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Add these capabilities:
   - Push Notifications
   - Background Modes (Remote notifications)
4. Build and run on simulator or device

## Cloud Functions (Backend)

The following Cloud Functions need to be deployed for full functionality:

### 1. Letter Delivery Function
```javascript
// Scheduled to run every minute
exports.deliverLetters = functions.pubsub
  .schedule('* * * * *')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const snapshot = await admin.firestore()
      .collection('letters')
      .where('deliverAt', '<=', now)
      .where('status', '==', 'sent')
      .get();

    const batch = admin.firestore().batch();

    snapshot.docs.forEach(doc => {
      batch.update(doc.ref, { status: 'delivered' });

      // Send push notification
      sendPushNotification(doc.data().recipientID, {
        title: 'You have a new letter!',
        body: 'A voice letter just arrived in your mailbox',
        data: { type: 'letter_delivered', letterID: doc.id }
      });
    });

    await batch.commit();
  });
```

### 2. Daily Spark Cron
```javascript
// Runs at :05 past every hour
exports.dailySparkCron = functions.pubsub
  .schedule('5 * * * *')
  .onRun(async (context) => {
    const users = await admin.firestore().collection('users').get();
    const now = new Date();

    for (const userDoc of users.docs) {
      const user = userDoc.data();

      if (shouldSendPrompt(user, now)) {
        const prompt = await getOrCreateDailyPrompt();

        await sendPushNotification(user.id, {
          title: 'Daily Spark ✨',
          body: prompt.text,
          data: { type: 'daily_spark', promptID: prompt.id }
        });

        await userDoc.ref.update({
          lastPromptAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }
    }
  });
```

### 3. Award Spark Stamp Function
```javascript
exports.awardSparkStamp = functions.https.onCall(async (data, context) => {
  const { promptID } = data;
  const uid = context.auth.uid;

  const stamp = {
    id: admin.firestore().collection('stamps').doc().id,
    tier: 'spark',
    earnedAt: admin.firestore.FieldValue.serverTimestamp(),
    promptID
  };

  await admin.firestore().collection('stamps').doc(stamp.id).set(stamp);

  await admin.firestore().collection('users').doc(uid).update({
    collectedStamps: admin.firestore.FieldValue.arrayUnion(stamp.id),
    postagePoints: admin.firestore.FieldValue.increment(3),
    streakCount: admin.firestore.FieldValue.increment(1)
  });

  return { success: true, stamp };
});
```

## Functional Requirements Coverage

| ID | Requirement | Implementation |
|----|-------------|----------------|
| FR-HIDE-01 | Recipient has no envelope until deliverAt | `Letter.isVisible` checks timestamp, Firestore rules enforce |
| FR-ENV-02 | Cloud Function creates envelope & pushes APNs | `deliverLetters` Cloud Function |
| FR-DEL-03 | Auto-purge after playback | `AudioPlayer.onPlaybackComplete` triggers `purgeLetter()` |
| FR-ENG-04 | Daily Spark Engine | `DailySparkService` + `dailySparkCron` Cloud Function |

## Testing

### Local Testing

1. **Anonymous Auth**: Tap "Get Started" on welcome screen
2. **Record Letter**: Tap compose button, record, select delay, seal & send
3. **Daily Spark**: Use local notification simulation in `PushNotificationService`
4. **Playback**: Letters appear in mailbox after deliverAt time

### Firebase Emulator (Optional)

```bash
firebase emulators:start --only firestore,storage,auth
```

Update `FirebaseManager.swift` to use emulators:
```swift
#if DEBUG
db.useEmulator(withHost: "localhost", port: 8080)
storage.useEmulator(withHost: "localhost", port: 9199)
auth.useEmulator(withHost: "localhost", port: 9099)
#endif
```

## Roadmap

### MVP (Current)
- [x] Core letter recording and delivery
- [x] Wax seal animation
- [x] Daily Spark prompts
- [x] Stamp collection
- [x] Auto-purge after playback

### Future Enhancements
- [ ] Transcription with Whisper API
- [ ] Sticker decorations
- [ ] Ambience intro clips (fireplace, rain, etc.)
- [ ] Partner pairing flow
- [ ] Multiple partner support
- [ ] Letter templates
- [ ] Seasonal prompt themes
- [ ] Social sharing (selected stamps)

## Non-Functional Requirements

- **Daily Spark Push Success**: ≥ 95% within 24h
- **Push→Record Latency**: ≤ 3s median
- **Audio Quality**: AAC, 44.1kHz, high quality
- **Storage Optimization**: Auto-purge prevents storage bloat

## Support

For issues or questions:
1. Check [Firebase documentation](https://firebase.google.com/docs)
2. Review Firestore rules and indexes
3. Check Cloud Function logs in Firebase Console
4. Verify APNs certificate is valid

## License

© 2025 VintageVoice. All rights reserved.

---

**Built with ❤️ using Swift, SwiftUI, and Firebase**
