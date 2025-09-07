# Finance Tracker App

A modern Flutter app to track personal finances with a clean UI, Firebase sync, and both list and table views for transactions.

## Features

- Splash screen with auto-navigation to auth management
- Authentication (Firebase Auth) and session management
- Dashboard with:
  - Total balance, income, expenses
  - Budget remaining
  - Recent transactions
  - Category spending overview
- Transactions:
  - Search, category filter, and date range filter
  - Toggle between list view and table view
  - Add, edit, and delete transactions
  - Cloud sync with Firestore
- Budget screen (cloud-backed)
- Reports screen (analytics overview)
- Material 3 theme with Provider state management

## Prerequisites

- Flutter SDK 3.x (check with `flutter --version`)
- Dart SDK (bundled with Flutter)
- Android Studio/Xcode (for device emulators) or a physical device
- Firebase project and FlutterFire CLI (for cloud features)
  - Firebase CLI: `npm i -g firebase-tools`
  - FlutterFire CLI: `dart pub global activate flutterfire_cli`

## Getting Started

1) Clone the repository

```bash
git clone <https://github.com/Dilshan189/financetrakerapp.git>
cd financetrakerApp
```

2) Install dependencies

```bash
flutter pub get
```

3) Configure Firebase (required for auth/cloud sync)

- Create a Firebase project at `https://console.firebase.google.com`
- Add your Android and/or iOS app to the Firebase project
  - Android package name is defined in `android/app/build.gradle` (`applicationId`)
  - iOS bundle identifier is in Xcode project settings
- Run FlutterFire configuration

```bash
flutterfire configure
```

- Enable Authentication providers you plan to use (e.g., Email/Password)
- Create a Firestore database (Production or Test)

Minimal Firestore rules for development only (do NOT use in production):

```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/transactions/{docId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

4) Assets

- The app expects images under `images/` (e.g., `images/wallet.png`).
- Ensure `pubspec.yaml` includes the `images/` folder under `assets:` then run `flutter pub get`.

5) Run the app

```bash
# List available devices
flutter devices

# Run on a chosen device
flutter run -d <deviceId>
```

## Project Structure (key parts)

```
lib/
  providers/
    transaction_provider.dart     # Transaction model + Provider + Firestore sync
    budget_provider.dart          # Budget state + cloud sync (used in dashboard)
  screens/
    splashscreen.dart             # Splash → navigates to auth management
    auth/
      authmange_screen.dart       # Auth management (routing to login/home)
    add_transaction_screen.dart   # Add/Edit transaction form
    transactions_screen.dart      # Filters + list/table views + edit/delete
    dashborad_screen.dart         # Dashboard (stats, recent, categories)
    budget_screen.dart            # Budget view
    reports_screen.dart           # Reports/analytics
  theme/
    app_theme.dart                # Colors and theme helpers
```

## Usage Notes

- Transactions list supports both list and table views (toggle button in header).
- Table view is horizontally and vertically scrollable with visible scrollbars.
- Edit/Delete actions are available in both views.
- Dashboard starts cloud sync on init via `TransactionProvider.startListening()` and `BudgetProvider.loadFromCloud()`.

## Troubleshooting

- Blank splash or missing image: confirm `images/wallet.png` exists and `pubspec.yaml` lists `images/` under `assets:`; run `flutter pub get`.
- Navigation issues: ensure your app is wrapped with `GetMaterialApp` if you use GetX navigation, or adjust navigation to standard `Navigator`.
- Firebase errors:
  - Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are added properly by `flutterfire configure`.
  - Confirm Auth provider(s) enabled and Firestore rules allow access for the signed-in user.
- Cache/build issues: try `flutter clean && flutter pub get`.

## Common Commands

```bash
flutter clean
flutter pub get
flutter analyze
flutter run -d <deviceId>
```

## License

Specify your license here.
