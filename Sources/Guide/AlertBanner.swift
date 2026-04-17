import SwiftUI

struct AlertBanner: View {
    let message: String
    var isCritical: Bool = false
    @State private var flashTarget = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: isCritical ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                    .font(isCritical ? .title2 : .body)
                
                Text(isCritical ? "CRITICAL ALERT" : "EMERGENCY ALERT")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Spacer()
                
                if isCritical {
                    Text("LIVE")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.25))
                        .clipShape(Capsule())
                }
            }
            
            Text(message)
                .font(.subheadline)
                .fontWeight(isCritical ? .semibold : .regular)
                .foregroundColor(.white.opacity(0.95))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isCritical
                                ? [Color.red, Color.red.opacity(0.85)]
                                : [Theme.destructive, Theme.destructive.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Glass overlay for depth
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.1))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    Color.white.opacity(isCritical && flashTarget ? 0.6 : 0.2),
                    lineWidth: isCritical ? 2 : 1
                )
        )
        .shadow(
            color: (isCritical ? Color.red : Theme.destructive).opacity(0.4),
            radius: isCritical ? 20 : 10, x: 0, y: isCritical ? 8 : 4
        )
        .padding(.horizontal, 16)
        .onAppear {
            if isCritical {
                withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    flashTarget = true
                }
            }
        }
    }
}
