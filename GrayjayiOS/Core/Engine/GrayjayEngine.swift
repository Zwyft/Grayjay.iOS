import Foundation
import JavaScriptCore

/// Simulates the Android `PlatformBridge` to allow JS plugins to interact with native iOS features.
@objc protocol PlatformBridgeJSExport: JSExport {
    func httpGet(_ url: String, _ headers: [String: String]) -> String
    func log(_ message: String)
    func isLoggedIn() -> Bool
}

@objc class PlatformBridge: NSObject, PlatformBridgeJSExport {
    func httpGet(_ url: String, _ headers: [String: String]) -> String {
        return NetworkManager.shared.executeSyncGet(url: url, headers: headers, pluginId: GrayjayEngine.shared.activePluginId)
    }
    
    func log(_ message: String) {
        print("[Plugin Log]: \(message)")
    }
    
    func isLoggedIn() -> Bool {
        guard let activeId = GrayjayEngine.shared.activePluginId else { return false }
        return PluginManager.shared.installedPlugins.first(where: { $0.id == activeId })?.savedAuth != nil
    }
}

class GrayjayEngine {
    static let shared = GrayjayEngine()
    private var jsContext: JSContext!
    var activePluginId: String?
    
    init() {
        setupContext()
    }
    
    private func setupContext() {
        jsContext = JSContext()
        
        // Handle JS exceptions
        jsContext.exceptionHandler = { context, exception in
            if let exception = exception {
                print("JS Exception: \(exception.toString() ?? "unknown")")
            }
        }
        
        // Inject the Platform Bridge
        let bridge = PlatformBridge()
        jsContext.setObject(bridge, forKeyedSubscript: "bridge" as NSString)
        
        // Provide console.log polyfill since JavaScriptCore doesn't have it natively
        let consoleLog: @convention(block) (String) -> Void = { message in
            print("JS Console: \(message)")
        }
        jsContext.setObject(consoleLog, forKeyedSubscript: "print" as NSString)
        
        // Timeout Polyfills (required by bundled JSDOM)
        let setTimeout: @convention(block) (JSValue, Double) -> Void = { callback, delay in
            DispatchQueue.global().asyncAfter(deadline: .now() + (delay / 1000.0)) {
                callback.call(withArguments: [])
            }
        }
        jsContext.setObject(setTimeout, forKeyedSubscript: "setTimeout" as NSString)
        
        let clearTimeout: @convention(block) (JSValue) -> Void = { _ in
            // Basic mock, true cancellation requires tracking IDs
        }
        jsContext.setObject(clearTimeout, forKeyedSubscript: "clearTimeout" as NSString)
        
        _ = jsContext.evaluateScript("""
            var console = { log: print, error: print, warn: print, info: print };
            var window = this;
            var global = this;
        """)
    }
    
    /// Loads a Grayjay plugin script into the engine
    func loadPlugin(script: String, pluginId: String, settings: [String: Any]? = nil) {
        self.activePluginId = pluginId
        _ = jsContext.evaluateScript(script)
        
        let defaultSettings: [String: Any] = [
            "authDetails": true,
            "youtubeActivity": true,
            "authChannels": true,
            "allowLoginFallback": true
        ]
        
        let finalSettings = settings ?? defaultSettings
        if let jsonString = try? String(data: JSONSerialization.data(withJSONObject: finalSettings), encoding: .utf8) {
            _ = jsContext.evaluateScript("if(typeof source !== 'undefined' && source.setSettings) { source.setSettings(\(jsonString)); }")
        }
    }
    
    /// Executes a specific function from the plugin
    func executeFunction(name: String, args: [Any]) -> JSValue? {
        guard let function = jsContext.objectForKeyedSubscript(name) else {
            print("Function \(name) not found in plugin.")
            return nil
        }
        return function.call(withArguments: args)
    }
}
