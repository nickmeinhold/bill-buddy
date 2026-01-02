# Bill Buddy

A personal finance app for tracking subscriptions, bills, budgets, and transactions—built with Flutter and Firebase.

## Features

- **Subscription tracking**: Monitor recurring charges and upcoming payments
- **Bill management**: Track due dates with reminders
- **Budget monitoring**: Set spending limits by category
- **Transaction history**: View and categorize spending
- **Bank statement parsing**: Upload PDF statements to auto-import transactions
- **Client-side encryption**: All sensitive financial data encrypted with your passphrase—not even Firebase can read it

## Tech Stack

- **Frontend**: Flutter (iOS, Android, macOS, Web)
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Backend**: Firebase (Auth + Firestore + Storage + Cloud Functions)
- **Charts**: fl_chart

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run on specific platform
flutter run -d macos
flutter run -d chrome
```

## Development

```bash
# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Deploy Cloud Functions
cd functions && npm run deploy
```

## Documentation

- [CLAUDE.md](./CLAUDE.md) - Detailed developer guide (architecture, patterns, setup)
- [docs/cdr-research.md](./docs/cdr-research.md) - CDR/Open Banking research and business model notes
- [docs/cdr-data-flow.mermaid](./docs/cdr-data-flow.mermaid) - Sequence diagram of CDR data flows

## Security

All sensitive data (transaction amounts, merchant names, notes) is encrypted client-side using AES-256-GCM before storage. Users set an encryption passphrase separate from their login credentials, with recovery codes for account recovery.

See the "Client-Side Encryption" section in [CLAUDE.md](./CLAUDE.md) for details.

## Roadmap

- [ ] AI-powered transaction categorization (Gemini Flash)
- [ ] Multi-bank PDF parsing support
- [ ] Apple Sign-In
- [ ] CDR/Open Banking integration via Basiq
- [ ] Bill negotiation service
