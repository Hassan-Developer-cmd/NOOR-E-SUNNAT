<div align="center">

# 🕌 NOOR E SUNNAT (نورِ سنت)
### Modern Islamic Platform, Sacred Sunnah & Fiqh Knowledge Hub, and Salawat Tracker

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

**NOOR E SUNNAT (نورِ سنت)** is a comprehensive, production-ready cross-platform Islamic application designed to illuminate the path of the Sunnah, foster abundant daily recitations of Salawat upon Prophet Muhammad (ﷺ), preserve sacred knowledge through authentic Fiqh Masail and Islamic Aqaid (Creed), and unite the community through verified Islamic events.

Engineered using **Flutter** and **Google Firebase Cloud Firestore**, **NOOR E SUNNAT** delivers a premium mobile experience across Android & iOS alongside a dedicated, real-time **Web Admin Management Portal** with automated CI/CD deployment via **Firebase Hosting**.

---

## ✨ Core Features & Modules

### 1. 📿 Global & Personal Salawat (Durood) Counter
- **Real-Time Global Aggregation**: Live synchronization of global recitations alongside personal lifetime and daily tallies powered by Firestore streams.
- **Goal Milestones & Streaks**: Daily recitation target system (100, 300, 500, 1000, 5000) with visual animated progress indicators and daily streak tracker.
- **Quick Bulk Recitations**: Quick-add chips (`+10`, `+50`, `+100`, `+500`) with custom input dialogs and optimistic UI updates.
- **Haptic & Sensory Feedback**: Native tactile vibration on every count with low-latency responsiveness.

### 2. 🏛️ Islamic Aqaid (Creed) - Modern Image-Grid
- **Visual Category Architecture**: Clean 2-column image cards utilizing local high-resolution assets (`tauheed.png`, `risalat.png`, `ishq_rasool.png`, `sahaba.png`, `wilayat.png`, `ahle_sunnat.png`, `quran.png`).
- **Dedicated Category Detail Screen**: Tap any category card to access structured, authentic creed articles, Quranic proofs, and scholarly references.
- **Full Search & Filter**: Real-time bilingual search across topics, titles, and body texts in both Urdu and English.

### 3. 📚 Fiqh Masail Knowledge Hub & Q&A
- **Comprehensive Topic Grouping**: Logical categorization covering Namaz, Wuzu, Tayamum, Roza, Zakat, Hajj, Nikah, Taharat, and Miras.
- **Authentic Classical Citations**: Every ruling is cited with recognized classical sources (*Bahar-e-Shariat*, *Fatawa Ridawiyyah*, *Fatawa Alamgiri*, *Sahih al-Bukhari*, *Sahih Muslim*).
- **Interactive Q&A Forum**: Users can submit questions directly to Islamic scholars and receive real-time answers with push notifications.

### 4. 🌟 Daily Content: Hadith, Ayat & "Topic of the Day"
- **Multi-Document Architecture**: Non-destructive Firestore storage where each entry is preserved with full historical integrity.
- **3 Dedicated Content Types**:
  - `Hadith`: Daily Hadith with Arabic Matn, Urdu/English translation, book reference, and badge.
  - `Ayat`: Quranic Ayah with diacritics, Urdu/English translation, Surah name & Ayah number.
  - `Topic of the Day`: In-depth Islamic topic title, explanation, key takeaways, and scholarly source.
- **Paginated Home Screen Stepper**: Smooth horizontal `< 1 / N >` stepper with previous/next controls, sharing attribution, and full searchable archive sheet.

### 5. 📅 Smooth Upcoming Events Slider & Announcements
- **Bulletproof Horizontal Scroll**: Native snapping horizontal card list with responsive widths and touch-event separation.
- **Lifecycle Statuses**: Clear visual badges (`Coming Soon`, `Featured`, `Ongoing`, `Completed`, `Cancelled`).
- **Push & In-App Notifications**: Real-time announcements with batch mark-all-read capabilities and direct screen navigation.

### 6. 💻 Web Admin Management Dashboard
- **Live Metrics & Analytics**: Real-time KPI summary cards (Total Users, Global Durood, Today's Durood, Active Events).
- **Users Leaderboard**: Community ranking by streak, lifetime recitations, and points.
- **Dynamic Content Management**: Dynamic Add/Edit forms for Hadith, Ayat, Topic of the Day, Masail, Aqaid, and Events.
- **Direct Notification Broadcasts**: Send high-priority broadcast announcements to all users with one click.

### 7. 🌐 100% Bilingual Localization & RTL Support
- **Seamless English & Urdu (اردو) Switch**: Instant on-the-fly toggling of translations, typography, and text direction (LTR / RTL).
- **Persistent Settings**: User preferences, authentication state, and counter goals persist across sessions.

---

## 🛠️ Architecture & Technology Stack

```mermaid
graph TD
    Client[📱 Flutter Mobile & Web Client] --> Providers[⚡ LanguageProvider & State Handlers]
    Providers --> CoreServices[🛠️ AuthService | CounterService | ContentService | AdminService | NotificationService]
    CoreServices --> Firebase[(🔥 Firebase Cloud Firestore & Auth)]
    GitPush[💻 Git Push origin main] --> GHActions[⚙️ GitHub Actions CI/CD]
    GHActions --> BuildWeb[📦 Flutter Web Release Build]
    BuildWeb --> Hosting[🌐 Firebase Hosting - islamic-app-ed1ed.web.app]
```

| Layer | Technology / Package | Purpose |
|---|---|---|
| **Framework** | Flutter 3.x (Dart 3.x) | Cross-platform UI development for Android, iOS, and Web |
| **Backend & Auth** | Firebase Cloud Firestore & Firebase Auth | Real-time cloud synchronization, multi-document storage, and auth |
| **State Management** | `ChangeNotifier` / `ListenableBuilder` / `StreamBuilder` | Lightweight, performant, reactive state architecture |
| **Localization** | `LanguageProvider` + `AppTranslations` | Instant English/Urdu bilingual toggle with RTL/LTR layout handling |
| **CI / CD Pipeline** | GitHub Actions (`firebase-hosting-merge.yml`) | Automated build, test, and deployment to Google Firebase Hosting |
| **Design System** | Custom `AppColors` & `AppTypography` | Islamic emerald (`#0F5132`) and gold (`#D4AF37`) palette |

---

## 📁 Repository Structure

```text
islamic_app/
├── .github/
│   └── workflows/
│       ├── firebase-hosting-merge.yml        # CI/CD auto-deploy on push to main
│       └── firebase-hosting-pull-request.yml  # Preview channel deployment
├── android/                                  # Android native configuration
├── ios/                                      # iOS native configuration
├── web/                                      # Web entry point & PWA configuration
│   ├── index.html                            # Custom HTML with service worker cache-buster
│   ├── manifest.json                         # Progressive Web App manifest
│   └── favicon.png                           # Web application favicon
├── lib/
│   ├── main.dart                             # App bootstrap, NoorESunnatApp & universal gates
│   ├── firebase_options.dart                 # Multi-platform Firebase configuration
│   ├── core/
│   │   ├── constants/                        # AppColors, AppTheme, AppTypography
│   │   ├── dummy_data/                       # Fallback datasets (mock_masail, mock_aqaid)
│   │   ├── localization/                     # English & Urdu translation dictionaries
│   │   ├── models/                           # AppUser, MasailModel, AqaidModel, EventModel, DailyContentModel
│   │   ├── providers/                        # LanguageProvider (persistent locale & RTL handling)
│   │   └── utils/                            # Firestore seeder utility
│   ├── features/
│   │   ├── admin_panel/                      # Web Admin Portal (dashboard, tables, dynamic forms)
│   │   ├── auth/                             # LoginScreen with Google Sign-In & Email/Password
│   │   ├── counter/                          # CounterScreen, StatCard, Goal Tracker
│   │   ├── events/                           # UpcomingEventsScreen & EventCards
│   │   ├── home/                             # HomeScreen, HadithWisdomCard, Event Slider
│   │   ├── knowledge_hub/                    # MasailGridScreen, AqaidGridScreen & detail views
│   │   ├── profile/                          # User profile, statistics & settings
│   │   └── splash/                           # Animated branding splash screen
│   └── services/                             # AuthService, CounterService, ContentService, AdminService, NotificationService
├── test/                                     # Comprehensive automated unit & widget test suites
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

## 🧪 Testing & Code Quality

Run the automated test suite and static analysis:

```bash
# Run all unit and widget tests
flutter test

# Run static analysis
flutter analyze
```

---

## 🚢 CI/CD & Firebase Hosting Deployment

The repository includes an automated GitHub Actions workflow configured in `.github/workflows/firebase-hosting-merge.yml`.

### Automated Deployment:
Whenever code is pushed to the `main` branch:
1. GitHub Actions checks out the repository and sets up the Flutter environment.
2. Dependencies are resolved via `flutter pub get`.
3. Code is verified and the release web bundle is built via `flutter build web --release`.
4. Artifacts are automatically deployed live to **Firebase Hosting**.

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
*نورِ سنت — May Allah (ﷻ) illuminate our hearts with the light of Sunnah and infinite recitations of Salawat.*

</div>
