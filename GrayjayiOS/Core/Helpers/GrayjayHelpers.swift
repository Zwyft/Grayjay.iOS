import SwiftUI
import UIKit

// MARK: - Source Color Helper

enum GrayjayColors {
    static func color(for sourceName: String) -> Color {
        switch sourceName.lowercased() {
        case let s where s.contains("youtube"):
            return .red
        case let s where s.contains("twitch"):
            return .purple
        case let s where s.contains("rumble"):
            return .orange
        case let s where s.contains("odysee") || s.contains("lbry"):
            return .blue
        default:
            return .green
        }
    }
}

// MARK: - Safe Area Helper

enum SafeArea {
    static var top: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 44
    }
    
    static var bottom: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.bottom
        }
        return 0
    }
}
