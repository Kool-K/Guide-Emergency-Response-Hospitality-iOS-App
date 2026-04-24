import SwiftUI

struct SignInView: View {
    @EnvironmentObject var session: UserSession
    @State private var accessCode: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showingStaffLogin: Bool = false
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedMeshBackground(primaryColor: Theme.primaryAccent)
            
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack {
                        Spacer(minLength: 40)
                        
                        // Sign-in card
                        VStack(spacing: 24) {
                            // App icon
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                    )
                                    .shadow(color: Theme.primaryAccent.opacity(0.2), radius: 20)
                                
                                Image(systemName: "shield.righthalf.filled")
                                    .font(.system(size: 40))
                                    .foregroundColor(Theme.primaryAccent)
                            }
                            
                            // Title
                            VStack(spacing: 6) {
                                Text("Guide")
                                    .font(.system(size: 42, weight: .black, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Crisis Management & Safety")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if showingStaffLogin {
                                // Staff Logic
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("STAFF ACCESS")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                        .tracking(1.5)
                                    
                                    TextField("Enter Security Code", text: $accessCode)
                                        .font(.body)
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(Color.white.opacity(0.4), lineWidth: 0.8)
                                                )
                                        )
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding(.top, 10)
                                
                                if let error = errorMessage {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.caption)
                                        Text(error)
                                            .font(.footnote)
                                    }
                                    .foregroundColor(Theme.destructive)
                                    .padding(.top, -8)
                                }
                                
                                Button(action: {
                                    Task { await handleSignIn() }
                                }) {
                                    HStack {
                                        if isLoading {
                                            ProgressView().tint(.white)
                                        } else {
                                            Text("Unlock Access")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                            Image(systemName: "lock.open.fill")
                                                .font(.subheadline)
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(LinearGradient(colors: [Theme.primaryAccent, Theme.primaryAccent.opacity(0.85)], startPoint: .leading, endPoint: .trailing))
                                    )
                                    .shadow(color: Theme.primaryAccent.opacity(0.35), radius: 12, x: 0, y: 6)
                                }
                                .disabled(isLoading || accessCode.isEmpty)
                                
                                Button(action: {
                                    withAnimation {
                                        showingStaffLogin = false
                                        errorMessage = nil
                                        accessCode = ""
                                    }
                                }) {
                                    Text("Cancel")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                            } else {
                                // Standard Selection
                                VStack(spacing: 12) {
                                    // Primary action — Guest Login
                                    Button(action: {
                                        Task { await handleSignIn() }
                                    }) {
                                        HStack(spacing: 8) {
                                            if isLoading {
                                                ProgressView().tint(.white)
                                            } else {
                                                Text("Guest Login")
                                                    .font(.headline)
                                                Spacer()
                                                Image(systemName: "arrow.right")
                                                    .font(.subheadline.weight(.semibold))
                                            }
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(LinearGradient(colors: [Theme.primaryAccent, Theme.primaryAccent.opacity(0.85)], startPoint: .leading, endPoint: .trailing))
                                        )
                                        .shadow(color: Theme.primaryAccent.opacity(0.35), radius: 12, x: 0, y: 6)
                                    }
                                    .disabled(isLoading)
                                    
                                    // Secondary action — Staff Login
                                    Button(action: {
                                        withAnimation {
                                            showingStaffLogin = true
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Text("Staff Login")
                                                .font(.headline)
                                            Spacer()
                                            Image(systemName: "lock.fill")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .foregroundColor(Theme.primaryAccent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                        .stroke(Theme.primaryAccent.opacity(0.5), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                                .padding(.top, 10)
                                
                                if let error = errorMessage {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.caption)
                                        Text(error)
                                            .font(.footnote)
                                    }
                                    .foregroundColor(Theme.destructive)
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(32)
                        .liquidGlass(cornerRadius: 28)
                        .frame(maxWidth: 450)
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                        
                        Text("Powered by Guide • Emergency Response System")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
            }
        }
    }
    
    private func handleSignIn() async {
        isLoading = true
        errorMessage = nil
        do {
            let (role, userId) = try await SupabaseService.shared.signInAnonymously(accessCode: accessCode)
            DispatchQueue.main.async {
                session.login(as: role, id: userId.uuidString)
            }
        } catch {
            DispatchQueue.main.async {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}

extension View {
    func accessibilityMinimumTapArea(_ size: CGFloat) -> some View {
        self.frame(minWidth: size, minHeight: size)
    }
}
