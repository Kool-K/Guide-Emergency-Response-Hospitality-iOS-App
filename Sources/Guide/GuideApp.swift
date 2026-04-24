import SwiftUI
import AVFoundation

@main
struct GuideApp: App {
    @StateObject private var userSession = UserSession()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSession)
                .onAppear {
                    requestAllPermissions()
                }
        }
    }
    
    private func requestAllPermissions() {
        // Request notification permissions
        NotificationManager.shared.requestAuthorization()
        
        // Request location permissions  
        DispatchQueue.main.async {
            LocationManager.shared.requestLocationPermission()
        }
        
        // Request microphone permissions (for voice notes)
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                print("Microphone permission: \(granted ? "granted" : "denied")")
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print("Microphone (Legacy) permission: \(granted ? "granted" : "denied")")
            }
        }
    }
}

