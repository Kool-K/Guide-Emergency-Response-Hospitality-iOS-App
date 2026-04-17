import Foundation
import SwiftUI

enum UserRole: String, Codable {
    case guest
    case staff
}

class UserSession: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var role: UserRole = .guest
    @Published var userId: String?
    
    func login(as role: UserRole, id: String) {
        self.role = role
        self.userId = id
        self.isAuthenticated = true
    }
    
    func logout() {
        self.role = .guest
        self.userId = nil
        self.isAuthenticated = false
        // Clear stale read state so fresh sessions see all messages
        UserDefaults.standard.removeObject(forKey: "readAlerts")
    }
}

// Representing a distress signal or incident
struct DistressSignal: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var latitude: Double
    var longitude: Double
    var status: String
    var createdAt: Date?
}

struct BroadcastAlert: Identifiable, Codable {
    var id: UUID
    var message: String
    var isActive: Bool
    var isCritical: Bool
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case message
        case isActive = "is_active"
        case isCritical = "is_critical"
        case createdAt = "created_at"
    }
}

struct GuestIssue: Identifiable, Codable {
    var id: UUID
    var description: String
    var severity: String
    var roomNumber: String?
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case description
        case severity
        case roomNumber = "room_number"
        case createdAt = "created_at"
    }
}

// User model for notification tracking
struct User: Identifiable, Codable {
    var id: UUID
    var name: String
    var role: String
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case role
        case createdAt = "created_at"
    }
}

// Track which users have seen/received alerts
struct AlertNotification: Identifiable, Codable {
    var id: UUID
    var alertId: UUID
    var userId: UUID
    var isSeen: Bool
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case alertId = "alert_id"
        case userId = "user_id"
        case isSeen = "is_seen"
        case createdAt = "created_at"
    }
}

// Inbox model for non-critical messages
struct InboxMessage: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var alertId: UUID
    var message: String
    var isRead: Bool
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case alertId = "alert_id"
        case message
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

// In-app message model for direct communication
struct AppMessage: Identifiable, Codable {
    var id: UUID
    var senderId: UUID
    var recipientId: UUID
    var message: String
    var messageType: String  // "text", "voicenote", "location"
    var isRead: Bool
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case recipientId = "recipient_id"
        case message
        case messageType = "message_type"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

// SOS Record with location and optional voicenote
struct SOSRecord: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var latitude: Double
    var longitude: Double
    var voiceNoteUrl: String?
    var status: String  // "active", "responded", "resolved"
    var createdAt: Date?
    var respondedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case latitude
        case longitude
        case voiceNoteUrl = "voice_note_url"
        case status
        case createdAt = "created_at"
        case respondedAt = "responded_at"
    }
}

