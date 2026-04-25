# Entity Relationship Diagram (ERD)
# Selaphim – AI Vision & Voice Assistant

**Version:** 1.0.0  
**Date:** 2026-04-25

---

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   ┌──────────────────┐              ┌──────────────────────────────────┐   │
│   │      USER        │              │          SETTINGS                │   │
│   ├──────────────────┤   1:1        ├──────────────────────────────────┤   │
│   │ PK  id (UUID)    │◄────────────►│ PK  id (UUID)                    │   │
│   │     name         │              │ FK  user_id                      │   │
│   │     avatar_path  │              │     ai_provider (enum)           │   │
│   │     created_at   │              │     ai_model                     │   │
│   │     updated_at   │              │     tts_voice                    │   │
│   └──────────────────┘              │     tts_speed (real)             │   │
│            │                        │     tts_pitch (real)             │   │
│            │ 1:N                    │     language_code                │   │
│            │                        │     theme (enum: light/dark)     │   │
│            ▼                        │     live_vision_interval (int)   │   │
│   ┌──────────────────┐              │     notifications_enabled (bool) │   │
│   │   CONVERSATION   │              └──────────────────────────────────┘   │
│   ├──────────────────┤                                                      │
│   │ PK  id (UUID)    │                                                      │
│   │ FK  user_id      │                                                      │
│   │     title        │                                                      │
│   │     mode (enum)  │  ◄── voice | vision | text                          │
│   │     created_at   │                                                      │
│   │     updated_at   │                                                      │
│   └──────────────────┘                                                      │
│            │ 1:N                                                             │
│            │                                                                 │
│            ▼                                                                 │
│   ┌──────────────────────────────────────────────────────────┐              │
│   │                        MESSAGE                           │              │
│   ├──────────────────────────────────────────────────────────┤              │
│   │ PK  id (UUID)                                            │              │
│   │ FK  conversation_id                                      │              │
│   │     role (enum)      ◄── user | assistant | system      │              │
│   │     content (text)                                       │              │
│   │     image_path       ◄── local thumbnail (nullable)     │              │
│   │     tokens_used (int nullable)                          │              │
│   │     created_at                                           │              │
│   └──────────────────────────────────────────────────────────┘              │
│                                                                              │
│   ┌──────────────────┐                                                      │
│   │    DAILY_LOG     │                                                      │
│   ├──────────────────┤                                                      │
│   │ PK  id (UUID)    │                                                      │
│   │ FK  user_id      │                                                      │
│   │ FK  conversation_id (nullable) ◄── linked conversation                 │
│   │     log_date (date)                                                     │
│   │     entry_type (enum)  ◄── voice | vision | note | summary             │
│   │     content (text)                                                      │
│   │     created_at                                                          │
│   └──────────────────┘                                                      │
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │                         API_PROVIDER_CONFIG                          │  │
│   ├──────────────────────────────────────────────────────────────────────┤  │
│   │ PK  id (UUID)                                                        │  │
│   │ FK  user_id                                                          │  │
│   │     provider_name (enum)  ◄── openai | gemini | claude               │  │
│   │     key_reference         ◄── key stored in flutter_secure_storage   │  │
│   │     is_active (bool)                                                 │  │
│   │     created_at                                                       │  │
│   │     updated_at                                                       │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Entity Descriptions

### USER
The central entity representing the application user (local profile, no cloud auth).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT (UUID) | PK | Unique user identifier |
| name | TEXT | NOT NULL | Display name |
| avatar_path | TEXT | NULLABLE | Local file path to avatar image |
| created_at | TEXT (ISO8601) | NOT NULL | Profile creation timestamp |
| updated_at | TEXT (ISO8601) | NOT NULL | Last update timestamp |

---

### SETTINGS
One-to-one with USER. Stores all application preferences.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT (UUID) | PK | |
| user_id | TEXT | FK → USER.id | |
| ai_provider | TEXT | NOT NULL, DEFAULT 'openai' | openai \| gemini \| claude |
| ai_model | TEXT | NOT NULL, DEFAULT 'gpt-4o' | Model name string |
| tts_voice | TEXT | NULLABLE | Platform TTS voice ID |
| tts_speed | REAL | DEFAULT 1.0 | Speech rate multiplier |
| tts_pitch | REAL | DEFAULT 1.0 | Pitch multiplier |
| language_code | TEXT | DEFAULT 'en-US' | BCP-47 locale code |
| theme | TEXT | DEFAULT 'system' | light \| dark \| system |
| live_vision_interval | INTEGER | DEFAULT 10 | Seconds between auto-captures |
| notifications_enabled | INTEGER | DEFAULT 1 | SQLite bool (0/1) |

---

### CONVERSATION
A session of multi-turn dialogue, either voice or vision initiated.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT (UUID) | PK | |
| user_id | TEXT | FK → USER.id | Owner |
| title | TEXT | NULLABLE | Auto-generated or user-set title |
| mode | TEXT | NOT NULL | voice \| vision \| text |
| created_at | TEXT (ISO8601) | NOT NULL | |
| updated_at | TEXT (ISO8601) | NOT NULL | |

---

### MESSAGE
An individual message within a conversation.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT (UUID) | PK | |
| conversation_id | TEXT | FK → CONVERSATION.id, ON DELETE CASCADE | |
| role | TEXT | NOT NULL | user \| assistant \| system |
| content | TEXT | NOT NULL | Message text (or transcription) |
| image_path | TEXT | NULLABLE | Local path to thumbnail for vision messages |
| tokens_used | INTEGER | NULLABLE | Token count from provider response |
| created_at | TEXT (ISO8601) | NOT NULL | |

---

### DAILY_LOG
Timestamped record of all activity for monitoring and summary generation.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT (UUID) | PK | |
| user_id | TEXT | FK → USER.id | |
| conversation_id | TEXT | FK → CONVERSATION.id, NULLABLE | Linked conversation |
| log_date | TEXT (YYYY-MM-DD) | NOT NULL | Date of the log entry |
| entry_type | TEXT | NOT NULL | voice \| vision \| note \| summary |
| content | TEXT | NOT NULL | Log text or summary |
| created_at | TEXT (ISO8601) | NOT NULL | |

---

### API_PROVIDER_CONFIG
Stores which provider is configured (API key stored separately in secure storage).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT (UUID) | PK | |
| user_id | TEXT | FK → USER.id | |
| provider_name | TEXT | NOT NULL | openai \| gemini \| claude |
| key_reference | TEXT | NOT NULL | Key name used in flutter_secure_storage |
| is_active | INTEGER | DEFAULT 0 | SQLite bool |
| created_at | TEXT (ISO8601) | NOT NULL | |
| updated_at | TEXT (ISO8601) | NOT NULL | |

---

## Relationships Summary

| Relationship | Type | Description |
|-------------|------|-------------|
| USER → SETTINGS | 1:1 | Each user has exactly one settings record |
| USER → CONVERSATION | 1:N | A user can have many conversations |
| CONVERSATION → MESSAGE | 1:N | A conversation holds many messages |
| USER → DAILY_LOG | 1:N | A user accumulates many daily log entries |
| CONVERSATION → DAILY_LOG | 1:N (optional) | A log entry may reference a conversation |
| USER → API_PROVIDER_CONFIG | 1:N | A user may configure multiple AI providers |

---

## Database Schema (SQLite DDL)

```sql
-- Users table
CREATE TABLE IF NOT EXISTS users (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  avatar_path  TEXT,
  created_at   TEXT NOT NULL,
  updated_at   TEXT NOT NULL
);

-- Settings table (1:1 with users)
CREATE TABLE IF NOT EXISTS settings (
  id                    TEXT PRIMARY KEY,
  user_id               TEXT NOT NULL UNIQUE,
  ai_provider           TEXT NOT NULL DEFAULT 'openai',
  ai_model              TEXT NOT NULL DEFAULT 'gpt-4o',
  tts_voice             TEXT,
  tts_speed             REAL NOT NULL DEFAULT 1.0,
  tts_pitch             REAL NOT NULL DEFAULT 1.0,
  language_code         TEXT NOT NULL DEFAULT 'en-US',
  theme                 TEXT NOT NULL DEFAULT 'system',
  live_vision_interval  INTEGER NOT NULL DEFAULT 10,
  notifications_enabled INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL,
  title      TEXT,
  mode       TEXT NOT NULL CHECK(mode IN ('voice', 'vision', 'text')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
  id              TEXT PRIMARY KEY,
  conversation_id TEXT NOT NULL,
  role            TEXT NOT NULL CHECK(role IN ('user', 'assistant', 'system')),
  content         TEXT NOT NULL,
  image_path      TEXT,
  tokens_used     INTEGER,
  created_at      TEXT NOT NULL,
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);

-- Daily logs table
CREATE TABLE IF NOT EXISTS daily_logs (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL,
  conversation_id TEXT,
  log_date        TEXT NOT NULL,
  entry_type      TEXT NOT NULL CHECK(entry_type IN ('voice', 'vision', 'note', 'summary')),
  content         TEXT NOT NULL,
  created_at      TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE SET NULL
);

-- API provider configurations
CREATE TABLE IF NOT EXISTS api_provider_configs (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL,
  provider_name TEXT NOT NULL CHECK(provider_name IN ('openai', 'gemini', 'claude')),
  key_reference TEXT NOT NULL,
  is_active     INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE(user_id, provider_name)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_daily_logs_user_date ON daily_logs(user_id, log_date);
CREATE INDEX IF NOT EXISTS idx_api_configs_user_id ON api_provider_configs(user_id);
```
