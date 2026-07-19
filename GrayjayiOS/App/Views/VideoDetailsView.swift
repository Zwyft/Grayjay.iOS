import SwiftUI
import AVKit

struct VideoDetailsView: View {
    let video: VideoDescriptor
    let pluginId: String
    
    @State private var isSubscribed: Bool = false
    @State private var player: AVPlayer?
    @State private var isFetchingStream: Bool = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // True Edge-to-Edge Player
                ZStack {
                    Color.black
                    if let player = player {
                        VideoPlayer(player: player)
                            .onAppear {
                                player.play()
                            }
                    } else {
                        if let thumbnailUrl = video.thumbnails?.first {
                            if #available(iOS 15.0, *) {
                                AsyncImage(url: URL(string: thumbnailUrl)) { image in
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                Text("Player Loading...")
                                    .foregroundColor(.white)
                            }
                        }
                        
                        if isFetchingStream {
                            ProgressView()
                                .scaleEffect(1.5, anchor: .center)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .frame(width: UIScreen.main.bounds.width)
                .aspectRatio(16/9, contentMode: .fit)
                
                VStack(alignment: .leading, spacing: 20) {
                    // Title and Views
                    VStack(alignment: .leading, spacing: 8) {
                        Text(video.name)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text("\(video.viewCount ?? 0) views • Recently")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color(red: 0.88, green: 0.88, blue: 0.88))
                    }
                    .padding(.top, 16)
                    
                    Divider().background(Color(white: 0.2))
                    
                    // Author / Subscribe Row
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color(white: 0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(video.author.name.prefix(1)))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(video.author.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Creator")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(Color(red: 0.88, green: 0.88, blue: 0.88))
                        }
                        
                        Spacer()
                        
                        Button(action: toggleSubscription) {
                            Text(isSubscribed ? "Subscribed" : "Subscribe")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(isSubscribed ? Color(white: 0.15) : Color.red)
                                .foregroundColor(isSubscribed ? .white : .white)
                                .cornerRadius(4)
                        }
                    }
                    
                    Divider().background(Color(white: 0.2))
                    
                    // Description
                    if let description = video.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(description)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        .background(Color(white: 0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkSubscription()
            fetchStream()
            
            // Add to history
            DatabaseManager.shared.addToHistory(
                pluginId: pluginId,
                url: video.url,
                name: video.name,
                authorName: video.author.name,
                thumbnail: video.thumbnails?.first
            )
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func fetchStream() {
        GrayjayEngine.shared.fetchVideoDetails(url: video.url) { jsonString in
            guard let jsonString = jsonString, let data = jsonString.data(using: .utf8) else {
                isFetchingStream = false
                return
            }
            
            do {
                let details = try JSONDecoder().decode(PlatformVideoDetails.self, from: data)
                
                // Find a suitable stream URL (Prefer HLS, then MP4)
                if let sources = details.video?.videoSources {
                    let hlsSource = sources.first { $0.container == "application/x-mpegURL" || $0.url.contains(".m3u8") }
                    let mp4Source = sources.first { $0.container == "video/mp4" || $0.url.contains(".mp4") }
                    
                    if let targetSource = hlsSource ?? mp4Source ?? sources.first,
                       let url = URL(string: targetSource.url) {
                        DispatchQueue.main.async {
                            self.player = AVPlayer(url: url)
                            self.isFetchingStream = false
                        }
                    } else {
                        self.isFetchingStream = false
                    }
                } else {
                    self.isFetchingStream = false
                }
            } catch {
                print("Failed to parse video details: \(error)")
                self.isFetchingStream = false
            }
        }
    }
    
    private func checkSubscription() {
        if let authorUrl = video.author.url {
            isSubscribed = DatabaseManager.shared.isSubscribed(url: authorUrl)
        }
    }
    
    private func toggleSubscription() {
        guard let authorUrl = video.author.url else { return }
        
        if isSubscribed {
            DatabaseManager.shared.unsubscribe(url: authorUrl)
        } else {
            DatabaseManager.shared.subscribe(
                pluginId: pluginId,
                url: authorUrl,
                name: video.author.name,
                thumbnail: video.author.thumbnail
            )
        }
        isSubscribed.toggle()
    }
}
