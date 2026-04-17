import SwiftUI
import MessageUI

struct MessageComposeView: UIViewControllerRepresentable {
    var recipients: [String]
    var body: String
    @Binding var isPresented: Bool
    var onComplete: ((Bool) -> Void)?
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var isPresented: Binding<Bool>
        var onComplete: ((Bool) -> Void)?
        
        init(isPresented: Binding<Bool>, onComplete: ((Bool) -> Void)?) {
            self.isPresented = isPresented
            self.onComplete = onComplete
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            let success = result == .sent
            controller.dismiss(animated: true) {
                self.isPresented.wrappedValue = false
                self.onComplete?(success)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, onComplete: onComplete)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        guard MFMessageComposeViewController.canSendText() else {
            // Simulator: show rich preview of what would happen on real device
            let vc = UIHostingController(rootView: SimulatorSMSPreview(
                recipients: recipients,
                messageBody: body,
                isPresented: $isPresented,
                onComplete: onComplete
            ))
            return vc
        }
        
        let controller = MFMessageComposeViewController()
        controller.recipients = recipients
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - Simulator SMS Preview

struct SimulatorSMSPreview: View {
    let recipients: [String]
    let messageBody: String
    @Binding var isPresented: Bool
    var onComplete: ((Bool) -> Void)?
    @State private var showSentAnimation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 36))
                        .foregroundColor(Theme.primaryAccent)
                    Text("SMS Preview")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Simulator — would open Messages on real device")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 16)
                
                Divider()
                
                // Recipients
                HStack {
                    Text("To:")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    ForEach(recipients, id: \.self) { recipient in
                        Text(recipient)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.primaryAccent.opacity(0.12))
                            .foregroundColor(Theme.primaryAccent)
                            .cornerRadius(12)
                    }
                    Spacer()
                }
                .padding()
                
                Divider()
                
                // Message body
                ScrollView {
                    VStack(alignment: .trailing, spacing: 8) {
                        Spacer().frame(height: 20)
                        
                        // SMS bubble
                        HStack {
                            Spacer()
                            Text(messageBody)
                                .font(.body)
                                .padding(12)
                                .background(Theme.primaryAccent)
                                .foregroundColor(.white)
                                .cornerRadius(18)
                                .frame(maxWidth: 280, alignment: .trailing)
                        }
                        .padding(.horizontal)
                        
                        // Timestamp
                        Text("Now")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.trailing, 20)
                    }
                }
                .frame(maxHeight: .infinity)
                
                Divider()
                
                // Action area
                VStack(spacing: 12) {
                    if showSentAnimation {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.success)
                            Text("Would be sent on a real iPhone")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.success)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4)) {
                            showSentAnimation = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isPresented = false
                            onComplete?(true)
                        }
                    }) {
                        Label("Simulate Send", systemImage: "paperplane.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primaryAccent)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                        onComplete?(false)
                    }
                }
            }
        }
    }
}
