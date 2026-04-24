import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: UserSession
    
    var body: some View {
        Group {
            if session.isAuthenticated {
                // Single-role views do not need a tab bar —
                // showing a tab bar with one item is not iOS-native.
                switch session.role {
                case .guest:
                    GuestDashboardView()
                case .staff:
                    StaffDashboardView()
                }
            } else {
                SignInView()
            }
        }
        .animation(.easeInOut, value: session.isAuthenticated)
    }
}
