import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var videos: [VideoDescriptor] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to engine notifications using Combine to avoid @objc/#selector issues
        NotificationCenter.default.publisher(for: NSNotification.Name("PluginInstalled"))
            .sink { [weak self] _ in
                self?.fetchHome()
            }
            .store(in: &cancellables)
    }
    
    func fetchHome() {
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
    @Binding var sidebarOpen: Bool
    @Binding var selectedSection: SidebarSection
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            
            // Content Feed with Navigation
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
                    
                    // Transparent Top Bar with Hamburger Menu
                    VStack(spacing: 0) {
                        HStack {
                            // Hamburger Menu Button to open sidebar
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    sidebarOpen = true
                                }
                            }) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            
                            Spacer()
                            
                            // Navigation link to Search
                            NavigationLink(destination: SearchView()) {
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
                        .padding(.top, safeAreaTop)
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
    
    private var safeAreaTop: CGFloat {
        SafeArea.top
    }
}

struct VideoCard: View {
    let video: VideoDescriptor
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Left Side: Player Container (178x100)
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Color(white: 0.1))
                    .frame(width: 178, height: 100)
                    .cornerRadius(4)
                
                if let thumbUrl = video.thumbnails?.first, let url = URL(string: thumbUrl) {
                    if #available(iOS 15.0, *) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 178, height: 100)
                                    .clipped()
                                    .cornerRadius(4)
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color(white: 0.15))
                            .frame(width: 178, height: 100)
                            .cornerRadius(4)
                    }
                }
                
                // Red progress bar at the bottom
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 178, height: 2)
                    .padding(.trailing, 80) // Simulate a partially watched video
            }
            .frame(width: 178, height: 100)
            
            // Right Side: Metadata & Buttons
            VStack(alignment: .leading, spacing: 4) {
                // Title (max 2 lines)
                Text(video.name)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .padding(.top, 2)
                
                // Channel Avatar and Info
                HStack(alignment: .center, spacing: 6) {
                    // Small Channel Avatar (28x28)
                    Circle()
                        .fill(Color(white: 0.2))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(video.author.name.prefix(1)))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(video.author.name)
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(Color(red: 0.88, green: 0.88, blue: 0.88))
                            .lineLimit(1)
                        
                        Text("\(video.viewCount ?? 0) views")
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(Color(red: 0.88, green: 0.88, blue: 0.88))
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 0)
                
                // Action Buttons pinned to the bottom
                HStack(spacing: 6) {
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 12))
                            Text("Options")
                                .font(.system(size: 11, weight: .light))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color(white: 0.15))
                        .cornerRadius(4)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 22)
                            .background(Color(white: 0.15))
                            .cornerRadius(4)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 22)
                            .background(Color(white: 0.15))
                            .cornerRadius(4)
                    }
                }
                .padding(.bottom, 4)
            }
            .frame(height: 100) // Match thumbnail height
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct VideoCardPlaceholder: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Left Side: Player Container
            Rectangle()
                .fill(Color(white: 0.1))
                .frame(width: 178, height: 100)
                .cornerRadius(4)
            
            // Right Side: Metadata
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.15))
                    .frame(height: 14)
                    .padding(.top, 4)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.15))
                    .frame(width: 100, height: 14)
                
                HStack(alignment: .center, spacing: 6) {
                    Circle()
                        .fill(Color(white: 0.15))
                        .frame(width: 28, height: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(white: 0.1))
                            .frame(width: 80, height: 10)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(white: 0.1))
                            .frame(width: 60, height: 10)
                    }
                }
                .padding(.top, 4)
                
                Spacer(minLength: 0)
            }
            .frame(height: 100)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
