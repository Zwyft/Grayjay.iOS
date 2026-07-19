import Foundation

struct PluginConfig: Codable, Identifiable {
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
    
    // Mapping from JS JSON structure
    enum CodingKeys: String, CodingKey {
        case id, name, description, version, author
        case scriptUrl = "script_url"
        case authConfig, savedAuth
    }
}

struct PluginAuthConfig: Codable {
    let loginUrl: String
    let completionUrl: String?
    let cookiesToFind: [String]?
    let headersToFind: [String]?
}

struct SourceAuth: Codable {
    var cookies: [String: String]
    var headers: [String: String]
    var userAgent: String?
}

class PluginManager: ObservableObject {
    static let shared = PluginManager()
    
    @Published var installedPlugins: [PluginConfig] = []
    
    // Known sources registry (similar to Android app's default list)
    @Published var availableSources: [PluginConfig] = [
        PluginConfig(
            id: "com.futo.youtube", name: "YouTube", description: "Official YouTube Plugin", version: 1.0, author: "FUTO", scriptUrl: "https://gitlab.futo.org/videostreaming/plugins/youtube/-/raw/master/YoutubeScript.js",
            authConfig: PluginAuthConfig(loginUrl: "https://accounts.google.com/ServiceLogin?service=youtube", completionUrl: nil, cookiesToFind: ["SID", "HSID", "SSID"], headersToFind: nil),
            savedAuth: nil
        ),
        PluginConfig(
            id: "com.futo.rumble", name: "Rumble", description: "Official Rumble Plugin", version: 1.0, author: "FUTO", scriptUrl: "https://plugins.grayjay.app/rumble.js",
            authConfig: PluginAuthConfig(loginUrl: "https://rumble.com/login.php", completionUrl: nil, cookiesToFind: ["user_session"], headersToFind: nil),
            savedAuth: nil
        ),
        PluginConfig(
            id: "com.futo.twitch", name: "Twitch", description: "Official Twitch Plugin", version: 1.0, author: "FUTO", scriptUrl: "https://plugins.grayjay.app/twitch.js",
            authConfig: nil, savedAuth: nil
        )
    ]
    
    func installPlugin(source: PluginConfig) {
        if !installedPlugins.contains(where: { $0.id == source.id }) {
            installedPlugins.append(source)
            
            // Download the actual JavaScript plugin script
            guard let url = URL(string: source.scriptUrl) else { return }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let script = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        GrayjayEngine.shared.loadPlugin(script: script, pluginId: source.id)
                        NotificationCenter.default.post(name: NSNotification.Name("PluginInstalled"), object: nil)
                    }
                } else {
                    print("Failed to download plugin script: \(error?.localizedDescription ?? "Unknown error")")
                }
            }.resume()
        }
    }
    
    func saveAuth(for pluginId: String, auth: SourceAuth) {
        if let index = installedPlugins.firstIndex(where: { $0.id == pluginId }) {
            installedPlugins[index].savedAuth = auth
        }
    }
}
