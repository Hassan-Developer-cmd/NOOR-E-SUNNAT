# Faizan e Durood (فیضانِ درود و سلام) - Modern Islamic Salawat & Knowledge App

A high-performance, cross-platform Flutter application designed to facilitate daily Salawat (Durood Sharif) recitations, track personal and global recitation milestones, explore authentic Fiqh Masail and Aqaid, and engage the community with upcoming Islamic events.

---

## 🌟 Key Features Implemented

- **⚡ Live Dual Durood Counter**:
  - **Global & Personal Count**: Real-time counter synced with Firebase Cloud Firestore.
  - **Tap Debouncing & Optimistic UI**: Latency-free tapping with background synchronization.
  - **Target Goal Tracker**: Custom daily targets (100, 300, 500, 1000, 5000) with dynamic completion progress bar.
  - **Haptic Feedback**: Optional haptic vibration feedback toggle on every recitation tap.

- **📜 Authentic Knowledge Hub (Masail & Aqaid)**:
  - **Fiqh Masail Categories**: Detailed Q&A items across *Namaz, Wuzu, Tayamum, Roza, Zakat, Hajj, Nikah, Taharat, Miras* with citations from *Bahar-e-Shariat*, *Fatawa Ridawiyyah*, and *Fatawa Alamgiri*.
  - **Aqaid Belief Categories**: Core tenets (*Tawheed, Risalat, Sahaba o Ahlebait, Ishq-e-Rasool, Wilayat*) enriched with Quranic verses and Hadith references.
  - **Dynamic Card Counts**: Subtitle badges on category cards dynamically mirror the exact number of available topics.

- **✨ High-End Islamic UI/UX & Branded Splash**:
  - **Animated Splash Screen**: Deep emerald gradient (`#0A3A2A`), gold Islamic crescent emblem (`#D4AF37`), and smooth scale/fade animation.
  - **Glassmorphism Theme**: Crisp card drop shadows, 16–20px border radii, and high-contrast typography.
  - **Hadith of the Day with One-Tap Share**: Daily quotes with a single tap "Copy & Share to WhatsApp/Socials" action.

- **🌐 Bilingual & RTL Support**:
  - Full English and Urdu (**اردو**) localization with instant locale switching and dynamic RTL text direction.

- **💻 Web Admin Management Portal**:
  - Web dashboard (`admin_dashboard_web.dart`) to manage events, Masail entries, Aqaid entries, Daily Hadith, Push Notifications, User Roles, and a one-click **"Seed Default Content to Firestore"** utility.

---

## 🛠️ Architecture & Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart 3.x) |
| **State Management** | ChangeNotifier / ListenableBuilder & StreamBuilder |
| **Backend / Database** | Firebase Cloud Firestore |
| **Authentication** | Firebase Auth (Google Sign-In & Email/Password) |
| **Localization** | Custom `LanguageProvider` + `GlobalMaterialLocalizations` |
| **Design Tokens** | Custom `AppColors` (Emerald & Gold) & `AppTypography` |

---

## 📁 Repository Folder Structure

```text
islamic_app/
├── lib/
│   ├── main.dart                      # App entry point, Localization & Auth Gate
│   ├── firebase_options.dart          # Firebase configuration settings
│   ├── core/
│   │   ├── constants/                 # AppColors, AppTheme, AppTypography
│   │   ├── dummy_data/                # MockMasailData & MockAqaidData fallbacks
│   │   ├── localization/              # English & Urdu translation strings
│   │   ├── models/                    # MasailModel, AqaidModel, EventModel, DailyContentModel, AppUser
│   │   ├── providers/                 # LanguageProvider (EN/UR state & RTL)
│   │   └── utils/                     # FirestoreSeeder utility script
│   ├── features/
│   │   ├── admin_panel/               # Web Admin Portal & Admin Login
│   │   ├── auth/                      # LoginScreen with official Google Sign-In button
│   │   ├── counter/                   # CounterScreen, StatCard, CounterButton, Goal Tracker
│   │   ├── home/                      # HomeScreen, HadithWisdomCard, EventCards
│   │   ├── knowledge_hub/             # MasailGridScreen, AqaidGridScreen & detail views
│   │   ├── profile/                   # ProfileScreen & Sign Out flow
│   │   └── splash/                    # Animated SplashScreen
│   └── services/                      # AuthService, CounterService, ContentService, AdminService
├── pubspec.yaml                       # Dependencies & assets configuration
└── README.md                          # Comprehensive Developer Guide
```

---

## 🚀 Setup & Execution Guide

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.12.0`)
- Android Studio / VS Code with Flutter extension
- Firebase Project configured for Android/Web

### 1. Installation
```bash
# Clone the repository
cd islamic_app

# Install project dependencies
flutter pub get
```

### 2. Running Locally (Mobile App)
```bash
# Run on connected Android device / emulator
flutter run
```

### 3. Running Locally (Web Admin Portal)
```bash
# Run Web Admin Portal on Chrome
flutter run -d chrome
```

### 4. Database Seeding
To populate Cloud Firestore with all default textual content (Masail, Aqaid, Daily Hadith, Events):
1. Open the Web Admin Portal (`AdminDashboardWeb`).
2. Log in with Admin Credentials.
3. Click **"Seed Default Content to Firestore"** in the top action bar.

---

## 🗄️ Firestore Database Schema

### `users` (Collection)
```json
{
  "user_id": "String (uid)",
  "email": "String",
  "username": "String",
  "photo_url": "String",
  "personal_total_durood": 0,
  "personal_today_durood": 0,
  "current_streak": 1,
  "last_counter_date": "Timestamp",
  "durood_points": 0,
  "is_admin": false,
  "created_at": "Timestamp"
}
```

### `global_counter/main` (Document)
```json
{
  "total_count": 15420,
  "today_count": 340,
  "last_updated": "Timestamp"
}
```

### `masail_entries` (Collection)
```json
{
  "category_id": "namaz | wuzu | roza | zakat | hajj | tayamum | nikah | taharat | miras",
  "question": "String",
  "question_ur": "String (Urdu)",
  "answer": "String",
  "answer_ur": "String (Urdu)",
  "citation": "String",
  "citation_ur": "String",
  "reference_book": "Bahar-e-Shariat",
  "reference_book_ur": "بہارِ شریعت"
}
```

### `aqaid_entries` (Collection)
```json
{
  "category_id": "tawheed | risalat | sahaba_ahlebait | ishq_rasool | wilayat",
  "title": "String",
  "title_ur": "String (Urdu)",
  "arabic_text": "String",
  "explanation": "String",
  "explanation_ur": "String (Urdu)",
  "reference": "String",
  "reference_ur": "String"
}
```

### `events` (Collection)
```json
{
  "title": "String",
  "title_ur": "String (Urdu)",
  "date_time": "String",
  "location": "String",
  "location_ur": "String (Urdu)",
  "status": "Upcoming | Featured | Recurring",
  "description": "String",
  "description_ur": "String (Urdu)"
}
```

---

## 📦 Building Production Release

### Android APK
```bash
flutter clean
flutter pub get
flutter build apk --release
```
**Output Location:** `build/app/outputs/flutter-apk/app-release.apk`

---

## 🚀 CI/CD & Automated Deployment (GitHub Actions + Firebase Hosting)

This project is configured with a fully automated CI/CD pipeline via GitHub Actions.

### 🌐 Live Production URL
- **Firebase Hosting App:** [https://islamic-app-ed1ed.web.app](https://islamic-app-ed1ed.web.app)
- **Firebase Console:** [https://console.firebase.google.com/project/islamic-app-ed1ed/hosting](https://console.firebase.google.com/project/islamic-app-ed1ed/hosting)

### 🔄 How Automated Deployment Works
1. Any `git push` to `main` (or `master`) triggers `.github/workflows/firebase-hosting-merge.yml`.
2. The GitHub runner sets up Java 17 and Flutter SDK, runs `flutter pub get`, builds the optimized web app (`flutter build web --release`), and deploys directly to Firebase Hosting live channel.
3. Pull requests automatically spin up a **Preview URL** channel for QA and code reviews (`.github/workflows/firebase-hosting-pull-request.yml`).

---

## 📄 License
This project is proprietary and intended for Islamic educational purposes.
