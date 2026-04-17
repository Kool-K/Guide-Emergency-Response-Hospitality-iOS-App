import SwiftUI

/// A prominent dialer sheet shown on Simulator where `tel:` URLs can't open.
/// On a real iPhone, the native Phone app opens instead.
struct SimulatorDialerView: View {
    let number: String
    let label: String
    @Binding var isPresented: Bool
    @State private var callSimulated = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 28) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.success.opacity(0.12))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "phone.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.success)
                }
                
                // Label
                Text(label)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                // Number
                Text(number)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .tracking(4)
                
                // Explanation
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(Theme.warning)
                        Text("Simulator Limitation")
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.warning)
                    }
                    
                    Text("The Phone app is not available on the iOS Simulator.\nOn a real iPhone, tapping this button opens the keypad with **\(number)** pre-dialed — you just press Call.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding()
                .liquidGlass(cornerRadius: 16)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Simulate call button
                if callSimulated {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.success)
                        Text("Call would connect on real device")
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.success)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.4)) {
                            callSimulated = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "phone.fill")
                            Text("Simulate Call to \(number)")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.success)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Theme.success.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer().frame(height: 30)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}
