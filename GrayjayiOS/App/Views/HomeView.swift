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
                
                // Minimal Transparent Top Bar (Mimicking Grayjay Android)
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(8)
                        }
                        
                        Button(action: {
                            viewModel.fetchHome()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(8)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
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
        VStack(alignment: .leading, spacing: 0) {
            // Edge-to-Edge Thumbnail
            ZStack(alignment: .bottom) {
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
                
                // Red progress bar at the bottom (like time_bar in Grayjay)
                Rectangle()
                    .fill(Color.red)
                    .frame(height: 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 150) // Simulate a partially watched video
            }
            
            // Metadata (Mimicking list_video_preview.xml)
            HStack(alignment: .top, spacing: 10) {
                // Creator Thumbnail (32x32 on Android)
                Circle()
                    .fill(Color(white: 0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(video.author.name.prefix(1)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .padding(.top, 10)
                
                // Title and Metadata
                VStack(alignment: .leading, spacing: 0) {
                    Text(video.name)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .padding(.top, 7)
                    
                    Text(video.author.name)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(Color(red: 0.88, green: 0.88, blue: 0.88)) // #E0E0E0
                        .lineLimit(1)
                    
                    Text("\(video.viewCount ?? 0) views")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(Color(red: 0.88, green: 0.88, blue: 0.88)) // #E0E0E0
                        .lineLimit(1)
                        .padding(.bottom, 5)
                }
                
                Spacer()
                
                // Quick Action Buttons
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color(white: 0.15))
                            .cornerRadius(4)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color(white: 0.15))
                            .cornerRadius(4)
                    }
                }
                .padding(.top, 10)
                .padding(.trailing, 10)
            }
            .padding(.leading, 10)
        }
    }
}

struct VideoCardPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color(white: 0.1))
                .aspectRatio(16/9, contentMode: .fit)
            
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(Color(white: 0.15))
                    .frame(width: 32, height: 32)
                    .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.15))
                        .frame(width: 180, height: 14)
                        .padding(.top, 10)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.1))
                        .frame(width: 120, height: 12)
                }
                
                Spacer()
            }
            .padding(.leading, 10)
        }
    }
}
