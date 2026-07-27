import SwiftUI

struct MainTabView: View {
    @State private var sidebarOpen: Bool = false
    @State private var selectedSection: SidebarSection = .home
    @StateObject private var pluginManager = PluginManager.shared
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Main Content
            Group {
                switch selectedSection {
                case .home:
                    HomeView(sidebarOpen: $sidebarOpen, selectedSection: $selectedSection)
                case .subscriptions:
                    SubsView(sidebarOpen: $sidebarOpen)
                case .source(let pluginId):
                    SourceContentView(pluginId: pluginId, sidebarOpen: $sidebarOpen)
                case .library:
                    LibraryView(sidebarOpen: $sidebarOpen)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Sidebar
            if sidebarOpen {
                // Dimmed overlay
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            sidebarOpen = false
                        }
                    }
                    .transition(.opacity)
                
                // Sidebar panel slides in from left
                HStack(spacing: 0) {
                    SidebarView(
                        isOpen: $sidebarOpen,
                        selectedSection: $selectedSection,
                        pluginManager: pluginManager
                    )
                    
                    Spacer()
                }
                .transition(.move(edge: .leading))
                .gesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .local)
                        .onEnded { value in
                            // Swipe left to close sidebar
                            if value.translation.width < -50 {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    sidebarOpen = false
                                }
                            }
                        }
                )
            }
        }
    }
}

// MARK: - Source Content View

struct SourceContentView: View {
    let pluginId: String
    @Binding var sidebarOpen: Bool
    @ObservedObject private var pluginManager = PluginManager.shared
    @State private var authPlugin: PluginConfig?
    @State private var showLogoutAlert: Bool = false
    @State private var videos: [VideoDescriptor] = []
    @State private var isLoadingContent: Bool = true
    
    private var plugin: PluginConfig? {
        pluginManager.installedPlugins.first(where: { $0.id == pluginId })
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let plugin = plugin {
                    if plugin.savedAuth != nil || plugin.authConfig == nil {
                        // Logged in or no auth needed — show content feed
                        sourceContentFeed(plugin: plugin)
                    } else {
                        // Not logged in — show login prompt
                        loginPrompt(plugin: plugin)
                    }
                } else {
                    // Plugin not installed
                    notInstalledView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            sidebarOpen = true
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(plugin?.name ?? "Source")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let plugin = plugin, plugin.savedAuth != nil {
                        Menu {
                            Button(role: .destructive, action: {
                                showLogoutAlert = true
                            }) {
                                Label("Logout from \(plugin.name)", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .onAppear {
                loadContent()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginAuthStateChanged)) { notification in
                if let changedId = notification.object as? String, changedId == pluginId {
                    loadContent()
                }
            }
            // Auth sheet
            .sheet(item: $authPlugin) { plugin in
                AuthenticationSheet(plugin: plugin, isPresented: Binding(
                    get: { authPlugin != nil },
                    set: { if !$0 { authPlugin = nil } }
                ))
            }
            // Logout confirmation
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Logout", role: .destructive) {
                    PluginManager.shared.logout(pluginId: pluginId)
                    videos = []
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let plugin = plugin {
                    Text("Sign out of \(plugin.name)? You'll need to log in again to access your subscriptions.")
                }
            }
        }
    }
    
    // MARK: - Login Prompt
    
    private func loginPrompt(plugin: PluginConfig) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Source icon
            Circle()
                .fill(sourceColor(for: plugin.name).opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(String(plugin.name.prefix(1)))
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(sourceColor(for: plugin.name))
                )
            
            VStack(spacing: 8) {
                Text("Sign in to \(plugin.name)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Connect your account to access your subscriptions, playlists, and more.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Login button
            Button(action: {
                authPlugin = plugin
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                    Text("Sign in with \(plugin.name)")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(sourceColor(for: plugin.name))
                .cornerRadius(24)
            }
            
            // Why login explanation
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text("Your credentials are stored locally and never shared.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.7))
            }
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Content Feed
    
    private func sourceContentFeed(plugin: PluginConfig) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar with auth status
            HStack(spacing: 12) {
                Circle()
                    .fill(sourceColor(for: plugin.name).opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(plugin.name.prefix(1)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(sourceColor(for: plugin.name))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(plugin.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    if plugin.savedAuth != nil {
                        Label("Signed in", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            if isLoadingContent {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Loading content...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else if videos.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "tray.full")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No content yet")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Browse and subscribe to creators to see their latest content here.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        ForEach(videos) { video in
                            NavigationLink(destination: VideoDetailsView(video: video, pluginId: pluginId)) {
                                VideoCard(video: video)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    // MARK: - Not Installed View
    
    private var notInstalledView: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.square.dashed")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("Source not installed")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("Install this source from the sidebar to view content.")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Content Loading
    
    private func loadContent() {
        guard plugin != nil else { return }
        isLoadingContent = true
        
        // Set active plugin ID for the engine
        GrayjayEngine.shared.activePluginId = pluginId
        
        // Fetch home feed using the plugin's JS (similar to HomeViewModel)
        DispatchQueue.global(qos: .userInitiated).async {
            if let jsValue = GrayjayEngine.shared.executeFunction(name: "getHome", args: []),
               let context = jsValue.context,
               let stringify = context.objectForKeyedSubscript("JSON")?.objectForKeyedSubscript("stringify"),
               let jsonJsValue = stringify.call(withArguments: [jsValue]),
               let jsonString = jsonJsValue.toString(),
               let data = jsonString.data(using: .utf8) {
                do {
                    let paged = try JSONDecoder().decode(PagedResult<VideoDescriptor>.self, from: data)
                    DispatchQueue.main.async {
                        videos = paged.results ?? []
                        isLoadingContent = false
                    }
                } catch {
                    print("Failed to decode source content: \(error)")
                    DispatchQueue.main.async {
                        isLoadingContent = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isLoadingContent = false
                }
            }
        }
    }
    
    private func sourceColor(for name: String) -> Color {
        GrayjayColors.color(for: name)
    }
}
