import Foundation

struct VideoDescriptor: Identifiable, Codable {
    let id: String
    let name: String
    let author: String
    let authorId: String?
    let authorUrl: String?
    let url: String
    let thumbnails: [String]?
    let duration: Int?
    let isLive: Bool?
    let viewCount: Int?
    let uploadDate: Int?
    let description: String?
    
    // Coding keys to match JS object if needed, though we will parse manually from JSContext dictionary
}

/// Helper struct for deserialization from JSContext JSON string
struct PagedResult<T: Codable>: Codable {
    let hasMore: Bool
    let results: [T]
}
