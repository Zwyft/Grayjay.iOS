import SwiftUI

struct VideoDetailsView: View {
    let video: VideoDescriptor
    let pluginId: String
    
    @State private var isSubscribed: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // True Edge-to-Edge Player
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
                            Text("Player Loading...")
                                .foregroundColor(.white)
                        }
                    }
                    
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white.opacity(0.8))
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
