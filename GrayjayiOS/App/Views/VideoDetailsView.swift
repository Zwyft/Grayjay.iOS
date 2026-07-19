import SwiftUI

struct VideoDetailsView: View {
    let video: VideoDescriptor
    let pluginId: String
    
    @State private var isSubscribed: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Video Player Placeholder / Integration
                ZStack {
                    Color.black
                    if let thumbnailUrl = video.thumbnails?.first {
                        if #available(iOS 15.0, *) {
                            AsyncImage(url: URL(string: thumbnailUrl)) { image in
                                image.resizable().aspectRatio(contentMode: .fit)
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            // iOS 14 fallback
                            Text("Player Loading...")
                                .foregroundColor(.white)
                        }
                    }
                    
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(height: 220)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(video.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        if let views = video.viewCount {
                            Text("\(views) views")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Author / Subscribe Row
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(String(video.author.name.prefix(1)))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(video.author.name)
                                .font(.headline)
                            
                            Text("Creator")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: toggleSubscription) {
                            Text(isSubscribed ? "Subscribed" : "Subscribe")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(isSubscribed ? Color.gray.opacity(0.2) : Color.red)
                                .foregroundColor(isSubscribed ? .primary : .white)
                                .cornerRadius(20)
                        }
                    }
                    
                    Divider()
                    
                    if let description = video.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkSubscription()
            
            // Add to history
            DatabaseManager.shared.addToHistory(
                pluginId: pluginId,
                url: video.url,
                name: video.name,
                authorName: video.author.name,
                thumbnail: video.thumbnails?.first
            )
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
