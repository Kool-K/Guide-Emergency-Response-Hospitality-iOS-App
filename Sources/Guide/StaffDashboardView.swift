import SwiftUI
import PhotosUI
struct StaffDashboardView: View {
    @EnvironmentObject var session: UserSession
    @State private var guestIssues: [GuestIssue] = []
    @State private var activeAlerts: [BroadcastAlert] = []
    
    @State private var showingBroadcastPrompt = false
    @State private var showingSendPrompt = false
    @State private var showingBroadcastList = false
    @State private var broadcastMessage = ""
    @State private var sendMessageText = ""
    @State private var showingIssuesSheet = false
    @State private var toastData: ToastData?
    @State private var blueprintItem: PhotosPickerItem? = nil
    @State private var showingBlueprint = false
    @State private var blueprintBase64: String? = nil
    
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background
                AnimatedMeshBackground(primaryColor: Theme.primaryAccent)
                
                VStack(spacing: 0) {
                    // Action cards
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            // Emergency Broadcast
                            Button(action: { showingBroadcastPrompt = true }) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.title3)
                                        .foregroundColor(Theme.destructive)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Emergency Broadcast")
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("Send critical evacuation/extreme alerts")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .liquidGlass(cornerRadius: 16)
                            }
                            
                            // Send to Guests
                            Button(action: { showingSendPrompt = true }) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                        .font(.title3)
                                        .foregroundColor(Theme.primaryAccent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Send to Guests")
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("Send normal instructions/welcome messages")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .liquidGlass(cornerRadius: 16)
                            }
                            // Update Blueprint
                            PhotosPicker(selection: $blueprintItem, matching: .images) {
                                HStack {
                                    Image(systemName: "map.fill")
                                        .font(.title3)
                                        .foregroundColor(Theme.primaryAccent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Update Blueprint")
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("Upload evacuation map for guests")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .liquidGlass(cornerRadius: 16)
                            }
                            
                            // View Blueprint
                            Button(action: { showingBlueprint = true }) {
                                HStack {
                                    Image(systemName: "map")
                                        .font(.title3)
                                        .foregroundColor(Theme.primaryAccent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("View Blueprint")
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("View current evacuation map")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .liquidGlass(cornerRadius: 16)
                            }
                            
                            // Open Context Maps
                            Button(action: {
                                if let url = URL(string: "maps://") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "location.viewfinder")
                                        .font(.title3)
                                        .foregroundColor(Theme.info)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Open Maps")
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("View local geographic maps")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .liquidGlass(cornerRadius: 16)
                            }
                            
                            // Guest Issues
                            Button(action: { showingIssuesSheet = true }) {
                                HStack {
                                    Image(systemName: "tray.full.fill")
                                        .font(.title3)
                                        .foregroundColor(Theme.warning)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Guest Issues")
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("Reported problems from guests")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if guestIssues.count > 0 {
                                        Text("\(guestIssues.count)")
                                            .font(.headline)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Theme.warning.opacity(0.15))
                                            .foregroundColor(Theme.warning)
                                            .clipShape(Capsule())
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .liquidGlass(cornerRadius: 16)
                            }
                            
                            // Active Broadcasts
                            Button(action: { showingBroadcastList = true }) {
                                HStack {
                                    Image(systemName: "list.bullet.rectangle.portrait.fill")
                                        .font(.title3)
                                        .foregroundColor(Theme.primaryAccent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Active Broadcasts")
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("View and remove active emergency alerts")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    let criticalCount = activeAlerts.filter { $0.isCritical }.count
                                    if criticalCount > 0 {
                                        Text("\(criticalCount)")
                                            .font(.headline)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Theme.destructive.opacity(0.15))
                                            .foregroundColor(Theme.destructive)
                                            .clipShape(Capsule())
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .liquidGlass(cornerRadius: 16)
                            }
                            
                            // Smart Assistant
                            NavigationLink(destination: SmartAssistantView()) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .font(.title3)
                                    Text("Smart Safety Assistant")
                                        .font(.body.weight(.semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    LinearGradient(
                                        colors: [Theme.primaryAccent, Theme.primaryAccent.opacity(0.85)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Theme.primaryAccent.opacity(0.3), radius: 12, x: 0, y: 6)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                        .frame(maxWidth: 600)
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Alert banner overlay
                if let criticalAlert = activeAlerts.first(where: { $0.isCritical }) {
                    AlertBanner(message: criticalAlert.message, isCritical: criticalAlert.isCritical)
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("Staff")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button(action: { session.logout() }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(Theme.primaryAccent)
            }
            .accessibilityLabel("Log Out"))
            .sheet(isPresented: $showingBroadcastPrompt) {
                NavigationView {
                    Form {
                        Section(header: Text("Critical Alert"), footer: Text("Critical alerts reach all users immediately and override their screen.")) {
                            TextField("Enter emergency message", text: $broadcastMessage, axis: .vertical)
                                .lineLimit(3...6)
                        }
                    }
                    .navigationTitle("Emergency Broadcast")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                broadcastMessage = ""
                                showingBroadcastPrompt = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Broadcast") {
                                showingBroadcastPrompt = false
                                Task {
                                    let msg = broadcastMessage
                                    broadcastMessage = ""
                                    do {
                                        let _ = try await SupabaseService.shared.broadcastAlert(message: msg, isCritical: true)
                                        DispatchQueue.main.async {
                                            toastData = ToastData(message: "✓ CRITICAL alert broadcast successfully", style: .success)
                                        }
                                    } catch {
                                        DispatchQueue.main.async {
                                            toastData = ToastData(message: "✗ Failed to broadcast: \(error.localizedDescription)", style: .error)
                                        }
                                    }
                                    fetchData()
                                }
                            }
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .disabled(broadcastMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingSendPrompt) {
                NavigationView {
                    Form {
                        Section(header: Text("Message Details"), footer: Text("Normal messages will be delivered to guest inboxes.")) {
                            TextField("Enter normal message", text: $sendMessageText, axis: .vertical)
                                .lineLimit(3...6)
                        }
                    }
                    .navigationTitle("Send to Guests")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                sendMessageText = ""
                                showingSendPrompt = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Send") {
                                showingSendPrompt = false
                                Task {
                                    let msg = sendMessageText
                                    sendMessageText = ""
                                    do {
                                        let _ = try await SupabaseService.shared.broadcastAlert(message: msg, isCritical: false)
                                        DispatchQueue.main.async {
                                            toastData = ToastData(message: "✓ Message sent to guests", style: .success)
                                        }
                                    } catch {
                                        DispatchQueue.main.async {
                                            toastData = ToastData(message: "✗ Failed to send message: \(error.localizedDescription)", style: .error)
                                        }
                                    }
                                    fetchData()
                                }
                            }
                            .fontWeight(.bold)
                            .disabled(sendMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingBroadcastList) {
                broadcastsSheet
            }
            .sheet(isPresented: $showingIssuesSheet) {
                issuesSheet
            }
            .sheet(isPresented: $showingBlueprint) {
                blueprintSheet
            }
        }
        .toast($toastData)
        .onChange(of: showingBlueprint) { isOpen in
            if isOpen {
                self.blueprintBase64 = nil
                Task {
                    do {
                        if let base64 = try await SupabaseService.shared.downloadBlueprint() {
                            DispatchQueue.main.async {
                                self.blueprintBase64 = base64
                            }
                        } else {
                            DispatchQueue.main.async {
                                toastData = ToastData(message: "Blueprint not found.", style: .error)
                                showingBlueprint = false
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            toastData = ToastData(message: "Failed to load blueprint.", style: .error)
                            showingBlueprint = false
                        }
                    }
                }
            }
        }
        .onChange(of: blueprintItem) { newItem in
            Task {
                guard let newItem = newItem else { return }
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self),
                       let originalImage = UIImage(data: data) {
                        
                        // Resize image to max 1024x1024 to prevent memory crashes
                        let maxSize: CGFloat = 1024
                        let scale = min(maxSize / originalImage.size.width, maxSize / originalImage.size.height)
                        let newSize = CGSize(width: originalImage.size.width * scale, height: originalImage.size.height * scale)
                        
                        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                        originalImage.draw(in: CGRect(origin: .zero, size: newSize))
                        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        
                        if let compressedData = resizedImage?.jpegData(compressionQuality: 0.3) {
                            let base64 = compressedData.base64EncodedString()
                            try await SupabaseService.shared.uploadBlueprint(base64: base64)
                            DispatchQueue.main.async {
                                toastData = ToastData(message: "✓ Blueprint updated successfully", style: .success)
                            }
                        } else {
                            throw URLError(.cannotDecodeRawData)
                        }
                    }
                } catch {
                    print("Blueprint upload error: \(error)")
                    DispatchQueue.main.async {
                        toastData = ToastData(message: "✗ Upload failed: \(error.localizedDescription)", style: .error)
                    }
                }
            }
        }
        .onAppear {
            NotificationManager.shared.requestAuthorization()
            fetchData()
        }
        .onReceive(timer) { _ in
            fetchData()
        }
    }
    // MARK: - Issues Sheet
    
    private var issuesSheet: some View {
        NavigationView {
            Group {
                if guestIssues.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.success)
                        Text("No reported issues")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(guestIssues) { issue in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(issue.roomNumber.flatMap { "Room \($0)" } ?? "Unknown Room")
                                        .font(.headline)
                                    Spacer()
                                    Text("Severity: \(issue.severity)")
                                        .font(.caption)
                                        .foregroundColor(issue.severity == "High" ? Theme.destructive : Theme.secondaryText)
                                }
                                Text(issue.description)
                                    .font(.body)
                                    .padding(.top, 2)
                                if let date = issue.createdAt {
                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    Task {
                                        do {
                                            try await SupabaseService.shared.deleteGuestIssue(id: issue.id)
                                            DispatchQueue.main.async {
                                                guestIssues.removeAll { $0.id == issue.id }
                                                toastData = ToastData(message: "✓ Issue resolved", style: .success)
                                            }
                                        } catch {
                                            print("Error resolving issue: \(error)")
                                        }
                                    }
                                } label: {
                                    Label("Resolve", systemImage: "checkmark")
                                }
                                .tint(Theme.success)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Guest Issues")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showingIssuesSheet = false }
                }
            }
        }
    }
    
    // MARK: - Broadcasts Sheet
    
    private var broadcastsSheet: some View {
        NavigationView {
            Group {
                let criticalAlerts = activeAlerts.filter { $0.isCritical }
                if criticalAlerts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No active broadcasts")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(activeAlerts.filter { $0.isCritical }) { alert in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    if alert.isCritical {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(Theme.destructive)
                                    } else {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(Theme.primaryAccent)
                                    }
                                    Text(alert.isCritical ? "Critical Alert" : "Normal Message")
                                        .font(.caption.bold())
                                        .foregroundColor(alert.isCritical ? Theme.destructive : Theme.primaryAccent)
                                    Spacer()
                                    if let date = alert.createdAt {
                                        Text(date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Text(alert.message)
                                    .font(.body)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        do {
                                            try await SupabaseService.shared.deleteBroadcastAlert(id: alert.id)
                                            DispatchQueue.main.async {
                                                activeAlerts.removeAll { $0.id == alert.id }
                                                toastData = ToastData(message: "✓ Broadcast removed", style: .success)
                                            }
                                        } catch {
                                            print("Error deleting broadcast: \(error)")
                                        }
                                    }
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Active Broadcasts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showingBroadcastList = false }
                }
            }
        }
    }
    
    // MARK: - Blueprint Sheet
    
    private var blueprintSheet: some View {
        NavigationView {
            Group {
                if let base64 = blueprintBase64,
                   let data = Data(base64Encoded: base64),
                   let uiImage = UIImage(data: data) {
                    ZoomableImageView(uiImage: uiImage)
                        .background(Color.black.opacity(0.05))
                } else {
                    VStack {
                        ProgressView()
                            .padding()
                        Text("Loading Blueprint...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Hotel Blueprint")
            .navigationBarItems(trailing: Button("Done") { showingBlueprint = false })
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchData() {
        Task {
            do {
                async let fetchedIssues = try? SupabaseService.shared.fetchGuestIssues()
                async let fetchedAlerts = try? SupabaseService.shared.fetchActiveAlerts()
                
                let results = await (fetchedIssues, fetchedAlerts)
                
                DispatchQueue.main.async {
                    if let issues = results.0 {
                        if issues.count > self.guestIssues.count && !self.guestIssues.isEmpty {
                            NotificationManager.shared.scheduleNotification(title: "New Guest Issue", subtitle: "A guest has reported a new issue.")
                            toastData = ToastData(message: "🆕 New guest issue reported", style: .info)
                        }
                        self.guestIssues = issues
                    }
                    if let alerts = results.1 {
                        if let newAlert = alerts.first, self.activeAlerts.first?.id != newAlert.id {
                            let title = newAlert.isCritical ? "CRITICAL ALERT" : "New Message"
                            NotificationManager.shared.scheduleNotification(title: title, subtitle: newAlert.message)
                        }
                        self.activeAlerts = alerts
                    }
                }
            }
        }
    }
}
