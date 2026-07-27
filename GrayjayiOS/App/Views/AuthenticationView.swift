import SwiftUI
import WebKit

// MARK: - Authentication WebView

struct AuthenticationView: UIViewRepresentable {
    let plugin: PluginConfig
    let onAuthSuccess: (SourceAuth) -> Void
    let onAuthFailed: (String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
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
        private var hasCompleted = false
        
        init(_ parent: AuthenticationView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            hasCompleted = false
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !hasCompleted else { return }
            
            // Check if we've reached the completion URL (OAuth redirect)
            if let completionUrl = parent.plugin.authConfig?.completionUrl,
               let currentUrl = webView.url?.absoluteString,
               currentUrl.hasPrefix(completionUrl) {
                extractAuth(from: webView)
                return
            }
            
            // Check cookies periodically
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.checkCookies(webView: webView)
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            // Ignore cancellation errors (user navigated away)
            if nsError.code != NSURLErrorCancelled {
                print("Auth navigation failed: \(error.localizedDescription)")
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            if nsError.code != NSURLErrorCancelled {
                print("Auth page load failed: \(error.localizedDescription)")
                parent.onAuthFailed("Failed to load login page: \(error.localizedDescription)")
            }
        }
        
        // Intercept redirects for OAuth completion detection
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(.allow)
        }
        
        // MARK: - Auth Extraction
        
        private func checkCookies(webView: WKWebView) {
            guard let authConfig = parent.plugin.authConfig else { return }
            let targetCookies = authConfig.cookiesToFind
            guard !targetCookies.isEmpty else { return }
            
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                var extractedCookies: [String: String] = [:]
                
                for cookie in cookies {
                    if targetCookies.contains(cookie.name) {
                        extractedCookies[cookie.name] = cookie.value
                    }
                }
                
                // Also look for headers (less common)
                let extractedHeaders: [String: String] = [:]
                for _ in authConfig.headersToFind {
                    // We'd need JavaScript injection for headers — skip for now
                }
                
                // If we found at least some target cookies, consider it a partial success
                if !extractedCookies.isEmpty {
                    // Check if we have all required cookies or at least some meaningful auth
                    let foundCount = extractedCookies.count
                    let targetCount = targetCookies.count
                    
                    if foundCount >= targetCount || (foundCount > 0 && foundCount >= targetCount / 2) {
                        let userAgent = webView.customUserAgent ?? "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15"
                        
                        let auth = SourceAuth(
                            cookies: extractedCookies,
                            headers: extractedHeaders,
                            userAgent: userAgent
                        )
                        
                        DispatchQueue.main.async {
                            self.hasCompleted = true
                            self.parent.onAuthSuccess(auth)
                        }
                    }
                }
            }
        }
        
        private func extractAuth(from webView: WKWebView) {
            // Extract all cookies from the current page
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                var allCookies: [String: String] = [:]
                for cookie in cookies {
                    allCookies[cookie.name] = cookie.value
                }
                
                let userAgent = webView.customUserAgent ?? "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15"
                let auth = SourceAuth(cookies: allCookies, headers: [:], userAgent: userAgent)
                
                DispatchQueue.main.async {
                    self.hasCompleted = true
                    self.parent.onAuthSuccess(auth)
                }
            }
        }
    }
}

// MARK: - Authentication Sheet Wrapper

struct AuthenticationSheet: View {
    let plugin: PluginConfig
    @Binding var isPresented: Bool
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Indeterminate progress indicator
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.9, green: 0.1, blue: 0.1)))
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }
                    
                    // Auth WebView
                    AuthenticationView(
                        plugin: plugin,
                        onAuthSuccess: { auth in
                            PluginManager.shared.saveAuth(for: plugin.id, auth: auth)
                            isPresented = false
                        },
                        onAuthFailed: { error in
                            errorMessage = error
                            showError = true
                            isLoading = false
                        }
                    )
                }
                
                // Loading overlay (indeterminate spinner — stay until page renders)
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading login page...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.8))
                    .allowsHitTesting(false)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.gray)
                }
            }
            .alert("Authentication Failed", isPresented: $showError) {
                Button("Try Again") {
                    errorMessage = nil
                    isLoading = true
                }
                Button("Cancel", role: .cancel) {
                    isPresented = false
                }
            } message: {
                Text(errorMessage ?? "Could not complete login. Please try again.")
            }
        }
        .onAppear {
            // Auto-dismiss loading after a timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}
