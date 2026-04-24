import SwiftUI

struct Theme {
    // Core palette
    static let background = Color(hex: "#F8F9FA")
    static let primaryAccent = Color(hex: "#4A6741")   // Refined earthy green
    static let destructive = Color(hex: "#C0392B")     // Refined crimson
    static let secondaryText = Color(hex: "#6B7280")
    static let cardBackground = Color.white.opacity(0.6)
    
    // Liquid glass tints
    static let glassTint = Color.white.opacity(0.18)
    static let glassBorder = Color.white.opacity(0.45)
    static let glassInnerShadow = Color.black.opacity(0.06)
    
    // Semantic colors
    static let success = Color(hex: "#27AE60")
    static let warning = Color(hex: "#F39C12")
    static let info = Color(hex: "#3498DB")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Liquid Glass Modifier

struct LiquidGlass: ViewModifier {
    var cornerRadius: CGFloat = 20
    var tint: Color = Theme.glassTint
    var shadowIntensity: CGFloat = 0.12
    var borderOpacity: CGFloat = 0.45
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.primary.opacity(borderOpacity * 0.35),
                                Color.primary.opacity(borderOpacity * 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: Color.black.opacity(shadowIntensity), radius: 20, x: 0, y: 8)
            .shadow(color: Color.black.opacity(shadowIntensity * 0.4), radius: 2, x: 0, y: 1)
    }
}

struct LiquidGlassButton: ViewModifier {
    var isProminent: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isProminent ? Theme.primaryAccent.opacity(0.15) : Theme.glassTint)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.primary.opacity(0.18),
                                Color.primary.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: Color.black.opacity(0.10), radius: 14, x: 0, y: 6)
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = 20, shadowRadius: CGFloat = 10) -> some View {
        self.modifier(LiquidGlass(cornerRadius: cornerRadius))
    }
    
    func liquidGlass(cornerRadius: CGFloat = 20, tint: Color = Theme.glassTint) -> some View {
        self.modifier(LiquidGlass(cornerRadius: cornerRadius, tint: tint))
    }
    
    func liquidGlassButton(prominent: Bool = false) -> some View {
        self.modifier(LiquidGlassButton(isProminent: prominent))
    }
}

// MARK: - Animated Background

struct AnimatedMeshBackground: View {
    @State private var animate = false
    var primaryColor: Color = Theme.primaryAccent
    
    var body: some View {
        ZStack {
            // Use Color(.systemBackground) so it adapts to dark/light mode
            Color(.systemBackground)
                .ignoresSafeArea()
            
            LinearGradient(
                colors: [
                    primaryColor.opacity(0.12),
                    Color.clear,
                    primaryColor.opacity(0.06)
                ],
                startPoint: animate ? .topLeading : .topTrailing,
                endPoint: animate ? .bottomTrailing : .bottomLeading
            )
            
            // Floating orbs — opacity is already low, looks good in both modes
            Circle()
                .fill(primaryColor.opacity(0.10))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: animate ? 50 : -50, y: animate ? -80 : 80)
            
            Circle()
                .fill(primaryColor.opacity(0.07))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: animate ? -70 : 70, y: animate ? 100 : -100)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Pulsing Glow

struct PulsingGlow: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isPulsing ? 0.6 : 0.2), radius: isPulsing ? radius : radius * 0.5)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulsingGlow(color: Color = Theme.destructive, radius: CGFloat = 20) -> some View {
        self.modifier(PulsingGlow(color: color, radius: radius))
    }
}
