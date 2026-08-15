<div align="center">

# 🕌 FAIZAN-E-DUROOD (فیضانِ درود و سلام)
### Modern Islamic Salawat Tracker, Knowledge Hub & Community Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/Hassan-Developer-cmd/FAIZAN-E-DUROOD/actions)
[![Hosting](https://img.shields.io/badge/Live%20Web-Firebase%20Hosting-00B0FF?style=for-the-badge&logo=google-cloud&logoColor=white)](https://islamic-app-ed1ed.web.app)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

<br/>

**[🌐 Live Web Application & Admin Portal](https://islamic-app-ed1ed.web.app)** • **[📦 GitHub Repository](https://github.com/Hassan-Developer-cmd/FAIZAN-E-DUROOD.git)**

---

</div>

## 📖 Overview

**FAIZAN-E-DUROOD** is a full-featured, cross-platform Islamic application designed to encourage daily recitations of Salawat upon Prophet Muhammad (ﷺ), preserve sacred knowledge through authentic Fiqh Masail and Islamic Aqaid (Beliefs), and connect the community through upcoming Islamic events.

Built with **Flutter** and **Firebase Cloud Firestore**, the platform features a mobile client experience alongside a dedicated **Web Admin Management Dashboard** with automated CI/CD deployment to **Firebase Hosting**.

---

## ✨ Key Features

### 1. 📿 Global & Personal Durood Counter
- **Real-Time Aggregation**: Live synchronization of global recitations alongside personal lifetime and daily tallies via Firestore listeners.
- **Goal Milestones & Streaks**: Set daily recitation goals (100, 300, 500, 1000, 5000) with visual progress bars and daily recitation streak trackers.
- **Quick Bulk Recitations**: Increment counters via fast chip selections (`+10`, `+50`, `+100`, `+500`) with custom confirmation dialogs.
- **Haptic & Sensory Feedback**: Tactile feedback on taps with optimistic UI state updates for latency-free counting.

### 2. 📚 Fiqh Masail & Aqaid Knowledge Hub
- **Logical Category Grouping**:
  - *Masail Categories*: Namaz, Wuzu, Tayamum, Roza, Zakat, Hajj, Nikah, Taharat, Miras.
  - *Aqaid Categories*: Tawheed, Risalat, Ahle Sunnat, Quranic fundamentals, Wilayat.
- **Authentic Book References**: Every ruling and belief is cited with classical sources (*Bahar-e-Shariat*, *Fatawa Ridawiyyah*, *Fatawa Alamgiri*, *Sahih al-Bukhari*, *Sahih Muslim*).
- **Interactive Search**: Real-time filtering across English and Urdu titles, explanations, and Arabic script.

### 3. 🌟 Daily Hadith & Ayat with "Topic of the Day"
- **Accumulative History Archive**: New daily entries are saved as distinct Firestore documents without overwriting or hiding past wisdom.
- **Topic of the Day Flag**: Dedicated highlight system allowing admins to activate a featured "Topic of the Day" displayed prominently at the top of the mobile home screen.
- **Historical Archive Viewer**: In-app bottom sheet archive displaying all historical Hadith & Ayat in reverse chronological order.

### 4. 📅 Event Management & Push Announcements
- **Dynamic Status Lifecycle**: Events feature statuses (`Coming Soon`, `Featured`, `Ongoing`, `Completed`, `Cancelled`) with distinct color badges.
- **Deduplicated Notification Pipeline**: Automated in-app notification triggers and topic broadcasts when events are created or statuses change.
- **Smooth Non-Nested Scrolling**: Optimized `BouncingScrollPhysics` for event cards across all screen resolutions.

### 5. 💻 Web Admin Dashboard & Management Portal
- **Dashboard Metrics**: Real-time KPI summary cards (Total Users, Global Durood, Today's Durood, Active Events).
- **Users Leaderboard**: Complete leaderboard ranked by streaks, displaying User Name, Email, Current Streak, **Total Durood** (lifetime recitations), and Total Points.
- **Content CRUD**: Comprehensive management tabs for Events, Masail, Aqaid, Daily Content, and Push Notifications.
- **Authorized Notification Deletion**: Admins can safely delete notifications directly from the web portal with confirmation safeguards.
- **Auto-Clearing Search & Filters**: Search controllers and category filters auto-reset on tab switches for a clean administrative workflow.

### 6. 🌐 Universal Bilingual Localization & Persistent Auth
- **English & Urdu (اردو)**: Dynamic text and layout direction (LTR / RTL) switching on the fly.
- **Relocated Header Toggle**: Main Masail, Aqaid, Counter, and Splash screens feature clean top-level AppBar language toggles.
- **Persistent Preferences**: Language preference and user authentication sessions persist across app restarts via `SharedPreferences` and `FirebaseAuth`.

---

## 🛠️ Architecture & Tech Stack

```mermaid
graph TD
    Client[📱 Flutter Mobile / Web Client] --> Providers[⚡ LanguageProvider & State Services]
    Providers --> CoreServices[🛠️ AuthService | CounterService | ContentService | AdminService]
    CoreServices --> Firebase[(🔥 Firebase Cloud Firestore & Auth)]
    GitPush[💻 Git Push origin main] --> GHActions[⚙️ GitHub Actions CI/CD]
    GHActions --> BuildWeb[📦 Flutter Web Release Build]
    BuildWeb --> Hosting[🌐 Firebase Hosting - islamic-app-ed1ed.web.app]
```

| Layer | Technology / Package | Purpose |
|---|---|---|
| **Framework** | Flutter 3.x (Dart 3.x) | Cross-platform UI development for Android, iOS, and Web |
| **Backend & Auth** | Firebase Cloud Firestore & Firebase Auth | Real-time database, cloud synchronization, and user authentication |
| **State Management** | `ChangeNotifier` / `ListenableBuilder` / `StreamBuilder` | Reactive, lightweight, and performant state updates |
| **Localization** | Custom `LanguageProvider` + `AppTranslations` | Instant English/Urdu bilingual toggle with RTL/LTR layout handling |
| **CI / CD Pipeline** | GitHub Actions (`firebase-hosting-merge.yml`) | Automated build and deployment to Google Firebase Hosting |
| **Styling & Theme** | Custom `AppColors` & `AppTypography` | Islamic emerald (`#0F5132`) and gold (`#D4AF37`) design system |

---

## 📁 Repository Directory Structure

```text
islamic_app/
├── .github/
│   └── workflows/
│       ├── firebase-hosting-merge.yml        # CI/CD auto-deploy on push to main
│       └── firebase-hosting-pull-request.yml  # Preview channel deployment
├── android/                                  # Android native project configuration
├── ios/                                      # iOS native project configuration
├── web/                                      # Web entry point & cache-invalidation configuration
│   ├── index.html                            # Custom HTML with service worker cache-buster
│   ├── manifest.json                         # Progressive Web App manifest
│   └── favicon.png                           # Web application favicon
├── lib/
│   ├── main.dart                             # App bootstrap, auth gates & universal localization
│   ├── firebase_options.dart                 # Multi-platform Firebase configuration
│   ├── core/
│   │   ├── constants/                        # AppColors, AppTheme, AppTypography
│   │   ├── dummy_data/                       # Fallback datasets (mock_masail, mock_aqaid)
│   │   ├── localization/                     # English & Urdu translation dictionaries
│   │   ├── models/                           # AppUser, MasailModel, AqaidModel, EventModel, DailyContentModel
│   │   ├── providers/                        # LanguageProvider (persistent locale & RTL handling)
│   │   └── utils/                            # Firestore seeder utility
│   ├── features/
│   │   ├── admin_panel/                      # Web Admin Portal (dashboard, tables, modals)
│   │   ├── auth/                             # LoginScreen with Google Sign-In & Email/Password
│   │   ├── counter/                          # CounterScreen, StatCard, CounterButton, Goal Tracker
│   │   ├── events/                           # UpcomingEventsScreen & DetailedEventCards
│   │   ├── home/                             # HomeScreen, HadithWisdomCard, EventBanners
│   │   ├── knowledge_hub/                    # MasailGridScreen, AqaidGridScreen & detail views
│   │   ├── profile/                          # User profile, statistics & sign out
│   │   └── splash/                           # Animated branding splash screen
│   └── services/                             # AuthService, CounterService, ContentService, AdminService
├── firebase.json                             # Firebase Hosting rules & cache-control headers
├── firestore.rules                           # Cloud Firestore security rules
├── pubspec.yaml                              # Dependencies and asset declarations
└── README.md                                 # Project documentation
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.22.0`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.4.0`)
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- Android Studio / VS Code with Flutter & Dart extensions

### 1. Clone the Repository
```bash
git clone https://github.com/Hassan-Developer-cmd/FAIZAN-E-DUROOD.git
cd FAIZAN-E-DUROOD
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Firebase
Ensure your Firebase project is registered and run:
```bash
flutterfire configure
```

### 4. Run the Application

#### Mobile (Android / iOS / Simulator):
```bash
flutter run
```

#### Web Admin Dashboard (Chrome):
```bash
flutter run -d chrome
```

---

## 🚢 CI/CD & Firebase Hosting Deployment

The repository includes an automated GitHub Actions workflow configured in `.github/workflows/firebase-hosting-merge.yml`.

### Automated Deployment:
Whenever code is pushed to the `main` branch:
1. GitHub Actions checks out the code and sets up Flutter.
2. Dependencies are resolved via `flutter pub get`.
3. The release web bundle is built using `flutter build web --release`.
4. The build artifacts are deployed live to **Firebase Hosting**.

### Manual Web Deployment:
To deploy directly from your local terminal:
```bash
# Build optimized release bundle
flutter build web --release --no-wasm-dry-run

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

---

## 🔒 Security & Firestore Rules

Production Firestore security rules are configured in [firestore.rules](file:///c:/Islamic%20App/islamic_app/firestore.rules):
- **User Records**: Authenticated users have read and write access to their own user profile document.
- **Global Counters**: Authenticated users can increment global recitations with rate limiting.
- **Knowledge Base & Events**: Publicly readable by all users; write access is strictly restricted to verified Admins (`is_admin == true`).

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the Project (`https://github.com/Hassan-Developer-cmd/FAIZAN-E-DUROOD/fork`)
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m "feat: add AmazingFeature"`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Developed with ❤️ for the Ummah**  
*May Allah (ﷻ) bless all reciters with peace and infinite blessings.*

</div>
