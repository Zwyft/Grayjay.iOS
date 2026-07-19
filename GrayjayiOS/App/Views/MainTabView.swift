import SwiftUI

enum Tab: String, CaseIterable {
    case home = "Home"
    case subscriptions = "Subs"
    case playlists = "Library"
    case downloads = "Offline"
    case settings = "Config"
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            
            // Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .subscriptions:
                    Color.clear // Placeholder
                case .playlists:
                    Color.clear
                case .downloads:
                    Color.clear
                case .settings:
                    SourcesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 60) // Space for custom tab bar
            
            // Minimalist Custom Tab Bar
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: selectedTab == tab ? .bold : .medium, design: .rounded))
                                .foregroundColor(selectedTab == tab ? .white : .gray.opacity(0.6))
                            
                            if selectedTab == tab {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 4, height: 4)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(
                Rectangle()
                    .fill(Color(white: 0.05))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
            )
            .ignoresSafeArea(.all, edges: .bottom)
        }
    }
}
