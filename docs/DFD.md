# Data Flow Diagram (DFD)
# Selaphim – AI Vision & Voice Assistant

**Version:** 1.0.0  
**Date:** 2026-04-25

---

## Level 0 – Context Diagram

```
                        ┌──────────────────────────────────────────┐
                        │                                          │
  ┌──────────┐          │         SELAPHIM APPLICATION            │          ┌─────────────────┐
  │          │ voice /  │                                          │  API     │                 │
  │   USER   │─────────►│   ◄── AI Vision & Voice Assistant ──►   │─────────►│  AI PROVIDER    │
  │          │  camera  │                                          │  calls   │ (OpenAI/Gemini/ │
  └──────────┘          │                                          │          │  Claude)        │
       ▲                └──────────────────────────────────────────┘          └─────────────────┘
       │                              │         ▲
       │ TTS audio /                  │ read /  │ write
       │ screen text                  ▼ write   │
       └──────────────────────  ┌───────────────────┐
                                │  LOCAL STORAGE    │
                                │ (SQLite + Secure) │
                                └───────────────────┘
```

---

## Level 1 – Main Processes

```
                                 ┌──────────────┐
                                 │    USER      │
                                 └──────┬───────┘
                                        │
         ┌──────────────┬───────────────┼────────────────┬─────────────────┐
         │              │               │                │                 │
         ▼              ▼               ▼                ▼                 ▼
  ┌─────────────┐ ┌───────────┐ ┌─────────────┐ ┌────────────┐ ┌──────────────────┐
  │  1.0        │ │  2.0      │ │  3.0        │ │  4.0       │ │  5.0             │
  │  Vision     │ │  Voice    │ │  Daily Life │ │  History   │ │  Settings        │
  │  Analysis   │ │  Assistant│ │  Monitor    │ │  Manager   │ │  Manager         │
  └──────┬──────┘ └─────┬─────┘ └──────┬──────┘ └─────┬──────┘ └──────────────────┘
         │              │               │               │
         └──────────────┴───────────────┴───────────────┘
                                    │
                    ┌───────────────┴────────────────┐
                    │                                │
                    ▼                                ▼
          ┌──────────────────┐            ┌──────────────────┐
          │  AI PROVIDER API │            │  LOCAL STORAGE   │
          └──────────────────┘            └──────────────────┘
```

---

## Level 2 – Process 1.0: Vision Analysis

```
  USER
   │
   │ 1. Tap "Analyse"
   ▼
┌──────────────────────────────────────────────────────────────────┐
│                        1.0 Vision Analysis                       │
│                                                                  │
│  ┌──────────────┐    image    ┌──────────────────┐              │
│  │ 1.1 Camera   │────────────►│ 1.2 Image        │              │
│  │ Capture      │             │ Preprocessor     │              │
│  └──────────────┘             └────────┬─────────┘              │
│                                        │ base64 image            │
│                                        ▼                         │
│                              ┌──────────────────┐  API request  │
│  Custom prompt ─────────────►│ 1.3 AI Request   │──────────────►│ AI PROVIDER
│  (from user)                 │ Builder          │◄──────────────┤
│                              └────────┬─────────┘  AI response  │
│                                       │                          │
│                                       ▼                          │
│                              ┌──────────────────┐               │
│                              │ 1.4 Response     │               │
│                              │ Presenter        │               │
│                              └────────┬─────────┘               │
└───────────────────────────────────────┼─────────────────────────┘
                                        │
                    ┌───────────────────┼────────────────────┐
                    │                   │                     │
                    ▼                   ▼                     ▼
              Display text         TTS audio            Log to DB
              on screen           playback           (timestamp +
                                                     thumbnail +
                                                      response)
```

---

## Level 2 – Process 2.0: Voice Assistant

```
  USER
   │
   │ 1. Press mic button / wake word
   ▼
┌──────────────────────────────────────────────────────────────────┐
│                      2.0 Voice Assistant                         │
│                                                                  │
│  ┌──────────────┐  raw audio  ┌──────────────────┐              │
│  │ 2.1 Audio    │────────────►│ 2.2 STT Engine   │              │
│  │ Recorder     │             │ (on-device /     │              │
│  └──────────────┘             │  OpenAI Whisper) │              │
│                               └────────┬─────────┘              │
│                                        │ transcript text         │
│                                        ▼                         │
│  Conversation ─────────────────►┌──────────────────┐            │
│  History (context)              │ 2.3 AI Chat      │──────────► AI PROVIDER
│                                 │ Request Builder  │◄──────────
│                                 └────────┬─────────┘  response  │
│                                          │                       │
│                                          ▼                       │
│                                 ┌──────────────────┐             │
│                                 │ 2.4 TTS Playback │             │
│                                 └────────┬─────────┘             │
└──────────────────────────────────────────┼──────────────────────┘
                                           │
                    ┌──────────────────────┼──────────────────┐
                    │                      │                   │
                    ▼                      ▼                   ▼
              Display text           Audio output         Log to DB
              transcript             (speaker)          (conversation
                                                          entry)
```

---

## Level 2 – Process 3.0: Daily Life Monitor

```
  TIMER / USER EVENT
        │
        ▼
┌────────────────────────────────────────────────────────────────┐
│                    3.0 Daily Life Monitor                      │
│                                                                │
│  ┌───────────────────┐        ┌───────────────────────────┐   │
│  │ 3.1 Event         │───────►│ 3.2 Activity Logger       │   │
│  │ Collector         │        │ (save to DailyLog table)  │   │
│  │ (voice events,    │        └─────────────┬─────────────┘   │
│  │  vision events,   │                      │                  │
│  │  manual notes)    │                      ▼                  │
│  └───────────────────┘           ┌──────────────────────┐     │
│                                  │ 3.3 Stats Aggregator  │     │
│                                  │ (count, duration,     │     │
│                                  │  topic frequency)     │     │
│                                  └──────────┬────────────┘     │
│                                             │                   │
│                                             ▼                   │
│                                  ┌──────────────────────┐      │
│                                  │ 3.4 Summary          │ ────►│ AI PROVIDER
│                                  │ Generator (daily /   │◄────
│                                  │  weekly AI summary)  │      │
│                                  └──────────┬───────────┘      │
└──────────────────────────────────────────────┼──────────────────┘
                                               │
                                 ┌─────────────┼──────────────┐
                                 │             │              │
                                 ▼             ▼              ▼
                           Local DB      Notification    UI Stats
                           (persist)     (daily digest)   Screen
```

---

## Level 2 – Process 4.0: History Manager

```
  USER
   │
   ├─ Search query ──► 4.1 Search & Filter ──► DB query ──► results list
   ├─ Delete request ─► 4.2 Delete Handler ──► DB delete
   └─ Export request ─► 4.3 Export Builder ──► JSON/TXT file ──► share sheet
```

---

## Level 2 – Process 5.0: Settings Manager

```
  USER
   │
   ├─ Select provider ─► 5.1 Provider Config ──► Secure Storage (provider name)
   ├─ Enter API key ───► 5.2 Key Vault ──────────► Secure Storage (encrypted key)
   ├─ Select model ────► 5.3 Model Config ────────► SharedPreferences
   ├─ Configure TTS ───► 5.4 TTS Config ──────────► SharedPreferences
   └─ Toggle theme ────► 5.5 Theme Config ─────────► SharedPreferences
```

---

## Data Stores

| Store ID | Name | Technology | Contents |
|---------|------|-----------|---------|
| DS-1 | Conversations DB | SQLite (sqflite) | conversation_id, messages, timestamps |
| DS-2 | Daily Logs DB | SQLite (sqflite) | log entries, type, content, timestamp |
| DS-3 | User Profile | SharedPreferences | name, avatar path, stats |
| DS-4 | App Settings | SharedPreferences | provider, model, TTS config, theme |
| DS-5 | API Keys Vault | flutter_secure_storage | encrypted API keys per provider |

---

## Data Flows Summary

| Flow ID | From | To | Data |
|---------|------|----|------|
| DF-01 | User | Camera | tap event |
| DF-02 | Camera | Image Preprocessor | JPEG frame |
| DF-03 | Image Preprocessor | AI Request Builder | base64 image + prompt |
| DF-04 | AI Request Builder | AI Provider API | HTTP POST (JSON) |
| DF-05 | AI Provider API | Response Presenter | JSON response |
| DF-06 | Response Presenter | TTS Engine | text string |
| DF-07 | TTS Engine | User | audio |
| DF-08 | User | Audio Recorder | speech |
| DF-09 | Audio Recorder | STT Engine | PCM audio |
| DF-10 | STT Engine | AI Chat Builder | transcript text |
| DF-11 | AI Chat Builder | AI Provider API | HTTP POST (JSON) |
| DF-12 | AI Provider API | TTS Playback | response text |
| DF-13 | Any Process | Daily Log DB | log entry |
| DF-14 | Settings UI | Secure Storage | API key |
| DF-15 | Secure Storage | AI Request Builder | decrypted API key |
