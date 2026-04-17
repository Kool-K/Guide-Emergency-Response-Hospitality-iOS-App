import Foundation
import UIKit
import UserNotifications
import AVFoundation

class NotificationManager {
    static let shared = NotificationManager()
    private var audioPlayer: AVAudioPlayer?
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert]) { success, error in
            if success {
                print("Notification permissions granted.")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Notification permissions error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(title: String, subtitle: String, isCritical: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.sound = isCritical ? .default : .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        // Add critical alert sound for emergency broadcasts
        if isCritical || title.contains("CRITICAL") || title.contains("SOS") {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "alarm.caf"))
            content.interruptionLevel = .critical
        }
        
        // Trigger immediately
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func playEmergencySound() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = Bundle.main.url(forResource: "alarm", withExtension: "caf") else { return }
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                self.audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.caf.rawValue)
                let player = self.audioPlayer!
                player.volume = 1.0
                player.numberOfLoops = 2
                player.play()
            } catch {
                print("Failed to play emergency sound: \(error)")
            }
        }
    }
}
