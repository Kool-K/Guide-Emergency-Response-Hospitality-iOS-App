import re

with open('Sources/Guide/ManagerDashboardView.swift', 'r') as f:
    content = f.read()

# 1. State vars
content = re.sub(
    r'@State private var showingBroadcastPrompt = false\n    @State private var broadcastMessage = ""\n    @State private var broadcastIsCritical = false\n    @State private var showingIssuesSheet = false\n    @State private var showingUsersList = false\n    @State private var toastData: ToastData\?',
    '@State private var showingBroadcastPrompt = false\n    @State private var showingSendPrompt = false\n    @State private var showingBroadcastList = false\n    @State private var broadcastMessage = ""\n    @State private var sendMessageText = ""\n    @State private var showingIssuesSheet = false\n    @State private var showingUsersList = false\n    @State private var toastData: ToastData?',
    content
)

# 2. Buttons
# Replace Broadcast Alert button
content = re.sub(
    r'// Broadcast Alert\n.*?Button\(action: \{ showingBroadcastPrompt[^}]+\}\)\s*\{\s*HStack\s*\{.*?Image\(systemName: "megaphone\.fill"\).*?"Broadcast Alert".*?"Send emergency message to all users".*?liquidGlass\(cornerRadius: 16\)\n\s*\}',
    '''// Emergency Broadcast
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
                            }''',
    content, flags=re.DOTALL
)

# Replace Guest Issues down to Smart Assistant
content = re.sub(
    r'// Guest Issues\n.*?Button\(action: \{ showingIssuesSheet = true \}\)\s*\{.*?liquidGlass\(cornerRadius: 16\)\n\s*\}\n\s*// Smart Assistant',
    '''// Guest Issues
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
                                        Text("\\(guestIssues.count)")
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
                                        Text("View and remove active messages")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if activeAlerts.count > 0 {
                                        Text("\\(activeAlerts.count)")
                                            .font(.headline)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Theme.primaryAccent.opacity(0.15))
                                            .foregroundColor(Theme.primaryAccent)
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
                            
                            // Smart Assistant''',
    content, flags=re.DOTALL
)

# 3. Replace .alert("Broadcast Alert"...
content = re.sub(
    r'\.alert\("Broadcast Alert", isPresented: \$showingBroadcastPrompt\).*?Text\("Critical alerts reach all users immediately\. Non-critical messages go to inbox\."\)\n\s*\}',
    '''.alert("Emergency Broadcast", isPresented: $showingBroadcastPrompt) {
                TextField("Enter emergency message", text: $broadcastMessage)
                Button("Broadcast") {
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
                                toastData = ToastData(message: "✗ Failed to broadcast: \\(error.localizedDescription)", style: .error)
                            }
                        }
                        fetchData()
                    }
                }
                Button("Cancel", role: .cancel) { broadcastMessage = "" }
            } message: {
                Text("Critical alerts reach all users immediately and override their screen.")
            }
            .alert("Send Message to Guests", isPresented: $showingSendPrompt) {
                TextField("Enter normal message", text: $sendMessageText)
                Button("Send") {
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
                                toastData = ToastData(message: "✗ Failed to send message: \\(error.localizedDescription)", style: .error)
                            }
                        }
                        fetchData()
                    }
                }
                Button("Cancel", role: .cancel) { sendMessageText = "" }
            } message: {
                Text("Normal messages will be delivered to guest inboxes.")
            }''',
    content, flags=re.DOTALL
)

# 4. Add .sheet for broadcastList
content = re.sub(
    r'\.sheet\(isPresented: \$showingUsersList\)',
    '''.sheet(isPresented: $showingBroadcastList) {
                broadcastsSheet
            }
            .sheet(isPresented: $showingUsersList)''',
    content
)

# 5. Broadcasts Sheet definition + issues sheet updates
# I'll replace the existing issuesSheet up to Data Fetching
issues_sheet_content = '''    // MARK: - Issues Sheet
    
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
                                    Text(issue.roomNumber.flatMap { "Room \\($0)" } ?? "Unknown Room")
                                        .font(.headline)
                                    Spacer()
                                    Text("Severity: \\(issue.severity)")
                                        .font(.caption)
                                        .foregroundColor(issue.severity == "High" ? Theme.destructive : Theme.secondary)
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
                                            print("Error resolving issue: \\(error)")
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
                if activeAlerts.isEmpty {
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
                        ForEach(activeAlerts) { alert in
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
                                            print("Error deleting broadcast: \\(error)")
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
    }'''

content = re.sub(
    r'// MARK: - Issues Sheet.*?// MARK: - Data Fetching',
    issues_sheet_content + '\n    \n    // MARK: - Data Fetching',
    content, flags=re.DOTALL
)

with open('Sources/Guide/ManagerDashboardView.swift', 'w') as f:
    f.write(content)

