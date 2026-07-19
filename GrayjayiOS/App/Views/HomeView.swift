import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var videos: [VideoDescriptor] = []
    
    init() {
        // Subscribe to engine notifications or polling (simplified for Phase 1)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchHome), name: NSNotification.Name("PluginInstalled"), object: nil)
    }
    
    @objc func fetchHome() {
        // Evaluate getHome across installed plugins (simplified)
        if let jsValue = GrayjayEngine.shared.executeFunction(name: "getHome", args: []),
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
                }
            } catch {
                print("Failed to decode video descriptor: \(error)")
                print("JSON Dump: \(String(data: data, encoding: .utf8) ?? "")")
            }
        }
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Spacer for fixed header
                        Spacer().frame(height: 100)
                        
                        // Content Feed
                        if viewModel.videos.isEmpty {
                            VStack(spacing: 32) {
                                ForEach(0..<3) { index in
                                    VideoCardPlaceholder()
                                }
                            }
                        } else {
                            LazyVStack(spacing: 24) {
                                ForEach(viewModel.videos) { video in
                                    NavigationLink(destination: VideoDetailsView(video: video, pluginId: GrayjayEngine.shared.activePluginId ?? "")) {
                                        VideoCard(video: video)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
                
                // Translucent Glassmorphism Header
                VStack(spacing: 0) {
                    HStack {
                        Text("Grayjay")
                            .font(.system(size: 28, weight: .heavy, design: .default))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.fetchHome()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(Color.white.opacity(0.15)))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)
                }
                .background(BlurView(style: .dark).ignoresSafeArea(edges: .top))
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchHome()
            }
        }
    }
}

struct VideoCard: View {
    let video: VideoDescriptor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Edge-to-Edge Thumbnail
            ZStack {
                Rectangle()
                    .fill(Color(white: 0.1))
                    .aspectRatio(16/9, contentMode: .fit)
                
                if let thumbUrl = video.thumbnails?.first, let url = URL(string: thumbUrl) {
                    if #available(iOS 15.0, *) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(16/9, contentMode: .fit)
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color(white: 0.15))
                            .aspectRatio(16/9, contentMode: .fit)
                    }
                }
            }
            
            // Metadata
            HStack(alignment: .top, spacing: 12) {
                // Author Avatar
                Circle()
                    .fill(Color(white: 0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(video.author.name.prefix(1)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text("\(video.author.name) - \(video.viewCount ?? 0) views")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.6))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct VideoCardPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color(white: 0.1))
                .aspectRatio(16/9, contentMode: .fit)
            
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color(white: 0.15))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.15))
                        .frame(width: 200, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.1))
                        .frame(width: 140, height: 12)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
