import SwiftUI

struct SidebarView: View {
    @Binding var isOpen: Bool
    @Binding var selectedSection: SidebarSection
    @ObservedObject var pluginManager: PluginManager
    @State private var subscriptions: [Subscription] = []
    @State private var authPlugin: PluginConfig?
    @State private var showLogoutAlert: PluginConfig?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Sidebar Content
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    sidebarHeader
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 8) {
                            // Main Navigation Items
                            sidebarNavItem(
                                icon: "house.fill",
                                title: "Home",
                                section: .home
                            )
                            
                            sidebarNavItem(
                                icon: "music.note.tv.fill",
                                title: "Subscriptions",
                                section: .subscriptions
                            )
                            
                            // Subscribed Channels
                            if selectedSection == .subscriptions || !subscriptions.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    if subscriptions.isEmpty {
                                        Text("No subscriptions yet")
                                            .font(.caption)
                                            .foregroundColor(.gray.opacity(0.7))
                                            .padding(.leading, 52)
                                            .padding(.vertical, 4)
                                    } else {
                                        ForEach(subscriptions.prefix(5)) { sub in
                                            Button(action: {
                                                selectedSection = .subscriptions
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                                    isOpen = false
                                                }
                                            }) {
                                                HStack(spacing: 12) {
                                                    Circle()
                                                        .fill(Color.blue.opacity(0.3))
                                                        .frame(width: 28, height: 28)
                                                        .overlay(
                                                            Text(String(sub.name.prefix(1)))
                                                                .font(.system(size: 11, weight: .bold))
                                                                .foregroundColor(.blue)
                                                        )
                                                    
                                                    Text(sub.name)
                                                        .font(.system(size: 14, weight: .regular))
                                                        .foregroundColor(.white.opacity(0.85))
                                                        .lineLimit(1)
                                                    
                                                    Spacer()
                                                }
                                                .padding(.leading, 52)
                                                .padding(.vertical, 2)
                                            }
                                        }
                                        
                                        if subscriptions.count > 5 {
                                            Text("+\(subscriptions.count - 5) more")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .padding(.leading, 52)
                                                .padding(.vertical, 2)
                                        }
                                    }
                                }
                            }
                            
                            // Divider
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                            
                            // Sources Section Header
                            Text("SOURCES")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.leading, 20)
                                .padding(.bottom, 4)
                            
                            // Installed Plugins with Login/Logout
                            if pluginManager.installedPlugins.isEmpty {
                                HStack(spacing: 12) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        .frame(width: 24)
                                    
                                    Text("No sources installed")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                                .padding(.leading, 20)
                                .padding(.vertical, 8)
                            } else {
                                ForEach(pluginManager.installedPlugins) { plugin in
                                    VStack(spacing: 0) {
                                        // Source row - tap to navigate
                                        Button(action: {
                                            selectedSection = .source(plugin.id)
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                                isOpen = false
                                            }
                                        }) {
                                            HStack(spacing: 12) {
                                                // Source icon
                                                Circle()
                                                    .fill(sourceColor(for: plugin.name).opacity(0.3))
                                                    .frame(width: 32, height: 32)
                                                    .overlay(
                                                        Text(String(plugin.name.prefix(1)))
                                                            .font(.system(size: 13, weight: .bold))
                                                            .foregroundColor(sourceColor(for: plugin.name))
                                                    )
                                                
                                                Text(plugin.name)
                                                    .font(.system(size: 15, weight: selectedSection == .source(plugin.id) ? .semibold : .regular))
                                                    .foregroundColor(selectedSection == .source(plugin.id) ? .white : .white.opacity(0.85))
                                                
                                                Spacer()
                                                
                                                // Auth status + actions
                                                if plugin.savedAuth != nil {
                                                    // Logged in - show checkmark and logout option
                                                    Menu {
                                                        Button(role: .destructive, action: {
                                                            showLogoutAlert = plugin
                                                        }) {
                                                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                                        }
                                                    } label: {
                                                        HStack(spacing: 4) {
                                                            Image(systemName: "checkmark.seal.fill")
                                                                .font(.system(size: 10))
                                                                .foregroundColor(.green)
                                                            
                                                            Image(systemName: "chevron.down")
                                                                .font(.system(size: 8))
                                                                .foregroundColor(.green.opacity(0.6))
                                                        }
                                                    }
                                                } else if plugin.authConfig != nil {
                                                    // Needs login - show login button
                                                    Button(action: {
                                                        authPlugin = plugin
                                                    }) {
                                                        Text("Login")
                                                            .font(.system(size: 11, weight: .bold))
                                                            .foregroundColor(.white)
                                                            .padding(.horizontal, 10)
                                                            .padding(.vertical, 4)
                                                            .background(Color.blue.opacity(0.8))
                                                            .cornerRadius(12)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                            .padding(.leading, 20)
                                            .padding(.trailing, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedSection == .source(plugin.id) ?
                                                Color.white.opacity(0.08) : Color.clear
                                            )
                                            .cornerRadius(8)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            
                            // Available Sources (not yet installed)
                            let uninstalled = pluginManager.availableSources.filter { available in
                                !pluginManager.installedPlugins.contains(where: { $0.id == available.id })
                            }
                            
                            if !uninstalled.isEmpty {
                                Rectangle()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 1)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                
                                Text("AVAILABLE")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(.gray.opacity(0.6))
                                    .padding(.leading, 20)
                                    .padding(.bottom, 4)
                                
                                ForEach(uninstalled) { source in
                                    Button(action: {
                                        selectedSection = .source(source.id)
                                        PluginManager.shared.installPlugin(source: source)
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                            isOpen = false
                                        }
                                    }) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(sourceColor(for: source.name).opacity(0.2))
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Text(String(source.name.prefix(1)))
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(sourceColor(for: source.name).opacity(0.6))
                                                )
                                            
                                            Text(source.name)
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundColor(.white.opacity(0.5))
                                            
                                            Spacer()
                                            
                                            Image(systemName: "icloud.and.arrow.down")
                                                .font(.system(size: 11))
                                                .foregroundColor(.gray.opacity(0.5))
                                        }
                                        .padding(.leading, 20)
                                        .padding(.trailing, 16)
                                        .padding(.vertical, 6)
                                    }
                                }
                            }
                            
                            // Library
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                            
                            sidebarNavItem(
                                icon: "clock.fill",
                                title: "Library",
                                section: .library
                            )
                        }
                        .padding(.top, 8)
                    }
                }
                .frame(width: min(geometry.size.width * 0.78, 300))
                .background(
                    Color(white: 0.06)
                        .ignoresSafeArea()
                )
                
                Spacer()
            }
            .onAppear {
                loadSubscriptions()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionsUpdated"))) { _ in
                loadSubscriptions()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PluginInstalled"))) { _ in
                loadSubscriptions()
            }
            // Present auth sheet
            .sheet(item: $authPlugin) { plugin in
                AuthenticationSheet(plugin: plugin, isPresented: Binding(
                    get: { authPlugin != nil },
                    set: { if !$0 { authPlugin = nil } }
                ))
            }
            // Logout confirmation
            .alert("Logout", isPresented: Binding(
                get: { showLogoutAlert != nil },
                set: { if !$0 { showLogoutAlert = nil } }
            )) {
                Button("Logout", role: .destructive) {
                    if let plugin = showLogoutAlert {
                        PluginManager.shared.logout(pluginId: plugin.id)
                    }
                    showLogoutAlert = nil
                }
                Button("Cancel", role: .cancel) {
                    showLogoutAlert = nil
                }
            } message: {
                if let plugin = showLogoutAlert {
                    Text("Sign out of \(plugin.name)? This will remove your saved credentials.")
                }
            }
        }
    }
    
    // MARK: - Sidebar Header
    
    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        isOpen = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, safeAreaTop + 12)
            
            // App Logo / Title
            HStack(spacing: 12) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                
                Text("Grayjay")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(white: 0.08),
                    Color(white: 0.06)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Sidebar Nav Item
    
    private func sidebarNavItem(icon: String, title: String, section: SidebarSection) -> some View {
        Button(action: {
            selectedSection = section
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                isOpen = false
            }
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedSection == section ? .white : .gray)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 15, weight: selectedSection == section ? .semibold : .regular))
                    .foregroundColor(selectedSection == section ? .white : .white.opacity(0.85))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                selectedSection == section ?
                Color.white.opacity(0.08) : Color.clear
            )
            .cornerRadius(8)
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Helpers
    
    private func sourceColor(for name: String) -> Color {
        GrayjayColors.color(for: name)
    }
    
    private func loadSubscriptions() {
        subscriptions = DatabaseManager.shared.getSubscriptions()
    }
    
    private var safeAreaTop: CGFloat {
        SafeArea.top
    }
}

enum SidebarSection: Hashable {
    case home
    case subscriptions
    case source(String)
    case library
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .subscriptions: return "Subscriptions"
        case .source(let id): return id
        case .library: return "Library"
        }
    }
}
