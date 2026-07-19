import SwiftUI
import WebKit

struct AuthenticationView: UIViewRepresentable {
    let plugin: PluginConfig
    let onAuthSuccess: (SourceAuth) -> Void
    let onCancel: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        if let authConfig = plugin.authConfig, let url = URL(string: authConfig.loginUrl) {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: AuthenticationView
        
        init(_ parent: AuthenticationView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            checkCookies(webView: webView)
        }
        
        func checkCookies(webView: WKWebView) {
            guard let authConfig = parent.plugin.authConfig, let targetCookies = authConfig.cookiesToFind else { return }
            
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                var extractedCookies: [String: String] = [:]
                
                for cookie in cookies {
                    if targetCookies.contains(cookie.name) {
                        extractedCookies[cookie.name] = cookie.value
                    }
                }
                
                // If we found all target cookies, authentication is successful
                if extractedCookies.count == targetCookies.count {
                    let userAgent = webView.customUserAgent ?? "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1"
                    
                    let auth = SourceAuth(cookies: extractedCookies, headers: [:], userAgent: userAgent)
                    
                    DispatchQueue.main.async {
                        self.parent.onAuthSuccess(auth)
                    }
                }
            }
        }
    }
}

struct AuthenticationSheet: View {
    let plugin: PluginConfig
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            AuthenticationView(plugin: plugin, onAuthSuccess: { auth in
                PluginManager.shared.saveAuth(for: plugin.id, auth: auth)
                isPresented = false
            }, onCancel: {
                isPresented = false
            })
            .navigationBarTitle("Login to \(plugin.name)", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
