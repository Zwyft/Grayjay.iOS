import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let session = URLSession(configuration: .default)
    
    /// Synchronous HTTP Get for JavaScriptCore plugins.
    /// - Parameters:
    ///   - urlString: Target URL
    ///   - headers: Custom HTTP headers
    /// - Returns: JSON string representing the response or error
    func executeSyncGet(url urlString: String, headers: [String: String], pluginId: String?) -> String {
        guard let url = URL(string: urlString) else {
            return "{\"error\": \"Invalid URL\"}"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Inject Authentication Cookies if available
        if let pid = pluginId, let auth = PluginManager.shared.installedPlugins.first(where: { $0.id == pid })?.savedAuth {
            let cookieString = auth.cookies.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
            if !cookieString.isEmpty {
                request.setValue(cookieString, forHTTPHeaderField: "Cookie")
            }
            if let userAgent = auth.userAgent {
                request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            }
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var responseData: Data?
        var statusCode: Int = 0
        var errorDesc: String?
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                errorDesc = error.localizedDescription
            } else if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
                responseData = data
            }
            semaphore.signal()
        }
        
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
        if let errorDesc = errorDesc {
            return "{\"error\": \"\(errorDesc)\"}"
        }
        
        let body = responseData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        
        // Escape body for JSON serialization (basic implementation)
        let escapedBody = body
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        
        return "{\"status\": \(statusCode), \"body\": \"\(escapedBody)\"}"
    }
}
