# Selaphim – AI Vision & Voice Assistant

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Your intelligent daily-life companion** – powered by OpenAI (ChatGPT), Google Gemini, or Anthropic Claude.

---

## Overview

**Selaphim** is a cross-platform Flutter mobile application (Android & iOS) that combines:

| Feature | Description |
|---------|-------------|
| 📷 **AI Vision** | Point your camera at anything and receive an instant AI-generated description |
| 🎤 **Voice Assistant** | Speak to a multi-turn AI assistant and receive spoken replies |
| 📋 **Daily Life Monitor** | Automatic logging of every interaction with daily summaries |
| ⚙️ **Flexible AI Providers** | Switch between OpenAI, Google Gemini, and Anthropic Claude in Settings |
| 🌙 **Dark / Light Theme** | Full Material Design 3 theming |
| 🔒 **Secure API Key Storage** | Keys stored in the device keychain via `flutter_secure_storage` |

---

## Documentation

Detailed design documentation lives in the [`docs/`](docs/) folder:

| Document | Description |
|---------|-------------|
| [SRS.md](docs/SRS.md) | Software Requirements Specification – functional and non-functional requirements, use cases |
| [DFD.md](docs/DFD.md) | Data Flow Diagrams (Level 0, 1, and 2) |
| [ERD.md](docs/ERD.md) | Entity Relationship Diagram and full SQLite DDL schema |

---

## Getting Started

### Prerequisites
- Flutter SDK 3.x ([install](https://flutter.dev/docs/get-started/install))
- Dart SDK 3.x (bundled with Flutter)
- Android Studio / Xcode for device targets
- An API key from at least one AI provider:
  - [OpenAI](https://platform.openai.com/api-keys)
  - [Google AI Studio (Gemini)](https://aistudio.google.com/app/apikey)
  - [Anthropic Console (Claude)](https://console.anthropic.com/)

### Installation

```bash
git clone https://github.com/mohd-aidi/selaphim.git
cd selaphim
flutter pub get
flutter run
```

### First Run
1. Launch the app – a default profile is created automatically.
2. Navigate to **Settings → API Keys**.
3. Enter your preferred AI provider's API key and tap **Save**.
4. Select the provider and model from the dropdowns.
5. Return to the **Voice** or **Vision** tab and start interacting!

---

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp + theme setup
├── models/
│   ├── ai_provider.dart         # AIProvider enum + extensions
│   ├── app_settings.dart        # Settings model
│   ├── conversation.dart        # Conversation + Message models
│   ├── daily_log.dart           # DailyLog model
│   └── user_profile.dart        # UserProfile model
├── services/
│   ├── ai_service.dart          # OpenAI / Gemini / Claude adapters
│   ├── camera_service.dart      # Camera capture + live-stream
│   ├── database_service.dart    # SQLite (sqflite) persistence layer
│   ├── secure_storage_service.dart  # flutter_secure_storage wrapper
│   ├── speech_service.dart      # speech_to_text wrapper
│   └── tts_service.dart         # flutter_tts wrapper
├── providers/
│   ├── activity_provider.dart   # Daily logs + conversation history
│   ├── conversation_provider.dart  # Active conversation state
│   └── settings_provider.dart   # App settings + user profile
├── screens/
│   ├── home_screen.dart         # Dashboard + bottom navigation
│   ├── vision_screen.dart       # Camera + AI vision analysis
│   ├── voice_assistant_screen.dart  # Mic + chat UI
│   ├── history_screen.dart      # Conversation history + daily logs
│   └── settings_screen.dart     # Full settings page
├── widgets/
│   ├── ai_response_card.dart    # Chat bubble for AI/user messages
│   ├── activity_card.dart       # Daily log list item
│   ├── stat_tile.dart           # Stat counter tile for dashboard
│   └── voice_input_button.dart  # Animated mic FAB
└── utils/
    ├── app_theme.dart           # Material 3 light + dark themes
    ├── constants.dart           # App-wide constants
    └── helpers.dart             # Date/string formatting helpers
docs/
├── SRS.md    # Software Requirements Specification
├── DFD.md    # Data Flow Diagram
└── ERD.md    # Entity Relationship Diagram
test/
└── models_test.dart             # Unit tests for all models
```

---

## Architecture

```
┌─────────────────────────────────────────────┐
│                  Flutter UI                  │
│  Screens ◄──── Providers (ChangeNotifier)   │
└────────────────────┬────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
   AI Service   DB Service   Speech/TTS
(HTTP/REST)    (SQLite)    (Platform API)
        │
   OpenAI / Gemini / Claude
```

State management uses **Provider** (ChangeNotifier). The three core providers are:

- `SettingsProvider` – user profile, AI provider config, TTS settings
- `ConversationProvider` – current conversation, sends messages to AI APIs
- `ActivityProvider` – daily logs, history, statistics

---

## Permissions Required

| Permission | Reason |
|-----------|--------|
| `CAMERA` | Vision analysis |
| `RECORD_AUDIO` | Voice input (STT) |
| `INTERNET` | AI API calls |
| `POST_NOTIFICATIONS` | Daily reminder notifications |

---

## Running Tests

```bash
flutter test
```

---

## Security

- API keys are stored using `flutter_secure_storage` (device keychain / encrypted shared preferences) – **never** stored in plain text.
- All network calls use HTTPS.
- No user data is stored outside the device without explicit consent.

---

## License

MIT © mohd-aidi
