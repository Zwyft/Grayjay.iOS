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

class PluginManager {
    static let shared = PluginManager()
    
    @Published var installedPlugins: [PluginConfig] = []
    
    func installPlugin(from url: URL) {
        // In a real app, this would download the JSON config, parse it, and then download the JS script.
        // For now, we simulate a successful install.
        let mockPlugin = PluginConfig(
            id: "com.example.youtube",
            name: "YouTube",
            description: "Mock YouTube Plugin",
            version: 1.0,
            author: "FUTO",
            scriptUrl: "https://example.com/yt.js"
        )
        
        installedPlugins.append(mockPlugin)
        
        // Let the engine know
        let mockScript = "function getHome() { return [{title: 'Mock Video', id: '123'}]; }"
        GrayjayEngine.shared.loadPlugin(script: mockScript)
    }
}
