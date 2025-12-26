# Bill Buddy

A personal finance app built with Flutter, inspired by [Rocket Money](https://www.rocketmoney.com/). Track your subscriptions, bills, budgets, and transactions all in one place.

## Features

- **Dashboard** - Overview of monthly spending, active subscriptions, upcoming bills, recent transactions, and budget progress
- **Subscriptions** - Track recurring subscriptions with monthly/yearly cost calculations
- **Bills** - Manage bills with due dates, payment status, and reminders
- **Budgets** - Set spending limits by category and track progress
- **Transactions** - Log income and expenses with filtering options

## Screenshots

*Coming soon*

## Getting Started

### Prerequisites

- Flutter SDK (3.10+)
- Firebase project
- Xcode (for iOS/macOS)
- Android Studio (for Android)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/bill_buddy.git
   cd bill_buddy
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   ```bash
   # Install FlutterFire CLI if needed
   dart pub global activate flutterfire_cli

   # Configure Firebase (generates lib/firebase_options.dart)
   flutterfire configure
   ```

4. Set up Firestore security rules in Firebase Console:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

5. Enable Authentication in Firebase Console:
   - Go to Authentication > Sign-in method
   - Enable Email/Password

6. Run the app:
   ```bash
   flutter run
   ```

## Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Backend**: Firebase (Auth + Firestore)
- **Charts**: fl_chart
- **Fonts**: Google Fonts (Inter)

## Project Structure

```
lib/
├── core/           # Constants and theming
├── features/       # Feature modules (auth, dashboard, transactions, etc.)
│   └── {feature}/
│       ├── domain/        # Providers and services
│       └── presentation/  # Screens and widgets
├── routing/        # GoRouter configuration
└── shared/         # Shared models and widgets
```

## Supported Platforms

- iOS
- Android
- macOS
- Web (Chrome)

## License

MIT
