import SwiftUI
import UIKit

// MARK: - Zoomable Image View (UIScrollView-backed for reliable pinch-to-zoom)

/// Wraps UIScrollView for native, buttery-smooth pinch-to-zoom and pan.
/// Double-tap toggles between 1× and 3× zoom. Supports 1×–6× range.
struct ZoomableImageView: UIViewRepresentable {
    let uiImage: UIImage

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 6.0
        scrollView.minimumZoomScale = 1.0
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear

        // ImageView sized to the actual image pixels — scroll view handles the rest
        let imageView = UIImageView(image: uiImage)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        scrollView.addSubview(imageView)

        context.coordinator.imageView = imageView
        context.coordinator.scrollView = scrollView

        // Double-tap to toggle zoom
        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let imageView = context.coordinator.imageView else { return }
        let boundsSize = scrollView.bounds.size
        guard boundsSize.width > 0, boundsSize.height > 0 else { return }

        let imageSize = uiImage.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        // Set imageView to actual image size (scroll view will scale it)
        imageView.frame = CGRect(origin: .zero, size: imageSize)
        scrollView.contentSize = imageSize

        // Calculate the scale that fits the image perfectly in the view
        let scaleW = boundsSize.width / imageSize.width
        let scaleH = boundsSize.height / imageSize.height
        let fitScale = min(scaleW, scaleH)

        // Only reconfigure zoom scales when layout changes (avoid resetting user zoom)
        if context.coordinator.lastBoundsSize != boundsSize {
            context.coordinator.lastBoundsSize = boundsSize

            scrollView.minimumZoomScale = fitScale
            scrollView.maximumZoomScale = max(fitScale * 6, 3.0)
            scrollView.zoomScale = fitScale
        }

        centerImage(in: scrollView)
    }

    static func centerImage(in scrollView: UIScrollView) {
        guard let imageView = scrollView.subviews.first as? UIImageView else { return }
        let boundsSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize
        let zoomScale = scrollView.zoomScale

        let scaledW = contentSize.width * zoomScale
        let scaledH = contentSize.height * zoomScale

        let offsetX = max((boundsSize.width - scaledW) / 2, 0)
        let offsetY = max((boundsSize.height - scaledH) / 2, 0)

        imageView.frame.origin = CGPoint(x: offsetX, y: offsetY)
    }

    private func centerImage(in scrollView: UIScrollView) {
        ZoomableImageView.centerImage(in: scrollView)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: ZoomableImageView
        weak var imageView: UIImageView?
        weak var scrollView: UIScrollView?
        var lastBoundsSize: CGSize = .zero

        init(_ parent: ZoomableImageView) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            ZoomableImageView.centerImage(in: scrollView)
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = scrollView else { return }

            if scrollView.zoomScale > scrollView.minimumZoomScale + 0.01 {
                // Zoom out to fit
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                // Zoom in to 3× at the tapped point
                let location = gesture.location(in: imageView)
                let targetScale = min(scrollView.minimumZoomScale * 3, scrollView.maximumZoomScale)
                let size = CGSize(
                    width: scrollView.bounds.width / targetScale,
                    height: scrollView.bounds.height / targetScale
                )
                let origin = CGPoint(
                    x: location.x - size.width / 2,
                    y: location.y - size.height / 2
                )
                scrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
            }
        }
    }
}

struct GuestDashboardView: View {
    @EnvironmentObject var session: UserSession
    @StateObject private var locationManager = LocationManager()
    @State private var showingAssistant = false
    @State private var showingMessageSheet = false
    @State private var showingReportIssue = false
    @State private var showingInbox = false
    @State private var showingIssueFeedback = false
    @State private var issueFeedbackMessage = ""
    @State private var issueText = ""
    @State private var roomNumber = ""
    @State private var activeAlerts: [BroadcastAlert] = []
    @State private var inboxMessages: [InboxMessage] = []
    @State private var unreadCount = 0
    @State private var sosPressed = false
    @State private var toastData: ToastData?
    @State private var showingBlueprint = false
    @State private var blueprintBase64: String? = nil
    @State private var showingDialerSheet = false
    @State private var pendingCallNumber = ""
    @State private var pendingCallLabel = ""
    
    // India emergency numbers
    let EMERGENCY_112 = "112"
    let FIRE_NUMBER = "101"
    let POLICE_NUMBER = "100"
    let MEDICAL_NUMBER = "102"
    
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Animated background
                AnimatedMeshBackground(primaryColor: Theme.primaryAccent)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // SOS Button
                        sosButton
                            .padding(.top, 50)
                        
                        // Emergency quick-call row
                        emergencyCallRow
                        
                        // Action buttons
                        actionButtons
                        
                        Spacer(minLength: 40)
                    }
                }
                
                // Alert banner overlay
                if let criticalAlert = activeAlerts.first(where: { $0.isCritical }) {
                    AlertBanner(message: criticalAlert.message, isCritical: criticalAlert.isCritical)
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("Welcome, Guest")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button(action: { session.logout() }) {
                HStack(spacing: 4) {
                    Text("Log Out")
                        .font(.subheadline)
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
                .foregroundColor(Theme.primaryAccent)
            })
            .sheet(isPresented: $showingBlueprint) {
                blueprintSheet
            }
            .sheet(isPresented: $showingInbox) {
                inboxSheet
            }
            .sheet(isPresented: $showingMessageSheet) {
                MessageComposeView(
                    recipients: [EMERGENCY_112],
                    body: emergencySMSBody,
                    isPresented: $showingMessageSheet,
                    onComplete: { sent in
                        if sent {
                            toastData = ToastData(message: "📍 Location shared with emergency contacts", style: .success)
                        }
                    }
                )
            }
            .sheet(isPresented: $showingDialerSheet) {
                SimulatorDialerView(
                    number: pendingCallNumber,
                    label: pendingCallLabel,
                    isPresented: $showingDialerSheet
                )
            }
            .alert("Report Issue", isPresented: $showingReportIssue) {
                TextField("Room Number (Required)", text: $roomNumber)
                TextField("Describe the issue...", text: $issueText)
                Button("Submit") {
                    guard !roomNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        toastData = ToastData(message: "✗ Room Number is required", style: .error)
                        return
                    }
                    Task {
                        do {
                            try await SupabaseService.shared.reportGuestIssue(description: issueText, roomNumber: roomNumber)
                            DispatchQueue.main.async {
                                toastData = ToastData(message: "✓ Issue reported to staff successfully", style: .success)
                                issueText = ""
                                roomNumber = ""
                            }
                        } catch {
                            DispatchQueue.main.async {
                                toastData = ToastData(message: "✗ Failed to report issue: \(error.localizedDescription)", style: .error)
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    issueText = ""
                    roomNumber = ""
                }
            } message: {
                Text("Please mention your room number and describe the issue.")
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
        .onAppear {
            NotificationManager.shared.requestAuthorization()
            locationManager.requestLocation()
            fetchAlerts()
            fetchInboxMessages()
        }
        .onReceive(timer) { _ in
            fetchAlerts()
            fetchInboxMessages()
        }
    }
    
    // MARK: - Emergency SMS body with location
    
    private var emergencySMSBody: String {
        let lat = locationManager.location?.latitude ?? 0
        let lng = locationManager.location?.longitude ?? 0
        return """
        🚨 EMERGENCY SOS — I need immediate help!
        
        📍 My Location:
        https://maps.apple.com/?ll=\(lat),\(lng)
        
        Coordinates: \(String(format: "%.6f", lat)), \(String(format: "%.6f", lng))
        
        Sent via Guide Crisis App
        """
    }
    
    // MARK: - SOS Button
    
    private var sosButton: some View {
        Button(action: triggerSOS) {
            ZStack {
                // Outer pulsing glow
                Circle()
                    .fill(Theme.destructive.opacity(0.15))
                    .frame(width: 270, height: 270)
                    .pulsingGlow(color: Theme.destructive, radius: 30)
                
                // Glass ring
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 250, height: 250)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                
                // Main button
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.destructive, Theme.destructive.opacity(0.85)],
                            center: .center, startRadius: 0, endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 220)
                    .shadow(color: Theme.destructive.opacity(0.5), radius: sosPressed ? 25 : 15, x: 0, y: 8)
                    .scaleEffect(sosPressed ? 0.92 : 1.0)
                
                VStack(spacing: 6) {
                    Text("SOS")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("TAP FOR HELP")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(2)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: sosPressed)
    }
    
    // MARK: - Emergency Call Row
    
    private var emergencyCallRow: some View {
        HStack(spacing: 20) {
            emergencyButton(icon: "flame.fill", title: "Fire", tel: FIRE_NUMBER)
            emergencyButton(icon: "shield.fill", title: "Police", tel: POLICE_NUMBER)
            emergencyButton(icon: "cross.case.fill", title: "Medical", tel: MEDICAL_NUMBER)
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 14) {
            // Inbox button
            Button(action: {
                showingInbox = true
                fetchInboxMessages()
            }) {
                HStack {
                    Label("Inbox", systemImage: "bell.fill")
                        .font(.body.weight(.medium))
                    Spacer()
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.destructive)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .foregroundColor(.primary)
                .liquidGlass(cornerRadius: 16)
            }
            
            // Notify Emergency Contacts
            Button(action: { showingMessageSheet = true }) {
                HStack {
                    Label("Alert Authorities", systemImage: "exclamationmark.shield.fill")
                        .font(.body.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .foregroundColor(.primary)
                .liquidGlass(cornerRadius: 16)
            }
            
            // Report Issue
            Button(action: { showingReportIssue = true }) {
                HStack {
                    Label("Report Issue to Staff", systemImage: "exclamationmark.bubble.fill")
                        .font(.body.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .foregroundColor(.primary)
                .liquidGlass(cornerRadius: 16)
            }
            // View Hotel Blueprint
            Button(action: { showingBlueprint = true }) {
                HStack {
                    Label("View Hotel Blueprint", systemImage: "map.fill")
                        .font(.body.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .foregroundColor(.primary)
                .liquidGlass(cornerRadius: 16)
            }
            
            // Open Context Maps
            Button(action: {
                if let url = URL(string: "maps://") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Label("Open Maps", systemImage: "location.viewfinder")
                        .font(.body.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .foregroundColor(.primary)
                .liquidGlass(cornerRadius: 16)
            }
            
            // Smart Assistant
            NavigationLink(destination: SmartAssistantView(), isActive: $showingAssistant) {
                Button(action: { showingAssistant = true }) {
                    HStack {
                        Label("Smart Safety Assistant", systemImage: "sparkles")
                            .font(.body.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
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
        }
        .padding(.horizontal, 28)
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

    // MARK: - Inbox Sheet
    
    private var inboxSheet: some View {
        NavigationView {
            Group {
                if inboxMessages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No messages yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Broadcasts from staff will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(inboxMessages) { message in
                        HStack(spacing: 12) {
                            // Priority indicator
                            Circle()
                                .fill(message.isRead ? Color.clear : Theme.info)
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(message.message)
                                    .font(.body)
                                    .fontWeight(message.isRead ? .regular : .semibold)
                                    .foregroundColor(.primary)
                                if let createdAt = message.createdAt {
                                    Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            var readIds = UserDefaults.standard.array(forKey: "readAlerts") as? [String] ?? []
                            readIds.append(message.id.uuidString)
                            UserDefaults.standard.set(readIds, forKey: "readAlerts")
                            fetchInboxMessages()
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showingInbox = false }
                }
            }
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchAlerts() {
        Task {
            do {
                let alerts = try await SupabaseService.shared.fetchActiveAlerts()
                DispatchQueue.main.async {
                    if let newAlert = alerts.first, self.activeAlerts.first?.id != newAlert.id {
                        if newAlert.isCritical {
                            NotificationManager.shared.scheduleNotification(title: "CRITICAL ALERT", subtitle: newAlert.message)
                        } else {
                            NotificationManager.shared.scheduleNotification(title: "New Message from Staff", subtitle: newAlert.message)
                        }
                    }
                    self.activeAlerts = alerts
                }
            } catch {
                print("Failed to fetch alerts: \(error)")
            }
        }
    }
    
    private func fetchInboxMessages() {
        Task {
            do {
                let alerts = try await SupabaseService.shared.fetchActiveAlerts()
                let readIds = UserDefaults.standard.array(forKey: "readAlerts") as? [String] ?? []
                
                // Show ALL alerts in inbox (both critical and non-critical)
                let messages = alerts.map { alert in
                    InboxMessage(
                        id: alert.id,
                        userId: UUID(),
                        alertId: alert.id,
                        message: alert.message,
                        isRead: readIds.contains(alert.id.uuidString),
                        createdAt: alert.createdAt
                    )
                }
                
                DispatchQueue.main.async {
                    self.inboxMessages = messages
                    self.unreadCount = messages.filter { !$0.isRead }.count
                }
            } catch {
                print("Failed to fetch alerts for inbox: \(error)")
                DispatchQueue.main.async {
                    if self.inboxMessages.isEmpty {
                        toastData = ToastData(message: "Unable to load messages. Check connection.", style: .error)
                    }
                }
            }
        }
    }
    
    // MARK: - SOS Action
    
    private func triggerSOS() {
        guard let loc = locationManager.location, let userIdString = session.userId, let userId = UUID(uuidString: userIdString) else {
            // If no location, still try to call
            toastData = ToastData(message: "📍 Acquiring location… Please enable Location Services", style: .warning)
            initiateEmergencyCall(EMERGENCY_112, label: "Emergency")
            return
        }
        
        withAnimation {
            sosPressed = true
        }
        
        Task {
            do {
                // 1. Create SOS record with location
                let _ = try await SupabaseService.shared.createSOSRecord(
                    userId: userId,
                    latitude: loc.latitude,
                    longitude: loc.longitude,
                    voiceNoteUrl: nil
                )
                
                // 2. Broadcast distress signal for staff visibility
                try await SupabaseService.shared.broadcastDistressSignal(lat: loc.latitude, lng: loc.longitude, userId: userId)
                
                // 3. Send emergency notification
                NotificationManager.shared.scheduleNotification(
                    title: "🚨 SOS ACTIVATED",
                    subtitle: "Guest needs immediate help at: \(String(format: "%.4f", loc.latitude)), \(String(format: "%.4f", loc.longitude))",
                    isCritical: true
                )
                
                DispatchQueue.main.async {
                    // 4. Show success toast
                    toastData = ToastData(message: "🚨 SOS sent — calling emergency services", style: .warning)
                    
                    // 5. Open phone dialer with emergency number
                    initiateEmergencyCall(EMERGENCY_112, label: "Emergency Services")
                    
                    // 6. After a short delay, show SMS composer for location sharing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showingMessageSheet = true
                    }
                    
                    withAnimation {
                        sosPressed = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    toastData = ToastData(message: "SOS record failed — still calling emergency", style: .error)
                    initiateEmergencyCall(EMERGENCY_112, label: "Emergency Services")
                    withAnimation {
                        sosPressed = false
                    }
                }
            }
        }
    }
    
    // MARK: - Phone Dialer
    
    private func initiateEmergencyCall(_ number: String, label: String) {
        if let url = URL(string: "tel:\(number)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Simulator: show dialer sheet with the number
            pendingCallNumber = number
            pendingCallLabel = label
            showingDialerSheet = true
        }
    }
    
    // MARK: - Emergency Button
    
    private func emergencyButton(icon: String, title: String, tel: String) -> some View {
        Button(action: {
            initiateEmergencyCall(tel, label: title)
        }) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 0.8)
                        )
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(Theme.destructive)
                }
                .shadow(color: Theme.destructive.opacity(0.15), radius: 8, x: 0, y: 4)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
                
                Text(tel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .liquidGlass(cornerRadius: 18)
        }
    }
}
