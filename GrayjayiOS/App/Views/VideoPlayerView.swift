import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var showControls = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                CustomVideoPlayer(player: player)
                    .onTapGesture {
                        withAnimation {
                            showControls.toggle()
                        }
                    }
                    .overlay(
                        controlOverlay
                    )
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private var controlOverlay: some View {
        ZStack {
            if showControls {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showControls.toggle() }
                    }
                
                HStack(spacing: 40) {
                    Button(action: {
                        player?.seek(to: CMTime(seconds: (player?.currentTime().seconds ?? 0) - 10, preferredTimescale: 1))
                    }) {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        if isPlaying {
                            player?.pause()
                        } else {
                            player?.play()
                        }
                        isPlaying.toggle()
                    }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 48, weight: .black))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        player?.seek(to: CMTime(seconds: (player?.currentTime().seconds ?? 0) + 10, preferredTimescale: 1))
                    }) {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private func setupPlayer() {
        let newPlayer = AVPlayer(url: videoURL)
        
        // Optimize for background playback
        if #available(iOS 15.0, *) {
            newPlayer.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
        }
        
        self.player = newPlayer
        self.player?.play()
        self.isPlaying = true
    }
}

/// A wrapper for AVPlayerLayer to provide a custom, unbranded video experience
struct CustomVideoPlayer: UIViewControllerRepresentable {
    var player: AVPlayer
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        controller.view.layer.addSublayer(playerLayer)
        
        // Use a weak reference block or observer to keep the layer frame synced
        DispatchQueue.main.async {
            playerLayer.frame = controller.view.bounds
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let layer = uiViewController.view.layer.sublayers?.first as? AVPlayerLayer {
            layer.player = player
            layer.frame = uiViewController.view.bounds
        }
    }
}
