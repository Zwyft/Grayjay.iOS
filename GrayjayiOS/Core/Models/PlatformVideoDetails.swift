import Foundation

struct VideoUrlSource: Codable {
    let name: String?
    let url: String
    let container: String? // e.g. "application/x-mpegURL" or "video/mp4"
    let width: Int?
    let height: Int?
}

struct VideoSourceDescriptor: Codable {
    let videoSources: [VideoUrlSource]?
}

struct PlatformVideoDetails: Codable {
    let video: VideoSourceDescriptor?
}
