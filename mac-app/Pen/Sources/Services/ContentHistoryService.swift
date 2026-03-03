import Foundation
import MySQLKit

class ContentHistoryService {
    // MARK: - Singleton
    static let shared = ContentHistoryService()
    private init() {}
    
    // MARK: - Public Methods
    
    /// Get the count of history records for a user
    func readHistoryCount(userID: Int) async -> Result<Int, Error> {
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            return .failure(NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"]))
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        do {
            let query = "SELECT COUNT(*) as count FROM content_history WHERE user_id = ?"
            let parameters: [MySQLData] = [MySQLData(int: userID)]
            
            let result = try await connection.execute(query: query, parameters: parameters)
            
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
    func loadHistoryByUserID(userID: Int, count: Int) async -> Result<[ContentHistoryModel], Error> {
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            return .failure(NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"]))
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        do {
            let query = "SELECT * FROM content_history WHERE user_id = ? ORDER BY enhance_datetime DESC, created_at DESC LIMIT ?"
            let parameters: [MySQLData] = [MySQLData(int: userID), MySQLData(int: count)]
            
            let result = try await connection.execute(query: query, parameters: parameters)
            
            let historyItems = result.map { ContentHistoryModel(from: $0) }
            return .success(historyItems)
        } catch {
            return .failure(error)
        }
    }
    
    /// Add a new history record for a user
    func addToHistoryByUserID(history: ContentHistoryModel, userID: Int) async -> Result<Bool, Error> {
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            return .failure(NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"]))
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        do {
            let query = """
            INSERT INTO content_history (uuid, user_id, enhance_datetime, original_content, enhanced_content, prompt_text, ai_provider, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            let parameters: [MySQLData] = [
                MySQLData(string: history.uuid.uuidString),
                MySQLData(int: userID),
                MySQLData(string: ContentHistoryModel.isoStringFromDate(history.enhanceDateTime)),
                MySQLData(string: history.originalContent),
                MySQLData(string: history.enhancedContent),
                MySQLData(string: history.promptText),
                MySQLData(string: history.aiProvider),
                MySQLData(string: ContentHistoryModel.isoStringFromDate(history.createdAt)),
                MySQLData(string: ContentHistoryModel.isoStringFromDate(history.updatedAt))
            ]
            
            _ = try await connection.execute(query: query, parameters: parameters)
            
            // After adding, check if we need to trim old records
            try await trimHistoryIfNeeded(userID: userID)
            
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    /// Delete all history records for a user
    func resetHistoryByUserID(userID: Int) async -> Result<Bool, Error> {
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            return .failure(NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"]))
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        do {
            let query = "DELETE FROM content_history WHERE user_id = ?"
            let parameters: [MySQLData] = [MySQLData(int: userID)]
            
            _ = try await connection.execute(query: query, parameters: parameters)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Private Methods
    
    /// Trim old history records if the count exceeds the user's limit
    private func trimHistoryIfNeeded(userID: Int) async throws {
        // Get user's history limit from preferences
        let historyLimit = try await getUserHistoryLimit(userID: userID)
        
        // Get current history count
        let currentCountResult = await readHistoryCount(userID: userID)
        guard case .success(let currentCount) = currentCountResult else {
            if case .failure(let error) = currentCountResult {
                throw error
            }
            throw NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get history count"])
        }
        
        if currentCount > historyLimit {
            // Get oldest records to delete
            guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
                throw NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
            }
            defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
            
            let recordsToDelete = currentCount - historyLimit
            let query = """
            DELETE FROM content_history
            WHERE user_id = ?
            ORDER BY enhance_datetime ASC, created_at ASC
            LIMIT ?
            """
            
            let parameters: [MySQLData] = [
                MySQLData(int: userID),
                MySQLData(int: recordsToDelete)
            ]
            
            _ = try await connection.execute(query: query, parameters: parameters)
        }
    }
    
    /// Get the user's history limit from preferences
    public func getUserHistoryLimit(userID: Int) async throws -> Int {
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            throw NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"])
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        let query = "SELECT pen_content_history FROM users WHERE id = ?"
        let parameters: [MySQLData] = [MySQLData(int: userID)]
        
        let result = try await connection.execute(query: query, parameters: parameters)
        
        if let firstRow = result.first, let limit = firstRow["pen_content_history"] as? Int {
            return limit
        } else {
            return 10 // Default limit
        }
    }
    
    // MARK: - Helper Methods
    

}
