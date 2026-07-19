import Foundation

struct PluginConfig: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let version: Double
    let author: String
    let scriptUrl: String
    
    // Mapping from JS JSON structure
    enum CodingKeys: String, CodingKey {
        case id, name, description, version, author
        case scriptUrl = "script_url"
    }
}

class PluginManager: ObservableObject {
    static let shared = PluginManager()
    
    @Published var installedPlugins: [PluginConfig] = []
    
    // Known sources registry (similar to Android app's default list)
    @Published var availableSources: [PluginConfig] = [
        PluginConfig(id: "com.futo.youtube", name: "YouTube", description: "Official YouTube Plugin", version: 1.0, author: "FUTO", scriptUrl: "https://plugins.grayjay.app/youtube.js"),
        PluginConfig(id: "com.futo.rumble", name: "Rumble", description: "Official Rumble Plugin", version: 1.0, author: "FUTO", scriptUrl: "https://plugins.grayjay.app/rumble.js"),
        PluginConfig(id: "com.futo.twitch", name: "Twitch", description: "Official Twitch Plugin", version: 1.0, author: "FUTO", scriptUrl: "https://plugins.grayjay.app/twitch.js")
    ]
    
    func installPlugin(source: PluginConfig) {
        // In a real implementation, this would HTTP GET the scriptUrl, validate it, and save it to SQLite.
        // For now, we simulate installation and add it to our active array.
        if !installedPlugins.contains(where: { $0.id == source.id }) {
            installedPlugins.append(source)
            
            // Mock JS injection for the engine to prove binding works
            let mockScript = """
            function getHome() { 
                return JSON.stringify({
                    hasMore: false, 
                    results: [
                        {id: '1', name: 'Mock \(source.name) Video', author: '\(source.author)', url: 'mock://video', thumbnails: ['https://picsum.photos/400/225']}
                    ]
                });
            }
            """
            GrayjayEngine.shared.loadPlugin(script: mockScript)
        }
    }
}
