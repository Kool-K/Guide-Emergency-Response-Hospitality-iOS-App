import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: UserSession
    
    var body: some View {
        Group {
            if session.isAuthenticated {
                TabView {
                    switch session.role {
                    case .guest:
                        GuestDashboardView()
                            .tabItem {
                                Label("Home", systemImage: "house.fill")
                            }
                    case .staff:
                        StaffDashboardView()
                            .tabItem {
                                Label("Home", systemImage: "house.fill")
                            }
                    }
                }
                .tint(Theme.primaryAccent)
            } else {
                SignInView()
            }
        }
        .animation(.easeInOut, value: session.isAuthenticated)
    }
}
