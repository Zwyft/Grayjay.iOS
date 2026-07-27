import Foundation

// MARK: - Plugin Configuration

struct PluginConfig: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let description: String
    let version: Double
    let author: String
    let scriptUrl: String
    
    // Auth configuration parsed from the JS plugin
    var authConfig: PluginAuthConfig?
    
    // Session state extracted from WebKit
    var savedAuth: SourceAuth?
    
    static func == (lhs: PluginConfig, rhs: PluginConfig) -> Bool {
        lhs.id == rhs.id
    }
}

struct PluginAuthConfig: Codable {
    let loginUrl: String
    let completionUrl: String?
    let cookiesToFind: [String]
    let headersToFind: [String]
}

struct SourceAuth: Codable {
    var cookies: [String: String]
    var headers: [String: String]
    var userAgent: String?
}

// MARK: - Notifications

extension Notification.Name {
    static let pluginAuthStateChanged = Notification.Name("PluginAuthStateChanged")
}

// MARK: - Persisted State

/// Lightweight container saved to disk so installed plugins + auth survive app restarts.
private struct PersistedPluginState: Codable {
    let installedPlugins: [PluginConfig]
}

// MARK: - Plugin Persistence Manager

private class PluginPersistenceManager {
    private let fileManager = FileManager.default
    
    private var supportDir: URL? {
        try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }
    
    private var stateFile: URL? {
        supportDir?.appendingPathComponent("grayjay_plugins.json")
    }
    
    private var scriptsDir: URL? {
        guard let dir = supportDir else { return nil }
        let scripts = dir.appendingPathComponent("plugin_scripts")
        try? fileManager.createDirectory(at: scripts, withIntermediateDirectories: true)
        return scripts
    }
    
    // MARK: - Plugin State
    
    func loadInstalledPlugins() -> [PluginConfig] {
        guard let url = stateFile,
              let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(PersistedPluginState.self, from: data) else {
            return []
        }
        return state.installedPlugins
    }
    
    func saveInstalledPlugins(_ plugins: [PluginConfig]) {
        guard let url = stateFile else { return }
        let state = PersistedPluginState(installedPlugins: plugins)
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: url, options: .atomic)
        }
    }
    
    func clearState() {
        guard let url = stateFile else { return }
        try? fileManager.removeItem(at: url)
    }
    
    // MARK: - Plugin Script Caching
    
    func cachedScriptPath(for pluginId: String) -> URL? {
        scriptsDir?.appendingPathComponent("\(pluginId).js")
    }
    
    func loadCachedScript(for pluginId: String) -> String? {
        guard let url = cachedScriptPath(for: pluginId),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    func cacheScript(_ script: String, for pluginId: String) {
        guard let url = cachedScriptPath(for: pluginId),
              let data = script.data(using: .utf8) else { return }
        try? data.write(to: url, options: .atomic)
    }
    
    func removeCachedScript(for pluginId: String) {
        guard let url = cachedScriptPath(for: pluginId) else { return }
        try? fileManager.removeItem(at: url)
    }
}

// MARK: - Plugin Manager

class PluginManager: ObservableObject {
    static let shared = PluginManager()
    
    @Published var installedPlugins: [PluginConfig] = [] {
        didSet { persistence.saveInstalledPlugins(installedPlugins) }
    }
    
    private let persistence = PluginPersistenceManager()
    
    // Known sources registry — mirrors the Android app's default source list
    @Published var availableSources: [PluginConfig] = [
        PluginConfig(
            id: "com.futo.youtube",
            name: "YouTube",
            description: "Watch videos, subscribe to channels, and browse your feed",
            version: 1.0,
            author: "FUTO",
            scriptUrl: "https://gitlab.futo.org/videostreaming/plugins/youtube/-/raw/master/YoutubeScript.js",
            authConfig: PluginAuthConfig(
                loginUrl: "https://accounts.google.com/ServiceLogin?service=youtube",
                completionUrl: "https://www.youtube.com",
                cookiesToFind: ["SID", "HSID", "SSID"],
                headersToFind: []
            ),
            savedAuth: nil
        ),
        PluginConfig(
            id: "com.futo.rumble",
            name: "Rumble",
            description: "Browse and watch Rumble videos",
            version: 1.0,
            author: "FUTO",
            scriptUrl: "https://plugins.grayjay.app/rumble.js",
            authConfig: PluginAuthConfig(
                loginUrl: "https://rumble.com/login.php",
                completionUrl: nil,
                cookiesToFind: ["user_session"],
                headersToFind: []
            ),
            savedAuth: nil
        ),
        PluginConfig(
            id: "com.futo.twitch",
            name: "Twitch",
            description: "Watch live streams and VODs from your favorite creators",
            version: 1.0,
            author: "FUTO",
            scriptUrl: "https://plugins.grayjay.app/twitch.js",
            authConfig: nil,
            savedAuth: nil
        )
    ]
    
    private init() {
        restoreState()
    }
    
    /// Loads previously-installed plugins and their auth state from disk.
    private func restoreState() {
        let saved = persistence.loadInstalledPlugins()
        guard !saved.isEmpty else { return }
        
        // Rehydrate installed plugins from saved state, merging with available source metadata
        var restored: [PluginConfig] = []
        for savedPlugin in saved {
            // Keep the saved version (which includes auth state)
            var plugin = savedPlugin
            
            // Merge in any metadata from availableSources that the saved version might lack
            if let available = availableSources.first(where: { $0.id == plugin.id }) {
                if plugin.authConfig == nil { plugin.authConfig = available.authConfig }
                if plugin.description.isEmpty { /* keep saved description */ }
            }
            
            restored.append(plugin)
        }
        installedPlugins = restored
        
        // Reload plugin scripts from cache
        for plugin in installedPlugins {
            if let cached = persistence.loadCachedScript(for: plugin.id) {
                GrayjayEngine.shared.loadPlugin(script: cached, pluginId: plugin.id)
            } else {
                // Script not cached — re-download
                downloadAndCacheScript(for: plugin)
            }
        }
    }
    
    // MARK: - Install / Uninstall
    
    func installPlugin(source: PluginConfig) {
        guard !installedPlugins.contains(where: { $0.id == source.id }) else { return }
        installedPlugins.append(source) // triggers didSet → persistence.save
        
        // Check cache first, then download
        if let cached = persistence.loadCachedScript(for: source.id) {
            GrayjayEngine.shared.loadPlugin(script: cached, pluginId: source.id)
            NotificationCenter.default.post(name: NSNotification.Name("PluginInstalled"), object: nil)
        } else {
            downloadAndCacheScript(for: source)
        }
    }
    
    func uninstallPlugin(id: String) {
        installedPlugins.removeAll(where: { $0.id == id }) // triggers didSet → persistence.save
        persistence.removeCachedScript(for: id)
        objectWillChange.send()
        NotificationCenter.default.post(name: .pluginAuthStateChanged, object: nil)
    }
    
    // MARK: - Authentication
    
    func saveAuth(for pluginId: String, auth: SourceAuth) {
        guard let index = installedPlugins.firstIndex(where: { $0.id == pluginId }) else { return }
        installedPlugins[index].savedAuth = auth // triggers didSet → persistence.save
        objectWillChange.send()
        NotificationCenter.default.post(name: .pluginAuthStateChanged, object: pluginId)
    }
    
    func logout(pluginId: String) {
        guard let index = installedPlugins.firstIndex(where: { $0.id == pluginId }) else { return }
        installedPlugins[index].savedAuth = nil // triggers didSet → persistence.save
        objectWillChange.send()
        NotificationCenter.default.post(name: .pluginAuthStateChanged, object: pluginId)
    }
    
    func isLoggedIn(pluginId: String) -> Bool {
        installedPlugins.first(where: { $0.id == pluginId })?.savedAuth != nil
    }
    
    // MARK: - Script Download / Cache
    
    private func downloadAndCacheScript(for source: PluginConfig) {
        guard let url = URL(string: source.scriptUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, let script = String(data: data, encoding: .utf8) else {
                print("Failed to download plugin script: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self?.persistence.cacheScript(script, for: source.id)
                GrayjayEngine.shared.loadPlugin(script: script, pluginId: source.id)
                NotificationCenter.default.post(name: NSNotification.Name("PluginInstalled"), object: nil)
            }
        }.resume()
    }
}
