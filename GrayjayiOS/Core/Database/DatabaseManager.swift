import Foundation
import GRDB

struct Subscription: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: String { url }
    let pluginId: String
    let url: String
    let name: String
    let thumbnail: String?
}

struct WatchHistory: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: String { url }
    let pluginId: String
    let url: String
    let name: String
    let authorName: String
    let thumbnail: String?
    let timestamp: Date
}

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var dbQueue: DatabaseQueue!
    
    init() {
        do {
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let databaseURL = appSupportURL.appendingPathComponent("grayjay.sqlite")
            
            dbQueue = try DatabaseQueue(path: databaseURL.path)
            try setupDatabase()
        } catch {
            print("Failed to initialize database: \(error)")
        }
    }
    
    private func setupDatabase() throws {
        try dbQueue.write { db in
            try db.create(table: "subscription", ifNotExists: true) { t in
                t.column("pluginId", .text).notNull()
                t.column("url", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("thumbnail", .text)
            }
            
            try db.create(table: "watchHistory", ifNotExists: true) { t in
                t.column("pluginId", .text).notNull()
                t.column("url", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("authorName", .text).notNull()
                t.column("thumbnail", .text)
                t.column("timestamp", .datetime).notNull()
            }
        }
    }
    
    // MARK: - Subscriptions
    
    func subscribe(pluginId: String, url: String, name: String, thumbnail: String?) {
        do {
            try dbQueue.write { db in
                let sub = Subscription(pluginId: pluginId, url: url, name: name, thumbnail: thumbnail)
                try sub.save(db)
            }
            NotificationCenter.default.post(name: NSNotification.Name("SubscriptionsUpdated"), object: nil)
        } catch {
            print("Failed to save subscription: \(error)")
        }
    }
    
    func unsubscribe(url: String) {
        do {
            try dbQueue.write { db in
                _ = try Subscription.deleteOne(db, key: ["url": url])
            }
            NotificationCenter.default.post(name: NSNotification.Name("SubscriptionsUpdated"), object: nil)
        } catch {
            print("Failed to delete subscription: \(error)")
        }
    }
    
    func isSubscribed(url: String) -> Bool {
        do {
            return try dbQueue.read { db in
                try Subscription.fetchOne(db, key: ["url": url]) != nil
            }
        } catch {
            return false
        }
    }
    
    func getSubscriptions() -> [Subscription] {
        do {
            return try dbQueue.read { db in
                try Subscription.fetchAll(db)
            }
        } catch {
            return []
        }
    }
    
    // MARK: - Watch History
    
    func addToHistory(pluginId: String, url: String, name: String, authorName: String, thumbnail: String?) {
        do {
            try dbQueue.write { db in
                let history = WatchHistory(pluginId: pluginId, url: url, name: name, authorName: authorName, thumbnail: thumbnail, timestamp: Date())
                try history.save(db)
            }
        } catch {
            print("Failed to save history: \(error)")
        }
    }
    
    func getHistory() -> [WatchHistory] {
        do {
            return try dbQueue.read { db in
                try WatchHistory.order(Column("timestamp").desc).fetchAll(db)
            }
        } catch {
            return []
        }
    }
}
