import Foundation

class GeminiService: ObservableObject {
    static let shared = GeminiService()
    
    private let apiKey = Config.geminiAPIKey
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    /// Generate a smart response, optionally including a hotel blueprint image for spatial guidance.
    /// When `blueprintBase64` is provided, Gemini Vision analyses the blueprint to give
    /// location-specific evacuation directions. If the image is not a valid building plan,
    /// Gemini is instructed to ignore it and respond using its own safety knowledge.
    func generateSmartResponse(
        prompt: String,
        context: String,
        conversationHistory: [[String: Any]] = [],
        blueprintBase64: String? = nil
    ) async throws -> String {
        // Hardcoded instant responses for critical scenarios to bypass API delay/connection issues
        let lowercasedPrompt = prompt.lowercased()
        if lowercasedPrompt.contains("fire") {
            return "🔥 FIRE EMERGENCY QRF:\n1. Stay low to the ground to avoid smoke inhalation.\n2. Do NOT use elevators. Use the nearest stairwell.\n3. Feel doors with the back of your hand before opening. If hot, do not open.\n4. Exit the building and proceed to the designated assembly point.\n5. Call emergency services (112) once safe."
        } else if lowercasedPrompt.contains("earthquake") {
            return "⚠️ EARTHQUAKE QRF:\n1. DROP, COVER, and HOLD ON under a sturdy desk or table.\n2. Stay away from windows, glass, and exterior walls.\n3. Do not exit the building until shaking stops.\n4. If outdoors, move to an open area away from trees and power lines."
        } else if lowercasedPrompt.contains("evacuate") || lowercasedPrompt.contains("evacuation") {
            return "🏃 EVACUATION QRF:\n1. Remain calm. Do not gather personal belongings.\n2. Follow the illuminated exit signs to the nearest stairwell.\n3. Do not use elevators.\n4. Proceed to the outdoor assembly area and wait for staff instructions."
        } else if lowercasedPrompt.contains("ambulance") || lowercasedPrompt.contains("medical") {
            return "🚑 MEDICAL EMERGENCY QRF:\n1. Ensure the scene is safe for you and the victim.\n2. Do NOT move the injured person unless they are in immediate danger.\n3. Send someone to notify hotel staff or call (102).\n4. Apply pressure to any bleeding with a clean cloth.\n5. If trained, perform CPR if the person is unresponsive and not breathing."
        } else if lowercasedPrompt.contains("police") || lowercasedPrompt.contains("security") || lowercasedPrompt.contains("intruder") {
            return "🛡️ SECURITY EMERGENCY QRF:\n1. Move to a safe, lockable room immediately.\n2. Stay quiet and silence your phone.\n3. Barricade the door if possible.\n4. Do NOT attempt to confront the intruder.\n5. Wait for official \"All Clear\" instructions from staff."
        } else if lowercasedPrompt.contains("safety") {
            return "ℹ️ GENERAL SAFETY QRF:\nYour safety is our priority. Please review the hotel blueprint using the 'View Hotel Blueprint' button to identify your nearest exit. Always use stairs during an emergency."
        }
        
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        // Build conversation contents with history
        var contents: [[String: Any]] = []
        
        // Add conversation history
        for entry in conversationHistory {
            contents.append(entry)
        }
        
        // --- System preamble adapts based on blueprint availability ---
        let blueprintInstruction: String
        if blueprintBase64 != nil {
            blueprintInstruction = """
            An image has been attached. First, determine whether this image is a valid hotel/building \
            blueprint, floor plan, or evacuation map. \
            - If YES: Reference specific locations, exits, stairwells, and rooms visible in the \
            blueprint when answering the user's question. Provide spatially-aware directions \
            (e.g., "turn left past Room 204 toward the east stairwell"). \
            - If NO (e.g., it is a selfie, landscape, meme, or any non-blueprint image): \
            Completely IGNORE the image and answer using only your own safety knowledge. \
            Do NOT mention that an irrelevant image was provided.
            """
        } else {
            blueprintInstruction = """
            No hotel blueprint is currently available. Provide general safety guidance based \
            on your own knowledge. Advise the user to check for physical exit signs and \
            illuminated evacuation routes in the building.
            """
        }
        
        let systemPreamble = """
        You are "Guide", a calm safety assistant in a hotel crisis app.
        - Guide users to safety during emergencies (fire, earthquake, flood, security threats)
        - Provide clear, step-by-step evacuation instructions
        - Offer first aid guidance and locate exits
        - Be concise, calm, and reassuring. Keep responses under 200 words.
        - If unsure, advise calling 112 (India emergency).
        
        \(blueprintInstruction)
        """
        
        // --- Build the user message parts (text + optional image) ---
        var userParts: [[String: Any]] = []
        
        let fullPrompt: String
        if contents.isEmpty {
            // First message: include system preamble
            if context.isEmpty {
                fullPrompt = "\(systemPreamble)\n\nUser: \(prompt)"
            } else {
                fullPrompt = "\(systemPreamble)\n\nContext:\n\(context)\n\nUser: \(prompt)"
            }
        } else {
            // Follow-up: just the user message
            fullPrompt = prompt
        }
        
        userParts.append(["text": fullPrompt])
        
        // Attach blueprint image for Gemini Vision (multimodal) if available
        if let base64 = blueprintBase64, !base64.isEmpty {
            userParts.append([
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": base64
                ]
            ])
        }
        
        contents.append([
            "role": "user",
            "parts": userParts
        ])
        
        let body: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 1024
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Gemini API Error [\(httpResponse.statusCode)]: \(errorBody)")
            // Return a helpful error message directly to the Chat UI
            if httpResponse.statusCode == 400 {
                return "⚠️ API configuration error. Please check your Gemini API key in Config.swift."
            } else if httpResponse.statusCode == 403 {
                return "⚠️ API key is invalid or expired."
            } else if httpResponse.statusCode == 404 {
                return "⚠️ API endpoint missing/wrong model. The selected Gemini model might be blocked or invalid."
            } else if httpResponse.statusCode == 429 {
                return "⚠️ Too many requests. Please wait a moment."
            }
            return "⚠️ Service Error (\(httpResponse.statusCode)): \(errorBody)"
        }
        
        struct GeminiResponse: Decodable {
            struct Candidate: Decodable {
                struct Content: Decodable {
                    struct Part: Decodable {
                        let text: String
                    }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]?
        }
        
        let responseObj = try JSONDecoder().decode(GeminiResponse.self, from: data)
        return responseObj.candidates?.first?.content.parts.first?.text ?? "I couldn't generate a response. Please try again."
    }
}
