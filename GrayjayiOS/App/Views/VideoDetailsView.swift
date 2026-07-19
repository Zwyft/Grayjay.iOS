import SwiftUI

struct VideoDetailsView: View {
    let video: VideoDescriptor
    let pluginId: String
    
    @State private var isSubscribed: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Edge-to-Edge Player Placeholder
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
                
                VStack(alignment: .leading, spacing: 20) {
                    // Title and Views
                    VStack(alignment: .leading, spacing: 8) {
                        Text(video.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text("\(video.viewCount ?? 0) views • Recently")
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.6))
                    }
                    .padding(.top, 16)
                    
                    Divider().background(Color(white: 0.2))
                    
                    // Author / Subscribe Row
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color(white: 0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(String(video.author.name.prefix(1)))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(video.author.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Creator")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.6))
                        }
                        
                        Spacer()
                        
                        Button(action: toggleSubscription) {
                            Text(isSubscribed ? "Subscribed" : "Subscribe")
                                .font(.system(size: 15, weight: .bold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(isSubscribed ? Color(white: 0.2) : Color.red)
                                .foregroundColor(isSubscribed ? .white : .white)
                                .cornerRadius(24)
                        }
                    }
                    
                    Divider().background(Color(white: 0.2))
                    
                    // Description
                    if let description = video.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(description)
                                .font(.system(size: 14))
                                .foregroundColor(Color(white: 0.8))
                        }
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(12)
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
