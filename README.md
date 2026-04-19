# Guide — Emergency Response & Crisis Management for Hospitality 🛡️

> **Chosen Vertical**: Hospitality & Guest Safety

**Guide** is a native iOS/iPadOS application built in **SwiftUI** that modernizes emergency response and crisis management in the hospitality industry. It provides hotel guests with instant access to life-saving tools — an SOS panic button, AI-powered safety guidance, real-time staff broadcasts, and interactive evacuation blueprints — while giving hotel staff a unified command center to manage emergencies in real time.

The app meaningfully integrates **Google Gemini 2.0 Flash (Vision)** to power a multimodal AI safety assistant that can visually analyse uploaded hotel blueprints and provide spatially-aware evacuation guidance to guests.

---

## 📋 Table of Contents

- [Chosen Vertical](#chosen-vertical)
- [How It Works](#how-it-works)
- [Approach & Logic](#approach--logic)
- [Architecture](#architecture)
- [Google Services Integration](#google-services-integration)
- [Security](#security)
- [Testing & Validation](#testing--validation)
- [Accessibility](#accessibility)
- [Assumptions](#assumptions)
- [How to Run](#how-to-run)
- [Tech Stack](#tech-stack)

---

## 🏨 Chosen Vertical

**Hospitality & Guest Safety** — Hotels serve thousands of guests who are unfamiliar with building layouts, local emergency numbers, and evacuation procedures. During a crisis (fire, earthquake, security threat), every second counts. Guide bridges this gap by putting AI-powered safety tools directly in the guest's pocket.

---

## ⚙️ How It Works

Guide operates on a **dual-role system** — Guests and Staff — each with tailored dashboards:

### 👤 Guest Dashboard
| Feature | Description |
|---|---|
| **SOS Panic Button** | One-tap alert that records the guest's live GPS, creates an SOS record in the database, broadcasts a distress signal to all staff, and initiates an emergency phone call + SMS with location |
| **Smart Safety Assistant** | AI-powered chat (Gemini 2.0 Flash Vision) that analyses the hotel's uploaded blueprint image to give spatially-aware directions (e.g., "turn left past Room 204 toward the east stairwell") |
| **Hotel Blueprint Viewer** | Zoomable, pannable view of the hotel's evacuation map uploaded by staff |
| **Emergency Quick-Call Row** | One-tap buttons for Fire (101), Police (100), and Medical (102) — India's emergency numbers |
| **Alert Authorities (SMS)** | Pre-composed SMS with live GPS coordinates sent to emergency contacts |
| **Inbox** | Real-time push notifications for staff broadcasts (critical alerts override the screen) |
| **Report Issue** | Submit safety concerns (with room number) directly to the staff dashboard |

### 🔑 Staff Dashboard
| Feature | Description |
|---|---|
| **Emergency Broadcast** | Push critical red-alert notifications that override all guest screens instantly |
| **Send to Guests** | Send non-critical informational messages to all guest inboxes |
| **Upload Blueprint** | Upload/update hotel evacuation maps directly from the photo library — the AI assistant will instantly start using the new blueprint for spatial guidance |
| **Guest Issues** | View and resolve reported guest issues with swipe-to-resolve |
| **Active Broadcasts** | Manage and remove active emergency alerts |
| **Smart Safety Assistant** | Staff also have access to the AI assistant for guidance |

> **Staff Access Code**: `STAFF123` — Use this code on the login screen to access the Staff Dashboard.

---

## 🧠 Approach & Logic

### 1. Blueprint-Aware AI (Core Innovation)

The central innovation of Guide is its **multimodal AI pipeline**:

```
Staff uploads blueprint image → Stored as base64 in Supabase (hotel_documents table)
                                        ↓
Guest opens Smart Assistant → Blueprint fetched & cached for the session
                                        ↓
Guest asks a question → Blueprint image + text prompt sent to Gemini Vision API
                                        ↓
Gemini analyses the floor plan → Returns spatially-aware evacuation directions
```

**Fallback Logic (3-tier resilience):**

| Tier | Condition | Behavior |
|------|-----------|----------|
| **Tier 1** | Blueprint uploaded AND is a valid floor plan | Gemini Vision provides directions referencing actual exits, rooms, and stairwells from the blueprint |
| **Tier 2** | No blueprint uploaded OR an unrelated image (selfie, meme, etc.) was uploaded | Gemini automatically detects it's not a blueprint, ignores the image, and responds using its own general safety knowledge |
| **Tier 3** | API unreachable / network failure | Hardcoded Quick Response Fallbacks (QRF) provide instant life-saving advice for fire, earthquake, medical, security, and evacuation scenarios — zero latency, zero dependency |

### 2. Zero-Latency QRF (Quick Response Fallbacks)

For the six most critical emergency keywords (`fire`, `earthquake`, `evacuate`, `medical`, `security`, `safety`), Guide returns **hardcoded expert responses instantly** — without waiting for any API call. This ensures guests receive life-saving instructions even during network outages or API degradation.

### 3. Real-Time Data Synchronization

All data (SOS records, broadcasts, blueprints, issues) flows through **Supabase** with 5-second polling intervals. When a guest triggers SOS:
1. GPS coordinates are captured via CoreLocation
2. An `sos_records` entry is created with coordinates + user ID
3. A `distress_signals` entry broadcasts the location to all staff
4. A local push notification fires on the staff dashboard
5. The phone dialer opens with 112 (India emergency)
6. An SMS composer pre-fills with a Google Maps link to the guest's location

### 4. Dual-Login Architecture

- **Guest Login** — No code needed; instant anonymous access
- **Staff Login** — Requires a property access code validated against the `access_codes` table in Supabase

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────┐
│                      SwiftUI Frontend                     │
│  ┌──────────┐  ┌──────────────┐  ┌─────────────────────┐ │
│  │ SignInView│  │GuestDashboard│  │  StaffDashboard     │ │
│  └────┬─────┘  └──────┬───────┘  └──────────┬──────────┘ │
│       │               │                     │             │
│       │        ┌──────┴───────┐              │             │
│       │        │SmartAssistant│              │             │
│       │        │    View      │              │             │
│       │        └──────┬───────┘              │             │
├───────┼───────────────┼──────────────────────┼─────────────┤
│              Service Layer (Singletons)                    │
│  ┌──────────────────┐  ┌───────────────────────────────┐  │
│  │  GeminiService   │  │      SupabaseService          │  │
│  │ (Gemini 2.0 Flash│  │  (Auth, CRUD, Storage,        │  │
│  │  Vision API)     │  │   Realtime Sync)              │  │
│  └────────┬─────────┘  └───────────┬───────────────────┘  │
├───────────┼────────────────────────┼──────────────────────┤
│           ▼                        ▼                      │
│  Google Gemini API          Supabase Backend               │
│  (generativelanguage        (PostgreSQL + Storage +        │
│   .googleapis.com)           Row Level Security)           │
└──────────────────────────────────────────────────────────┘
```

---

## 🔗 Google Services Integration

### Google Gemini 2.0 Flash (Vision) — Multimodal AI

Guide integrates the **Gemini 2.0 Flash** model via the `generativelanguage.googleapis.com` REST API for its Smart Safety Assistant:

| Capability | How It's Used |
|---|---|
| **Vision (Multimodal)** | Hotel blueprint images are sent as `inline_data` (base64 JPEG) alongside text prompts, enabling Gemini to visually interpret floor plans and provide spatially-aware evacuation guidance |
| **Multi-Turn Conversation** | Full conversation history is maintained and sent with each request for contextual follow-up questions |
| **Adaptive Prompting** | The system preamble dynamically adjusts based on whether a blueprint is available, instructing Gemini to either reference the blueprint or use general knowledge |
| **Image Validation** | Gemini is instructed to determine if the attached image is actually a building blueprint — if it's an unrelated image (selfie, landscape, etc.), it ignores the image entirely and responds with general safety guidance |

**API Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent`

---

## 🔒 Security

| Measure | Implementation |
|---|---|
| **Role-Based Access Control** | Guest vs. Staff roles enforced via access codes validated against Supabase `access_codes` table |
| **API Key Isolation** | All API keys (Gemini, Supabase) are stored in a dedicated `Config.swift` file, excluded from version control via `.gitignore` |
| **Row-Level Security** | Supabase RLS policies enforce that users can only read/write their own records |
| **Input Sanitization** | All user inputs are trimmed and validated before database insertion |
| **Secure Communication** | All API calls use HTTPS with TLS encryption |
| **Session Management** | User sessions are ephemeral (UUID-based) with clean logout that clears all local state |
| **Image Compression** | Uploaded blueprints are resized to max 1024×1024 and compressed to 30% JPEG quality to prevent memory attacks |

---

## ✅ Testing & Validation

| Test Area | Method |
|---|---|
| **SOS Flow** | End-to-end: tap SOS → verify `sos_records` + `distress_signals` created in Supabase → phone dialer opens → SMS composer with GPS coordinates |
| **Blueprint Upload** | Staff uploads image → verify `hotel_documents` table updated → Guest opens blueprint viewer → image renders correctly with zoom/pan |
| **AI Vision** | Upload a real floor plan → ask "where is the nearest exit?" → verify Gemini references specific rooms/exits from the blueprint. Upload a random photo → verify Gemini ignores it and gives general advice |
| **QRF Fallbacks** | Disconnect network → type "fire" → verify instant hardcoded response appears without delay |
| **Broadcast System** | Staff sends critical alert → verify guest screen shows red banner overlay immediately |
| **Role Validation** | Enter invalid access code → verify rejection. Enter `STAFF123` → verify staff dashboard loads |
| **Simulator Compatibility** | Emergency call buttons show a simulated dialer sheet on Simulator (since `tel:` URLs don't work) |

---

## ♿ Accessibility

| Feature | Implementation |
|---|---|
| **Large Touch Targets** | SOS button is 220pt diameter; all action buttons have minimum 16pt padding |
| **High Contrast** | Matte earthy green (`#4A6741`) and crimson red (`#C0392B`) both exceed WCAG AA contrast ratios against the light background |
| **Readable Typography** | System Dynamic Type is used throughout; all text respects the user's preferred text size |
| **Color + Icon Redundancy** | All alerts use both color AND iconography (e.g., ⚠️ + red for critical, ℹ️ + blue for info) — never color alone |
| **Pulsing Animations** | SOS button uses a pulsing glow to draw attention via motion, not just color |
| **Clear Labeling** | Every button has a descriptive text label alongside its icon |
| **Semantic Hierarchy** | Navigation titles, section headers, and body text follow a clear visual hierarchy |

---

## 📝 Assumptions

1. **Network Connectivity** — Both guest and staff devices have an active internet connection (Wi-Fi or cellular) for Supabase sync and Gemini API calls. Offline fallbacks (QRF) cover critical scenarios.
2. **Location Services** — Users grant location permission for SOS GPS tracking and emergency SMS coordinates.
3. **Staff Blueprint Upload** — Hotel staff are responsible for uploading a valid evacuation blueprint. If no blueprint is uploaded or an unrelated image is uploaded instead, the AI assistant gracefully falls back to general safety guidance.
4. **India Context** — Emergency numbers (112, 100, 101, 102) are configured for India. These can be changed in `GuestDashboardView.swift`.
5. **Single Property** — The app assumes a single hotel property per Supabase instance. Multi-property support would require tenant isolation.
6. **API Key Validity** — A valid Google Gemini API key must be configured in `Config.swift` for the AI assistant to function beyond QRF fallbacks.

---

## 🚀 How to Run

### Prerequisites
- **Xcode 15+** or **Swift Playgrounds 4.4+** (iPad/Mac)
- iOS 16.0+ deployment target
- A valid [Google AI Studio](https://aistudio.google.com/apikey) API key for Gemini
- A [Supabase](https://supabase.com) project with the required tables (see schema below)

### 1. Clone & Configure

```bash
git clone https://github.com/<your-username>/Guide.swiftpm.git
cd Guide.swiftpm
```

Open `Sources/Guide/Config.swift` and set your keys:

```swift
struct Config {
    static let supabaseURL = "https://your-project.supabase.co"
    static let supabaseAnonKey = "your-supabase-anon-key"
    static let geminiAPIKey = "your-gemini-api-key"
}
```

### 2. Supabase Schema

Create the following tables in your Supabase project:

| Table | Key Columns |
|-------|-------------|
| `access_codes` | `code` (text), `role` (text: "staff") |
| `users` | `id` (uuid PK), `name` (text), `role` (text), `active` (bool) |
| `broadcast_alerts` | `id` (uuid PK), `message` (text), `is_active` (bool), `is_critical` (bool) |
| `guest_issues` | `id` (uuid PK), `description` (text), `severity` (text), `room_number` (text) |
| `distress_signals` | `id` (uuid PK), `user_id` (uuid FK→users), `latitude` (float8), `longitude` (float8), `status` (text) |
| `sos_records` | `id` (uuid PK), `user_id` (uuid FK→users), `latitude` (float8), `longitude` (float8), `status` (text), `voice_note_url` (text nullable) |
| `hotel_documents` | `id` (uuid PK), `document_name` (text), `image_base64` (text) |
| `inbox_messages` | `id` (uuid PK), `user_id` (uuid FK→users), `alert_id` (uuid), `message` (text), `is_read` (bool) |
| `app_messages` | `id` (uuid PK), `sender_id` (uuid FK→users), `recipient_id` (uuid FK→users), `message` (text), `message_type` (text), `is_read` (bool) |

Insert the staff access code:
```sql
INSERT INTO access_codes (code, role) VALUES ('STAFF123', 'staff');
```

### 3. Build & Launch

1. Open `Guide.swiftpm` in **Xcode** or **Swift Playgrounds**
2. Select an iOS Simulator (iPhone 15 Pro recommended)
3. Press **⌘R** to build and run
4. **Guest Login** — Tap "Guest Login" (no code needed)
5. **Staff Login** — Tap "Staff Login" → enter `STAFF123` → tap "Unlock Access"

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | SwiftUI (iOS 16+), Swift 5.9 |
| **AI / ML** | Google Gemini 2.0 Flash (Vision) via REST API |
| **Backend** | Supabase (PostgreSQL, Row-Level Security, Storage) |
| **Auth** | Anonymous UUID sessions + access-code role validation |
| **Location** | CoreLocation (GPS for SOS + emergency SMS) |
| **Messaging** | MessageUI (SMS with pre-filled GPS coordinates) |
| **Notifications** | UserNotifications framework (local push) |
| **Design System** | Custom Liquid Glass (glassmorphism) + animated mesh background |

---

## 📁 Project Structure

```
Guide.swiftpm/
├── Package.swift                    # SPM manifest (Supabase dependency)
├── Sources/Guide/
│   ├── GuideApp.swift              # App entry point
│   ├── Config.swift                # API keys (gitignored)
│   ├── ContentView.swift           # Root router (SignIn vs Dashboard)
│   ├── SignInView.swift            # Dual-login (Guest / Staff)
│   ├── GuestDashboardView.swift    # Guest: SOS, calls, blueprint, inbox
│   ├── StaffDashboardView.swift    # Staff: broadcasts, issues, uploads
│   ├── SmartAssistantView.swift    # AI chat UI (multi-turn)
│   ├── GeminiService.swift         # Gemini Vision API (multimodal)
│   ├── SupabaseService.swift       # All Supabase CRUD operations
│   ├── Models.swift                # Data models & UserSession
│   ├── Theme.swift                 # Design system & Liquid Glass
│   ├── LocationManager.swift       # CoreLocation wrapper
│   ├── MessageComposeView.swift    # SMS composer (MFMessageComposeVC)
│   ├── SimulatorDialerView.swift   # Simulated phone dialer for Simulator
│   ├── AlertBanner.swift           # Critical alert overlay banner
│   ├── NotificationIndicator.swift # Unread badge component
│   ├── NotificationManager.swift   # Local push notifications
│   └── ToastView.swift             # Toast notification component
└── README.md
```

---

<p align="center">
  Built with ❤️ using <strong>SwiftUI</strong> + <strong>Google Gemini</strong> + <strong>Supabase</strong>
</p>
