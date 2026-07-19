import Foundation

struct PlatformAuthor: Codable {
    let id: String?
    let name: String
    let thumbnail: String?
    let url: String?
}

struct VideoDescriptor: Identifiable, Codable {
    let id: String
    let name: String
    let author: PlatformAuthor
    let url: String
    let thumbnails: [String]?
    let duration: Int?
    let isLive: Bool?
    let viewCount: Int?
    let uploadDate: Int?
    let description: String?
}

/// Helper struct for deserialization from JSContext JSON string
struct PagedResult<T: Codable>: Codable {
    let hasMore: Bool?
    let results: [T]?
}

