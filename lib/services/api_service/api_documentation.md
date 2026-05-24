# Cognithor Frontend — API Service Documentation

## Overview

This document describes the frontend API service layer for communicating with the Cognithor backend. The service implements a three-tier security model:

1. **Public** — health check, server info (plain HTTP)
2. **Login** — credentials exchanged for JWT (plain HTTP)
3. **Encrypted** — all authenticated payloads encrypted with AES-256-GCM using key derived from JWT

## Security Architecture

```
Flutter App                    Cognithor Backend
┌──────────────┐               ┌──────────────────┐
│              │   GET /        │                  │
│  Connect     │──────────────→│  Public routes    │
│  Screen      │←──────────────│  (plain JSON)     │
│              │   server info  │                  │
├──────────────┤               ├──────────────────┤
│              │   POST /token  │                  │
│  Login       │──────────────→│  Login route     │
│  Form        │←──────────────│  (plain JSON)     │
│              │   JWT          │                  │
├──────────────┤               ├──────────────────┤
│              │   Encrypted    │                  │
│  ApiClient   │──────────────→│  Middleware       │
│  (AES-256-   │←──────────────│  (decrypt/encrypt)│
│   GCM)       │   Encrypted    │                  │
└──────────────┘               └──────────────────┘
```

### Encryption Flow

1. Client obtains JWT via `POST /token`
2. `ApiClient.setToken(jwt)` derives AES-256 key: `SHA-256(JWT)` → 32 bytes
3. All subsequent requests: body wrapped in `{"_token": jwt, "_body": {...}}`, encrypted with AES-256-GCM
4. All responses: received as `{"iv": "...", "data": "..."}`, decrypted using same key
5. When JWT expires → re-login → new JWT → new key automatically
6. **Single-session**: each login increments a `token_version` (embedded as `ver` in JWT). If someone else logs in as the same user, the old JWT gets `401 Token superseded by another login` on next use.

## Classes

### ApiClient

**File:** `api_client.dart`

Base HTTP client. When a token is set, all request bodies are encrypted and all responses decrypted automatically.

```dart
final client = ApiClient(baseUrl: 'http://localhost:4464');
```

**Methods:**

| Method | Description |
|---|---|
| `setBaseUrl(url)` | Change backend URL |
| `setToken(token?)` | Set/clear JWT — derives AES key automatically |
| `get(path)` | GET with encrypted response |
| `post(path, body)` | POST with encrypted body + decrypted response |
| `put(path, body)` | PUT with encrypted body + decrypted response |
| `delete(path)` | DELETE with encrypted response |
| `getList(path)` | GET expecting JSON array response |
| `postForm(path, fields)` | POST form-urlencoded (not encrypted) |

### AuthService

**File:** `auth_service.dart`

```dart
final auth = AuthService(client);
bool ok = await auth.login('admin', 'admin');
// Token stored in ApiClient, encryption key derived automatically
```

### EncryptionService

**File:** `encryption_service.dart`

```dart
// Derive AES-256 key from JWT
Uint8List key = EncryptionService.deriveKey(jwt);

// Encrypt/decrypt with raw key bytes
Map<String, String> enc = EncryptionService.encrypt(plaintext, key);
String plain = EncryptionService.decrypt(enc, key);
```

Uses AES-256-GCM via PointyCastle. IV is 12 random bytes per call.

### BackendConnectionService

**File:** `backend_service.dart`

Manages connection lifecycle:

1. `loadSavedUrl()` — load previously saved URL from SharedPreferences
2. `tryConnect(url)` — ping server root endpoint
3. `autoDetect()` — try common ports (4464, 8000, 8080)
4. `login(username, password)` — plain POST to `/token` → returns JWT
5. `startMonitoring()` — heartbeat every 5s via `/health` + `/users/me`
6. `disconnect()` — clear state, stop monitoring

### OnboardingPasskey

**File:** `backend_service.dart`

Carries initial connection credentials from backend QR/passkey:

```dart
OnboardingPasskey {
  String host,       // e.g. "192.168.1.100"
  int port,         // e.g. 8000
  String username,  // e.g. "admin"
  String password,  // e.g. "admin"
  bool encryptionAvailable,  // always true
}
```

Decoded from base64. Used to auto-fill connection form.

## Connection Flow

```
┌─────────────────────────────────────────────────────┐
│ 1. App starts                                        │
│    ├─ Load saved URL from SharedPreferences          │
│    └─ If found → tryConnect() → if OK → monitor     │
│                                                      │
│ 2. Connect Screen                                    │
│    ├─ Auto-detect on common ports                    │
│    ├─ Manual entry (host + port)                     │
│    ├─ QR scan (URL or passkey)                       │
│    └─ Paste passkey                                  │
│                                                      │
│ 3. Connection Verified                               │
│    ├─ Show server info (name, version, status)       │
│    └─ Show login form (username + password)          │
│                                                      │
│ 4. Login                                             │
│    ├─ POST /token with credentials (plain HTTP)      │
│    ├─ On success → JWT stored                        │
│    ├─ ApiClient.setToken(jwt) → AES key derived      │
│    └─ Navigate to settings screen                    │
│                                                      │
│ 5. Normal Operation                                  │
│    ├─ All API calls encrypted with AES-256-GCM       │
│    ├─ JWT in Authorization: Bearer header            │
│    ├─ Health monitor runs every 5s                   │
│    ├─ On 401 with "Token superseded by another       │
│    │  login" → another session logged in as you     │
│    └─ On 401 → disconnect → show connect screen     │
└─────────────────────────────────────────────────────┘
```

## Key Files

| File | Purpose |
|---|---|
| `lib/services/api_service/api_client.dart` | HTTP client with automatic JWT-derived AES-256-GCM |
| `lib/services/encryption_service.dart` | AES-256-GCM + SHA-256 key derivation |
| `lib/services/backend_service.dart` | Connection lifecycle, login, health monitoring |
| `lib/onboarding_screens/connect_screen.dart` | Connection UI with auto-detect, QR, manual entry |
| `lib/main.dart` | App entry, wire up services |
| `lib/settings/settings_screen.dart` | Connection, providers, security management |

## Dependencies

```yaml
dependencies:
  http: ^1.2.0
  pointycastle: ^3.9.1     # AES-256-GCM + SHA-256
  shared_preferences: ^2.2.0
  mobile_scanner: ^6.0.2   # QR camera scanning
  file_picker: ^11.0.2     # QR image loading
  zxing2: ^0.2.4           # QR decode from image
```

## Security Notes

- **JWT is never persisted** — in-memory only. On app restart, user re-logs in.
- **Token TTL**: 30s to 10min (configurable via backend settings).
- **Single-session**: each login bumps the token version. Only the latest session is valid — previous ones get 401 on next request.
- **Backend URL** is stored in SharedPreferences (plain text — low risk, just a LAN address).
- **Passkey** is base64-encoded (not encrypted) but provides minimal exposure: host + default credentials.
- **Encryption key** changes every time the JWT changes (login or token refresh).
- No TLS required for the encrypted payload tier — AES-256-GCM provides confidentiality and integrity at the application layer.
