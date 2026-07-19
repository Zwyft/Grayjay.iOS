import SwiftUI

class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var videos: [VideoDescriptor] = []
    @Published var isSearching: Bool = false
    
    func performSearch() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isSearching = true
        videos = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Call source.search(query)
            if let jsValue = GrayjayEngine.shared.executeFunction(name: "search", args: [self.query]),
               let context = jsValue.context,
               let stringify = context.objectForKeyedSubscript("JSON")?.objectForKeyedSubscript("stringify"),
               let jsonJsValue = stringify.call(withArguments: [jsValue]),
               let jsonString = jsonJsValue.toString(),
               let data = jsonString.data(using: .utf8) {
                
                do {
                    let paged = try JSONDecoder().decode(PagedResult<VideoDescriptor>.self, from: data)
                    DispatchQueue.main.async {
                        if let res = paged.results {
                            self.videos = res
                        }
                        self.isSearching = false
                    }
                } catch {
                    print("Search decoding failed: \(error)")
                    DispatchQueue.main.async {
                        self.isSearching = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isSearching = false
                }
            }
        }
    }
}

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar Header
                HStack(spacing: 12) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(white: 0.6))
                        
                        TextField("Search Grayjay...", text: $viewModel.query, onCommit: {
                            viewModel.performSearch()
                        })
                        .foregroundColor(.white)
                        .disableAutocorrection(true)
                        
                        if !viewModel.query.isEmpty {
                            Button(action: {
                                viewModel.query = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color(white: 0.6))
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(white: 0.15))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)
                .background(BlurView(style: .dark).ignoresSafeArea(edges: .top))
                
                // Results Area
                if viewModel.isSearching {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if viewModel.videos.isEmpty && !viewModel.query.isEmpty {
                    Spacer()
                    Text("No results found.")
                        .foregroundColor(Color(white: 0.6))
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 24) {
                            ForEach(viewModel.videos) { video in
                                NavigationLink(destination: VideoDetailsView(video: video, pluginId: GrayjayEngine.shared.activePluginId ?? "")) {
                                    VideoCard(video: video)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 100) // Padding for bottom tab bar if needed
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}
