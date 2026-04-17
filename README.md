# Guide: Crisis Management & Emergency Response 🛡️

**Guide** is a comprehensive, native SwiftUI application for iOS/iPadOS built to modernize hotel emergency response and crisis management. It leverages **Supabase** backend architecture for instant real-time synchronization, and **Google Gemini AI** to power an automated emergency safety assistant.

## ✨ Core Features

### Guest & Visitor Dashboard
- **SOS Panic Button**: Instantly ping hotel security with real-time location.
- **Hotel Evacuation Blueprints**: View high-res, zoomable, and interactive hotel blueprints updated digitally by management.
- **Smart Safety Assistant**: Ask "Guide" anywhere, anytime. Powered by Gemini, the assistant dynamically reads the latest hotel instructions/docs to recommend the fastest path to safety.
- **Safety Inbox**: Get instant, non-intrusive push notifications for important but non-critical staff instructions. 

### Staff & Management Dashboard
- **Active Emergency Monitoring**: Instantly view active distress signals across the hotel.
- **Critical Broadcast System**: Push global, terrifying red-alert notifications that break through DND modes to instantly alert all guests logged into your wifi/ecosystem.
- **Blueprint Management**: Simply take a photo of the newest emergency evacuation procedure via the gallery and beam it instantly to every guest screen.
- **Quick Actions & Issue Tracking**: Log, manage, and delete custom complaints/incidents natively within the app.

---

## 🛠️ Architecture

- **Frontend**: 100% Native SwiftUI (Compatible with iOS 16+)
- **Backend**: Supabase (PostgreSQL, Storage, Realtime)
- **AI Integration**: Google Generative AI (Gemini 3 Flash API)
- **Data Transport**: Swift `URLSession` + JSON Serialization Native Hooks

---

## 🚀 Quickstart Guide

Because Guide is built with security first, you must configure your backend configurations locally before launching the `.swiftpm` module on Xcode or Playgrounds.

### 1. Database Configuration
Ensure your Supabase project contains the structural elements built for this application. You can execute the entire baseline schema directly on the Supabase SQL Editor via the included file:
```bash
# Copy and run heavily documented tables in Supabase
cat BLUEPRINT_SQL_FIX.sql 
```

### 2. Configure Environment Variables
You must **never commit your live API keys to Github**. `Config.swift` has been strictly ignored in the attached `.gitignore` profile.

To get started:
1. Duplicate the template configuration file: 
   ```bash
   cp Sources/Guide/Config.template.swift Sources/Guide/Config.swift
   ```
2. Replace `YOUR_SUPABASE_URL_HERE` and `YOUR_SUPABASE_ANON_KEY_HERE` with your Supabase keys from the Project Settings dashboard.
3. Replace `YOUR_GEMINI_API_KEY_HERE` with your live Google AI Studio API credential.

### 3. Build & Run
Open the `Guide.swiftpm` folder directly within Xcode:
```bash
open Guide.swiftpm
```
1. Select a simulator (iPhone 15 Pro / iPad Pro recommended for layout sizes).
2. Select `Product > Run (CMD + R)`.
3. Try securely logging in using the **Guest Login** button without entering a code!

---

## 🔒 Security Practices & Notes

- **.gitignore Enforcement**: The `.gitignore` prevents configuration environments (`Config.swift`) and Xcode cache structures from bleeding into standard Git history.
- **Role Isolation Constraints**: Both guest tracking and staff configurations are strictly sandboxed utilizing Supabase RLS (Row Level Security) schemas found explicitly inside the `BLUEPRINT_SQL_FIX.sql`.
- **Image Transcoding limits**: Hotel Blueprints are actively downscaled during capture on real-devices internally within `StaffDashboardView` before network propagation to guarantee 0% network memory failures against backend proxy caps.
