import Foundation
import MySQLKit

class ContentHistoryService {
    // MARK: - Singleton
    static let shared = ContentHistoryService()
    private init() {}
    
    // MARK: - Public Methods
    
    /// Get the count of non-deleted history records for a user
    func readHistoryCount(userID: UUID) -> Result<Int, Error> {
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            return .failure(NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"]))
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        do {
            let query = "SELECT COUNT(*) as count FROM content_history WHERE user_id = ? AND is_hidden = FALSE"
            let parameters: [MySQLData] = [MySQLData(string: userID.uuidString)]
            
            let result = try connection.execute(query: query, parameters: parameters).get()
            
            if let firstRow = result.first, let count = firstRow["count"] as? Int {
                return .success(count)
            } else {
                return .success(0)
            }
        } catch {
            return .failure(error)
        }
    }
    
    /// Load recent history records for a user, sorted by date (most recent first)
    func loadHistoryByUserID(userID: UUID, count: Int) -> Result<[ContentHistoryModel], Error> {
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            return .failure(NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"]))
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        do {
            let query = "SELECT * FROM content_history WHERE user_id = ? AND is_hidden = FALSE ORDER BY enhance_datetime DESC LIMIT ?"
            let parameters: [MySQLData] = [MySQLData(string: userID.uuidString), MySQLData(int: count)]
            
            let result = try connection.execute(query: query, parameters: parameters).get()
            
            let historyItems = result.map { ContentHistoryModel(from: $0) }
            return .success(historyItems)
        } catch {
            return .failure(error)
        }
    }
    
    /// Add a new history record for a user
    func addToHistoryByUserID(history: ContentHistoryModel, userID: UUID) -> Result<Bool, Error> {
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            return .failure(NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"]))
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        do {
            let query = """
            INSERT INTO content_history (uuid, user_id, enhance_datetime, original_content, enhanced_content, prompt_text, ai_provider, is_hidden, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            let parameters: [MySQLData] = [
                MySQLData(string: history.uuid.uuidString),
                MySQLData(string: history.userID.uuidString),
                MySQLData(string: ContentHistoryService.isoStringFromDate(history.enhanceDateTime)),
                MySQLData(string: history.originalContent),
                MySQLData(string: history.enhancedContent),
                MySQLData(string: history.promptText),
                MySQLData(string: history.aiProvider),
                MySQLData(bool: history.isHidden),
                MySQLData(string: ContentHistoryService.isoStringFromDate(history.createdAt)),
                MySQLData(string: ContentHistoryService.isoStringFromDate(history.updatedAt))
            ]
            
            _ = try connection.execute(query: query, parameters: parameters).get()
            
            // After adding, check if we need to trim old records
            try trimHistoryIfNeeded(userID: userID)
            
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    /// Soft delete all history records for a user
    func resetHistoryByUserID(userID: UUID) -> Result<Bool, Error> {
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            return .failure(NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"]))
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        do {
            let query = "UPDATE content_history SET is_hidden = TRUE WHERE user_id = ? AND is_hidden = FALSE"
            let parameters: [MySQLData] = [MySQLData(string: userID.uuidString)]
            
            _ = try connection.execute(query: query, parameters: parameters).get()
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Private Methods
    
    /// Trim old history records if the count exceeds the user's limit
    private func trimHistoryIfNeeded(userID: UUID) throws {
        // Get user's history limit from preferences
        let historyLimit = try getUserHistoryLimit(userID: userID)
        
        // Get current history count
        let currentCount = try readHistoryCount(userID: userID).get()
        
        if currentCount > historyLimit {
            // Get oldest records to delete
            guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
                throw NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
            
            let recordsToDelete = currentCount - historyLimit
            let query = """
            UPDATE content_history
            SET is_hidden = TRUE
            WHERE user_id = ? AND is_hidden = FALSE
            ORDER BY enhance_datetime ASC
            LIMIT ?
            """
            
            let parameters: [MySQLData] = [
                MySQLData(string: userID.uuidString),
                MySQLData(int: recordsToDelete)
            ]
            
            _ = try connection.execute(query: query, parameters: parameters).get()
        }
    }
    
    /// Get the user's history limit from preferences
    private func getUserHistoryLimit(userID: UUID) throws -> Int {
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            throw NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        let query = "SELECT pen_content_history FROM users WHERE id = ?"
        let parameters: [MySQLData] = [MySQLData(string: userID.uuidString)]
        
        let result = try connection.execute(query: query, parameters: parameters).get()
        
        if let firstRow = result.first, let limit = firstRow["pen_content_history"] as? Int {
            return limit
        } else {
            return 10 // Default limit
        }
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to convert Date to ISO string (made public for use in ContentHistoryModel)
    public static func isoStringFromDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
    /// Helper method to convert ISO string to Date (made public for use in ContentHistoryModel)
    public static func dateFromISOString(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }
}
