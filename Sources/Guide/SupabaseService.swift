import Foundation
import Supabase

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
    }
    
    func signInAnonymously(accessCode: String) async throws -> (UserRole, UUID) {
        let userId = UUID()
        let role: UserRole
        
        if accessCode.isEmpty {
            role = .guest
        } else {
            struct AccessCodeResponse: Decodable {
                let role: UserRole
            }
            
            let response: [AccessCodeResponse] = try await client
                .from("access_codes")
                .select("role")
                .eq("code", value: accessCode)
                .execute()
                .value
            
            if let roleRow = response.first {
                role = roleRow.role
            } else {
                throw NSError(domain: "SupabaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid Access Code"])
            }
        }
        
        // Register user in the users table so FK constraints are satisfied
        try await registerSessionUser(userId: userId, role: role)
        
        return (role, userId)
    }
    
    /// Upsert a record in `public.users` for the current session.
    /// This is required because sos_records, distress_signals, etc.
    /// have FK constraints referencing users(id).
    func registerSessionUser(userId: UUID, role: UserRole) async throws {
        struct UserInsert: Encodable {
            let id: UUID
            let name: String
            let role: String
            let active: Bool
        }
        
        let user = UserInsert(
            id: userId,
            name: "\(role.rawValue.capitalized) User",
            role: role.rawValue,
            active: true
        )
        
        try await client
            .from("users")
            .upsert(user)
            .execute()
    }
    
    func broadcastDistressSignal(lat: Double, lng: Double, userId: UUID) async throws {
        struct SignalInsert: Encodable {
            let user_id: UUID
            let latitude: Double
            let longitude: Double
            let status: String
        }
        let signal = SignalInsert(user_id: userId, latitude: lat, longitude: lng, status: "active")
        
        try await client
            .from("distress_signals")
            .insert(signal)
            .execute()
    }
    
    func fetchBlueprintsText() async throws -> String {
        let data = try await client.storage
            .from("blueprints")
            .download(path: "manual.txt")
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func broadcastAlert(message: String, isCritical: Bool) async throws -> Int {
        struct AlertInsert: Encodable {
            let message: String
            let is_active: Bool
            let is_critical: Bool
        }
        let alert = AlertInsert(message: message, is_active: true, is_critical: isCritical)
        
        try await client
            .from("broadcast_alerts")
            .insert(alert)
            .execute()
        
        // Fetch active users count to return
        let activeUsers = try await fetchActiveUsers()
        return activeUsers.count
    }
    
    func fetchActiveAlerts() async throws -> [BroadcastAlert] {
        return try await client
            .from("broadcast_alerts")
            .select()
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func deleteBroadcastAlert(id: UUID) async throws {
        try await client
            .from("broadcast_alerts")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    func reportGuestIssue(description: String, severity: String = "Normal", roomNumber: String) async throws {
        struct IssueInsert: Encodable {
            let description: String
            let severity: String
            let room_number: String
        }
        let issue = IssueInsert(description: description, severity: severity, room_number: roomNumber)
        
        try await client
            .from("guest_issues")
            .insert(issue)
            .execute()
    }
    
    func deleteGuestIssue(id: UUID) async throws {
        try await client
            .from("guest_issues")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    func fetchGuestIssues() async throws -> [GuestIssue] {
        return try await client
            .from("guest_issues")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func fetchActiveUsers() async throws -> [User] {
        return try await client
            .from("users")
            .select()
            .eq("active", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func addToInbox(alertId: UUID, message: String) async throws {
        struct InboxInsert: Encodable {
            let alert_id: UUID
            let user_id: UUID
            let message: String
            let is_read: Bool
        }
        
        // Fetch all active users and add inbox messages for each
        let users = try await fetchActiveUsers()
        for user in users {
            let inboxItem = InboxInsert(alert_id: alertId, user_id: user.id, message: message, is_read: false)
            try await client
                .from("inbox_messages")
                .insert(inboxItem)
                .execute()
        }
    }
    
    func fetchInboxMessages(userId: UUID) async throws -> [InboxMessage] {
        let userIdStr = userId.uuidString
        print("Fetching inbox for user: \(userIdStr)")
        
        let messages: [InboxMessage] = try await client
            .from("inbox_messages")
            .select()
            .eq("user_id", value: userIdStr)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("Fetched \(messages.count) inbox messages for user \(userIdStr)")
        return messages
    }
    
    func markMessageAsRead(messageId: UUID) async throws {
        struct MessageUpdate: Encodable {
            let is_read: Bool
        }
        
        try await client
            .from("inbox_messages")
            .update(MessageUpdate(is_read: true))
            .eq("id", value: messageId.uuidString)
            .execute()
    }
    
    // Send in-app message with guaranteed delivery
    func sendAppMessage(from senderId: UUID, to recipientId: UUID, message: String, messageType: String = "text") async throws {
        struct MessageInsert: Encodable {
            let sender_id: UUID
            let recipient_id: UUID
            let message: String
            let message_type: String
            let is_read: Bool
        }
        
        let appMessage = MessageInsert(
            sender_id: senderId,
            recipient_id: recipientId,
            message: message,
            message_type: messageType,
            is_read: false
        )
        
        try await client
            .from("app_messages")
            .insert(appMessage)
            .execute()
    }
    
    // Fetch app messages for user
    func fetchAppMessages(userId: UUID) async throws -> [AppMessage] {
        let userIdStr = userId.uuidString
        return try await client
            .from("app_messages")
            .select()
            .eq("recipient_id", value: userIdStr)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    // Mark app message as read
    func markAppMessageAsRead(messageId: UUID) async throws {
        struct MessageUpdate: Encodable {
            let is_read: Bool
        }
        
        try await client
            .from("app_messages")
            .update(MessageUpdate(is_read: true))
            .eq("id", value: messageId.uuidString)
            .execute()
    }
    
    // Create SOS record with location and optional voice note
    func createSOSRecord(userId: UUID, latitude: Double, longitude: Double, voiceNoteUrl: String? = nil) async throws -> SOSRecord {
        struct SOSInsert: Encodable {
            let user_id: UUID
            let latitude: Double
            let longitude: Double
            let voice_note_url: String?
            let status: String
        }
        
        let sosRecord = SOSInsert(
            user_id: userId,
            latitude: latitude,
            longitude: longitude,
            voice_note_url: voiceNoteUrl,
            status: "active"
        )
        
        let response: SOSRecord = try await client
            .from("sos_records")
            .insert(sosRecord)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    // Fetch active SOS records for staff/managers
    func fetchActiveSOSRecords() async throws -> [SOSRecord] {
        return try await client
            .from("sos_records")
            .select()
            .eq("status", value: "active")
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    // Update SOS record status
    func updateSOSRecordStatus(sosId: UUID, status: String) async throws {
        struct SOSUpdate: Encodable {
            let status: String
            let responded_at: String?
        }
        
        let now = ISO8601DateFormatter().string(from: Date())
        try await client
            .from("sos_records")
            .update(SOSUpdate(status: status, responded_at: status == "responded" ? now : nil))
            .eq("id", value: sosId.uuidString)
            .execute()
    }
    
    // Upload voice note to storage
    func uploadVoiceNote(userId: UUID, audioData: Data) async throws -> String {
        let fileName = "voicenotes/\(userId)/\(UUID().uuidString).m4a"
        
        try await client.storage
            .from("emergency_data")
            .upload(path: fileName, file: audioData, options: FileOptions(cacheControl: "3600", upsert: false))
        
        let urlPath = try await client.storage
            .from("emergency_data")
            .getPublicURL(path: fileName)
            
        return urlPath.absoluteString
    }
    
    // MARK: - Hotel Blueprints
    
    struct HotelDocument: Codable {
        let id: UUID?
        let document_name: String
        let image_base64: String
        let updated_at: String?
    }
    
    func uploadBlueprint(base64: String) async throws {
        let document = HotelDocument(
            id: UUID(),
            document_name: "evacuation_blueprint",
            image_base64: base64,
            updated_at: nil
        )
        // Clean up old ones first so we only keep the latest
        try? await client.from("hotel_documents")
            .delete()
            .eq("document_name", value: "evacuation_blueprint")
            .execute()
            
        try await client.from("hotel_documents")
            .insert(document)
            .execute()
    }
    
    func downloadBlueprint() async throws -> String? {
        let docs: [HotelDocument] = try await client.from("hotel_documents")
            .select()
            .eq("document_name", value: "evacuation_blueprint")
            .execute()
            .value
        return docs.first?.image_base64
    }
}
