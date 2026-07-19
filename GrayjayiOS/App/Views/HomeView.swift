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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text("Feed")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.fetchHome()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                // Content Feed
                if viewModel.videos.isEmpty {
                    VStack(spacing: 32) {
                        ForEach(0..<3) { index in
                            VideoCardPlaceholder()
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    LazyVStack(spacing: 32) {
                        ForEach(viewModel.videos) { video in
                            VideoCard(video: video)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            viewModel.fetchHome()
        }
    }
}

struct VideoCard: View {
    let video: VideoDescriptor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
            ZStack {
                Rectangle()
                    .fill(Color(white: 0.1))
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(12)
                
                if let thumbUrl = video.thumbnails?.first, let url = URL(string: thumbUrl) {
                    if #available(iOS 15.0, *) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(16/9, contentMode: .fit).cornerRadius(12)
                            }
                        }
                    } else {
                        // Fallback for iOS 14: Just a gray box (in a real app, use URLSession)
                        Rectangle()
                            .fill(Color(white: 0.2))
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(12)
                            .overlay(Text("Thumb").foregroundColor(.gray))
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            
            // Metadata
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(video.author.name.prefix(1)))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(video.author.name)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct VideoCardPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
            Rectangle()
                .fill(Color(white: 0.1))
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            
            // Metadata
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color(white: 0.15))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.2))
                        .frame(width: 200, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.15))
                        .frame(width: 120, height: 12)
                }
            }
        }
    }
}
