import SwiftUI

struct NotificationIndicator: View {
    var count: Int = 0
    var isCritical: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: isCritical ? "bell.badge.fill" : "bell.fill")
                .font(.title2)
                .foregroundColor(isCritical ? Theme.destructive : .blue)
            
            if count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(isCritical ? Theme.destructive : Color.blue)
                    .clipShape(Circle())
                    .offset(x: 5, y: -5)
            }
        }
    }
}

// User notification card with bell icon
struct UserNotificationCard: View {
    let user: User
    var hasUnreadNotifications: Bool = false
    var isCriticalAlert: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user.name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.black)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(user.role.capitalized)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if hasUnreadNotifications {
                    Image(systemName: isCriticalAlert ? "bell.badge.fill" : "bell.fill")
                        .foregroundColor(isCriticalAlert ? Theme.destructive : .blue)
                        .font(.title3)
                        .animation(.pulse, value: isCriticalAlert)
                }
                
                if isCriticalAlert {
                    Text("URGENT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.destructive)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

extension Animation {
    static var pulse: Animation {
        Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)
    }
}
