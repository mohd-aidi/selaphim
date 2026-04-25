# Software Requirements Specification (SRS)
# Selaphim – AI Vision & Voice Assistant

**Version:** 1.0.0  
**Date:** 2026-04-25  
**Status:** Approved

---

## Table of Contents
1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [Functional Requirements](#3-functional-requirements)
4. [Non-Functional Requirements](#4-non-functional-requirements)
5. [System Constraints](#5-system-constraints)
6. [External Interface Requirements](#6-external-interface-requirements)
7. [Use Cases](#7-use-cases)

---

## 1. Introduction

### 1.1 Purpose
This document specifies the software requirements for **Selaphim**, a Flutter-based mobile application that provides an AI-powered vision and voice assistant to monitor and assist users in their daily lives.

### 1.2 Scope
Selaphim is a cross-platform mobile application (Android & iOS) that leverages AI providers (OpenAI/ChatGPT, Google Gemini, Anthropic Claude) to:
- Analyze the user's visual environment via the device camera
- Engage in natural voice conversations to answer questions and provide guidance
- Log and summarize daily activities and interactions
- Provide proactive suggestions based on user context

### 1.3 Definitions & Acronyms
| Term | Definition |
|------|-----------|
| AI Provider | Third-party AI API service (OpenAI, Gemini, Claude) |
| STT | Speech-to-Text |
| TTS | Text-to-Speech |
| Vision Analysis | AI interpretation of camera images |
| Daily Log | Timestamped record of assistant interactions |
| SRS | Software Requirements Specification |
| DFD | Data Flow Diagram |
| ERD | Entity Relationship Diagram |

### 1.4 References
- OpenAI API Documentation: https://platform.openai.com/docs
- Google Gemini API: https://ai.google.dev
- Anthropic Claude API: https://docs.anthropic.com
- Flutter Documentation: https://flutter.dev/docs

---

## 2. Overall Description

### 2.1 Product Perspective
Selaphim is a standalone mobile application. It communicates with external AI provider APIs over HTTPS. User data is stored locally on the device (preferences, conversation history, daily logs). API keys are stored in secure device storage.

### 2.2 Product Functions (High-Level)
| ID | Function |
|----|---------|
| F-01 | AI Vision Analysis – capture image/video frame and describe the scene |
| F-02 | Voice Assistant – microphone input → AI processing → TTS output |
| F-03 | Daily Activity Monitoring – automatic logging of interactions |
| F-04 | Activity Summary – AI-generated daily/weekly summaries |
| F-05 | Settings – choose AI provider, model, language, voice |
| F-06 | History – browse past conversations and activity logs |
| F-07 | Proactive Alerts – reminders and suggestions based on context |

### 2.3 User Classes and Characteristics
| User Class | Description |
|-----------|-------------|
| General User | Non-technical user using vision & voice features daily |
| Power User | Technical user who configures custom API keys and model settings |

### 2.4 Operating Environment
- **Platforms:** Android 6.0+ (API 23+), iOS 13+
- **Connectivity:** Internet required for AI provider calls; basic STT/TTS may work offline
- **Hardware:** Device camera (rear + front), microphone, speakers

### 2.5 Design Constraints
- Flutter 3.x SDK
- Must not store raw API keys in plain text (use flutter_secure_storage)
- All AI API calls must be made over TLS 1.2+
- Comply with GDPR / local privacy regulations (no user data sent to third parties without consent)

---

## 3. Functional Requirements

### 3.1 User Authentication & Profile (FR-AUTH)
| ID | Requirement |
|----|------------|
| FR-AUTH-01 | The system shall allow users to create a local profile (name, avatar). |
| FR-AUTH-02 | The system shall not require cloud account registration. |
| FR-AUTH-03 | The system shall provide an optional PIN / biometric lock. |

### 3.2 AI Vision Module (FR-VIS)
| ID | Requirement |
|----|------------|
| FR-VIS-01 | The system shall access the device rear camera to capture still images. |
| FR-VIS-02 | The system shall send captured images to the selected AI provider with a user-defined or default prompt ("Describe what you see"). |
| FR-VIS-03 | The system shall display the AI text response on screen and optionally speak it aloud. |
| FR-VIS-04 | The system shall support continuous live-description mode (analyse every N seconds). |
| FR-VIS-05 | The system shall allow the user to type or speak a custom prompt before capture. |
| FR-VIS-06 | The system shall log each vision analysis (timestamp, image thumbnail, response). |

### 3.3 Voice Assistant Module (FR-VOICE)
| ID | Requirement |
|----|------------|
| FR-VOICE-01 | The system shall record voice input using the device microphone. |
| FR-VOICE-02 | The system shall convert speech to text using on-device STT or a provider STT API. |
| FR-VOICE-03 | The system shall send the transcribed text to the AI provider and receive a response. |
| FR-VOICE-04 | The system shall synthesise and play the AI response using TTS. |
| FR-VOICE-05 | The system shall maintain conversation context (multi-turn dialogue). |
| FR-VOICE-06 | The system shall support wake-word detection ("Hey Selaphim") when the app is in foreground. |
| FR-VOICE-07 | The system shall allow the user to read the transcript after each exchange. |

### 3.4 Daily Life Monitoring (FR-MON)
| ID | Requirement |
|----|------------|
| FR-MON-01 | The system shall log every voice or vision interaction with a timestamp. |
| FR-MON-02 | The system shall generate a daily summary of interactions using the AI provider. |
| FR-MON-03 | The system shall display activity statistics (interactions per day, topic frequency). |
| FR-MON-04 | The system shall send optional daily reminder notifications to encourage usage. |
| FR-MON-05 | The system shall allow the user to add manual notes to a daily log. |

### 3.5 Settings (FR-SET)
| ID | Requirement |
|----|------------|
| FR-SET-01 | The system shall allow selection of AI provider: OpenAI, Google Gemini, Anthropic Claude. |
| FR-SET-02 | The system shall allow entry of custom API key(s) per provider stored securely. |
| FR-SET-03 | The system shall allow selection of AI model (e.g., gpt-4o, gpt-4-turbo, gemini-1.5-pro). |
| FR-SET-04 | The system shall allow configuration of TTS voice, speed, and pitch. |
| FR-SET-05 | The system shall allow selection of app language / locale. |
| FR-SET-06 | The system shall allow configuration of live-vision interval (5 s – 60 s). |
| FR-SET-07 | The system shall allow toggling dark/light theme. |

### 3.6 History (FR-HIST)
| ID | Requirement |
|----|------------|
| FR-HIST-01 | The system shall display a paginated list of past conversations grouped by date. |
| FR-HIST-02 | The system shall allow the user to search history by keyword. |
| FR-HIST-03 | The system shall allow the user to delete individual or all history entries. |
| FR-HIST-04 | The system shall allow exporting history as a plain-text or JSON file. |

---

## 4. Non-Functional Requirements

### 4.1 Performance
| ID | Requirement |
|----|------------|
| NFR-PERF-01 | AI response latency should be < 3 s on a 4G connection. |
| NFR-PERF-02 | App cold-start time should be < 2 s on mid-range devices. |
| NFR-PERF-03 | Camera preview should render at ≥ 30 FPS. |

### 4.2 Security
| ID | Requirement |
|----|------------|
| NFR-SEC-01 | API keys shall be stored in encrypted secure storage (flutter_secure_storage). |
| NFR-SEC-02 | All network communications shall use HTTPS/TLS 1.2+. |
| NFR-SEC-03 | Images sent to AI APIs shall not be cached on remote servers beyond the API call. |
| NFR-SEC-04 | The app shall request only required permissions (camera, microphone, notifications). |

### 4.3 Usability
| ID | Requirement |
|----|------------|
| NFR-USE-01 | The primary voice-assistant feature shall be accessible in ≤ 2 taps from the home screen. |
| NFR-USE-02 | The UI shall comply with Material Design 3 guidelines. |
| NFR-USE-03 | All interactive elements shall meet WCAG 2.1 AA accessibility standards. |

### 4.4 Reliability
| ID | Requirement |
|----|------------|
| NFR-REL-01 | The app shall gracefully handle network timeouts (show error, allow retry). |
| NFR-REL-02 | Conversation history shall persist across app restarts. |

### 4.5 Maintainability
| ID | Requirement |
|----|------------|
| NFR-MNT-01 | Code shall follow Dart effective style guide. |
| NFR-MNT-02 | New AI providers shall be addable by implementing an abstract AIService interface. |

---

## 5. System Constraints

- The app **does not** provide its own AI backend; all AI processing is delegated to external APIs.
- Free-tier API keys may have rate limits; the app must handle HTTP 429 gracefully.
- Vision analysis requires uploading images; user must consent to data transmission.

---

## 6. External Interface Requirements

### 6.1 AI Provider APIs
| Provider | Endpoint | Auth |
|---------|----------|------|
| OpenAI | https://api.openai.com/v1/chat/completions | Bearer API Key |
| Google Gemini | https://generativelanguage.googleapis.com/v1beta | API Key query param |
| Anthropic Claude | https://api.anthropic.com/v1/messages | x-api-key header |

### 6.2 Device APIs
- Camera2 API (Android) / AVFoundation (iOS) via `camera` Flutter plugin
- SpeechRecognizer (Android) / SFSpeechRecognizer (iOS) via `speech_to_text` plugin
- AudioSession + FlutterTTS via `flutter_tts` plugin

---

## 7. Use Cases

### UC-01: Describe My Environment
**Actor:** User  
**Precondition:** App is open, camera permission granted, AI provider configured.  
**Main Flow:**
1. User taps "Vision" tab.
2. User taps "Analyse Scene" button.
3. App captures image from rear camera.
4. App sends image + prompt to AI provider.
5. AI returns text description.
6. App displays text and reads it aloud via TTS.

### UC-02: Ask the Assistant a Question
**Actor:** User  
**Precondition:** Microphone permission granted, AI provider configured.  
**Main Flow:**
1. User taps microphone button on Home/Voice screen.
2. User speaks their question.
3. App transcribes speech → text.
4. App sends text to AI provider (with conversation history).
5. AI returns answer.
6. App displays and reads the answer aloud.

### UC-03: Review Daily Summary
**Actor:** User  
**Precondition:** At least one logged interaction for today.  
**Main Flow:**
1. User navigates to "History" tab.
2. User taps "Today's Summary".
3. App sends today's log to AI provider with summary prompt.
4. App displays AI-generated summary.

### UC-04: Change AI Provider
**Actor:** User  
**Main Flow:**
1. User navigates to "Settings" tab.
2. User selects desired provider from dropdown.
3. User enters API key.
4. App saves key to secure storage.
5. All future AI calls use the new provider.
