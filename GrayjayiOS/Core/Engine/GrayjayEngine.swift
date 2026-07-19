import Foundation
import JavaScriptCore

/// Simulates the Android `PlatformBridge` to allow JS plugins to interact with native iOS features.
@objc protocol PlatformBridgeJSExport: JSExport {
    func httpGet(_ url: String, _ headers: [String: String]) -> String
    func log(_ message: String)
}

@objc class PlatformBridge: NSObject, PlatformBridgeJSExport {
    func httpGet(_ url: String, _ headers: [String: String]) -> String {
        return NetworkManager.shared.executeSyncGet(url: url, headers: headers)
    }
    
    func log(_ message: String) {
        print("[Plugin Log]: \(message)")
    }
}

class GrayjayEngine {
    static let shared = GrayjayEngine()
    private var jsContext: JSContext!
    
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
        
        _ = jsContext.evaluateScript("var console = { log: print };")
    }
    
    /// Loads a Grayjay plugin script into the engine
    func loadPlugin(script: String) {
        _ = jsContext.evaluateScript(script)
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
