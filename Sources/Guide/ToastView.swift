import SwiftUI

enum ToastStyle {
    case success
    case error
    case info
    case warning
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return Theme.success
        case .error: return Theme.destructive
        case .info: return Theme.info
        case .warning: return Theme.warning
        }
    }
}

struct ToastData: Equatable {
    let id = UUID()
    let message: String
    let style: ToastStyle
    
    static func == (lhs: ToastData, rhs: ToastData) -> Bool {
        lhs.id == rhs.id
    }
}

struct ToastView: View {
    let toast: ToastData
    @Binding var isShowing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.style.icon)
                .font(.title3)
                .foregroundColor(toast.style.color)
            
            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: { 
                withAnimation(.spring(response: 0.3)) { isShowing = false }
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .liquidGlass(cornerRadius: 16)
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.spring(response: 0.3)) {
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastData?
    
    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast = toast {
                ToastView(
                    toast: toast,
                    isShowing: Binding(
                        get: { self.toast != nil },
                        set: { if !$0 { self.toast = nil } }
                    )
                )
                .padding(.top, 8)
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toast)
    }
}

extension View {
    func toast(_ toast: Binding<ToastData?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}
