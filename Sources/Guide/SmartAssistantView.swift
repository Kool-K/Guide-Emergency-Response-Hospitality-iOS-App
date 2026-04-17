import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
}

struct SmartAssistantView: View {
    @State private var inputPrompt: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading: Bool = false
    @State private var conversationHistory: [[String: Any]] = []
    @StateObject private var locationManager = LocationManager()
    private let typingID = UUID()
    
    let quickActions = [
        ("🔥", "What to do in a fire?"),
        ("🚪", "Find nearest exit"),
        ("🩹", "First aid basics"),
        ("🏃", "Evacuation route"),
    ]
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground(primaryColor: Theme.primaryAccent)
            
            VStack(spacing: 0) {
                // Chat area
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            if messages.isEmpty {
                                emptyState
                            }
                            
                            ForEach(messages) { message in
                                chatBubble(message)
                                    .id(message.id)
                            }
                            
                            if isLoading {
                                typingIndicator
                                    .id(typingID)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(messages.last?.id ?? typingID, anchor: .bottom)
                        }
                    }
                    .onChange(of: isLoading) { loading in
                        if loading {
                            withAnimation {
                                proxy.scrollTo(typingID, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Quick actions (shown when no messages)
                if messages.isEmpty {
                    quickActionsRow
                }
                
                // Input bar
                inputBar
            }
        }
        .navigationTitle("Safety Assistant")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundColor(Theme.primaryAccent.opacity(0.6))
            
            Text("Guide Assistant")
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text("Ask me about safety procedures, exits,\nevacuation routes, or first aid.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
    
    // MARK: - Chat Bubble
    
    private func chatBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: 50) }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundColor(message.isUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if message.isUser {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Theme.primaryAccent)
                            } else {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                    )
                            }
                        }
                    )
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isUser { Spacer(minLength: 50) }
        }
    }
    
    // MARK: - Typing Indicator
    
    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Theme.primaryAccent.opacity(0.5))
                        .frame(width: 7, height: 7)
                        .scaleEffect(isLoading ? 1.0 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                            value: isLoading
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
            )
            Spacer()
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(quickActions, id: \.1) { emoji, action in
                    Button(action: {
                        inputPrompt = action
                        Task { await askGemini() }
                    }) {
                        HStack(spacing: 6) {
                            Text(emoji)
                            Text(action)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .liquidGlass(cornerRadius: 20)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about safety...", text: $inputPrompt)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                )
            
            Button(action: {
                Task { await askGemini() }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(inputPrompt.isEmpty || isLoading ? .secondary : Theme.primaryAccent)
            }
            .disabled(isLoading || inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Gemini API
    
    private func askGemini() async {
        let userText = inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }
        
        // Add user message to chat
        let userMessage = ChatMessage(text: userText, isUser: true)
        DispatchQueue.main.async {
            messages.append(userMessage)
            inputPrompt = ""
            isLoading = true
        }
        
        do {
            // Fetch context (blueprints/manuals)
            var context = ""
            do {
                context = try await SupabaseService.shared.fetchBlueprintsText()
            } catch {
                print("No context available: \(error)")
            }
            
            // Include location context
            var locationContext = ""
            if let loc = locationManager.location {
                locationContext = "\nUser's current coordinates: \(String(format: "%.4f", loc.latitude)), \(String(format: "%.4f", loc.longitude))"
            }
            
            let fullContext = context + locationContext
            
            let aiResponse = try await GeminiService.shared.generateSmartResponse(
                prompt: userText,
                context: fullContext,
                conversationHistory: conversationHistory
            )
            
            // Update conversation history for multi-turn
            conversationHistory.append(["role": "user", "parts": [["text": userText]]])
            conversationHistory.append(["role": "model", "parts": [["text": aiResponse]]])
            
            let aiMessage = ChatMessage(text: aiResponse, isUser: false)
            DispatchQueue.main.async {
                messages.append(aiMessage)
                isLoading = false
            }
        } catch {
            let errorMessage = ChatMessage(text: "I'm having trouble connecting. Please check your internet and try again.", isUser: false)
            DispatchQueue.main.async {
                messages.append(errorMessage)
                isLoading = false
            }
        }
    }
}
