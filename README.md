# Guide: Crisis Management & Emergency Response 🛡️

**Guide** is a comprehensive, native SwiftUI application for iOS/iPadOS built to modernize hotel emergency response and crisis management. It leverages a cloud backend for instant real-time synchronization, and **Google Gemini AI** to power an automated emergency safety assistant.

## ✨ Core Features

### Guest Dashboard
- **SOS Panic Button**: Instantly ping hotel security with real-time location.
- **Hotel Evacuation Blueprints**: View high-res, zoomable, and interactive hotel blueprints updated digitally by management.
- **Smart Safety Assistant**: Ask "Guide" anywhere, anytime. Powered by Gemini, the assistant dynamically reads the latest hotel instructions/docs to recommend the fastest path to safety.
- **Safety Inbox**: Get instant, non-intrusive push notifications for important but non-critical staff instructions. 

### Staff Dashboard
- **Active Emergency Monitoring**: Instantly view active distress signals across the hotel.
- **Critical Broadcast System**: Push global, red-alert notifications that break through DND modes to instantly alert all guests logged into the app.
- **Blueprint Management**: Simply take a photo of the newest emergency evacuation procedure via the gallery and beam it instantly to every guest screen.
- **Quick Actions & Issue Tracking**: Log, manage, and delete custom complaints/incidents natively within the app.

---

## 🚀 How to Run Locally

You must configure your local environment API keys before launching the app in Xcode or Swift Playgrounds. 

### 1. Configure Environment Variables
1. Duplicate the template configuration file in your terminal:
   ```bash
   cp Sources/Guide/Config.template.swift Sources/Guide/Config.swift
   ```
2. Open `Sources/Guide/Config.swift`.
3. Replace the placeholder Supabase URL and Anon Key with your real environment keys.
4. Replace the Gemini API Key string with your latest Google AI Studio key.

### 2. Build & Launch
1. Open the project folder (`Guide.swiftpm`) directly within Xcode or Swift Playgrounds.
2. Select an iOS simulator profile (an iPhone 15 Pro or iPad Pro is recommended to best visualize the responsive layout).
3. Select `Product > Run` (CMD + R).
4. Tap **Guest Login** or **Staff Login** to test the specific dashboards!
