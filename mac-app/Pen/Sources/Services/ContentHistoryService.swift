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
            // Use a different approach - get all records and count them
            let query = "SELECT uuid FROM content_history WHERE user_id = ?"
            let parameters: [MySQLData] = [MySQLData(string: "\(userID)")] // Convert to string to match table schema
            
            let result = try await connection.execute(query: query, parameters: parameters)
            
            // Count the number of rows returned
            let count = result.count
            print("ContentHistoryService: History count for user \(userID): \(count)")
            return .success(count)
        } catch {
            print("ContentHistoryService: Error getting history count: \(error)")
            return .failure(error)
        }
    }
    
    /// Load recent history records for a user, sorted by date (most recent first)
    func loadHistoryByUserID(userID: Int, count: Int) async -> Result<[ContentHistoryModel], Error> {
        print("========== ContentHistoryService.loadHistoryByUserID START ==========")
        print("[ContentHistoryService] userID: \(userID), count: \(count)")
        fflush(stdout)
        
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            print("[ContentHistoryService] ERROR: Failed to get database connection")
            fflush(stdout)
            return .failure(NSError(domain: "ContentHistoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get database connection"]))
        }
        defer { DatabaseConnectivityPool.shared.returnConnection(connection) }
        
        do {
            let query = "SELECT * FROM content_history WHERE user_id = ? ORDER BY enhance_datetime DESC, created_at DESC LIMIT ?"
            let parameters: [MySQLData] = [MySQLData(string: "\(userID)"), MySQLData(int: count)]
            
            let result = try await connection.execute(query: query, parameters: parameters)
            
            let historyItems = result.map { ContentHistoryModel(from: $0) }
            return .success(historyItems)
        } catch {
            print("[ContentHistoryService] Error loading history: \(error)")
            fflush(stdout)
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
            print("ContentHistoryService: Adding new history item for user \(userID)")
            let query = """
            INSERT INTO content_history (uuid, user_id, enhance_datetime, original_content, enhanced_content, prompt_text, ai_provider, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            let parameters: [MySQLData] = [
                MySQLData(string: history.uuid.uuidString),
                MySQLData(string: "\(userID)"), // Convert to string to match table schema
                MySQLData(string: ContentHistoryModel.isoStringFromDate(history.enhanceDateTime)),
                MySQLData(string: history.originalContent),
                MySQLData(string: history.enhancedContent),
                MySQLData(string: history.promptText),
                MySQLData(string: history.aiProvider),
                MySQLData(string: ContentHistoryModel.isoStringFromDate(history.createdAt)),
                MySQLData(string: ContentHistoryModel.isoStringFromDate(history.updatedAt))
            ]
            
            _ = try await connection.execute(query: query, parameters: parameters)
            print("ContentHistoryService: Added new history item")
            
            // After adding, check if we need to trim old records
            print("ContentHistoryService: Calling trimHistoryIfNeeded")
            await trimHistoryIfNeeded(userID: userID)
            print("ContentHistoryService: trimHistoryIfNeeded completed")
            
            return .success(true)
        } catch {
            print("ContentHistoryService: Error adding history item: \(error)")
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
    private func trimHistoryIfNeeded(userID: Int) async {
        do {
            // Get user's history limit from preferences
            let historyLimit = try await getUserHistoryLimit(userID: userID)
            
            // Get current history count
            let currentCountResult = await readHistoryCount(userID: userID)
            guard case .success(let currentCount) = currentCountResult else {
                if case .failure(let error) = currentCountResult {
                    print("ContentHistoryService: Error getting history count: \(error)")
                }
                return
            }
            
            if currentCount > historyLimit {
                // Get oldest records to delete
                guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
                    print("ContentHistoryService: Failed to get database connection for trimming")
                    return
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
                    MySQLData(string: "\(userID)"), // Convert to string to match table schema
                    MySQLData(int: recordsToDelete)
                ]
                
                _ = try await connection.execute(query: query, parameters: parameters)
                print("ContentHistoryService: Trimmed \(recordsToDelete) records for user \(userID)")
            }
        } catch {
            print("ContentHistoryService: Error in trimHistoryIfNeeded: \(error)")
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
            print("ContentHistoryService: Found history limit \(limit) for user \(userID)")
            return limit
        } else {
            print("ContentHistoryService: No history limit found for user \(userID), using default 40")
            return 40 // Default limit
        }
    }
    
    // MARK: - Helper Methods
    
    /// Test method to verify readHistoryCount works correctly
    public func testReadHistoryCount(userID: Int) async {
        print("\n=== Testing readHistoryCount for user \(userID) ===")
        let result = await readHistoryCount(userID: userID)
        switch result {
        case .success(let count):
            print("Test result: Success, count = \(count)")
        case .failure(let error):
            print("Test result: Failure, error = \(error)")
        }
        print("=====================================\n")
    }

}
