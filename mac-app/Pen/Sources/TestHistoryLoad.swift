import Foundation
import MySQLKit
import NIO
import System
import Logging

// Database configuration struct for this script
struct DatabaseConfig {
    let host: String = "101.132.156.250"
    let port: Int = 33320
    let username: String = "wingmandev"
    let password: String = "Wing123_Man"
    let databaseName: String = "wingman_db"
}

// Simple test script to directly query the content_history table
func testHistoryLoad() async {
    print("Testing content history load...")
    
    // Create database configuration
    let config = DatabaseConfig()
    
    // Create event loop group
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    defer { try? eventLoopGroup.syncShutdownGracefully() }
    
    do {
        // Create MySQL configuration
        let mysqlConfig = MySQLConfiguration(
            hostname: config.host,
            port: config.port,
            username: config.username,
            password: config.password,
            database: config.databaseName,
            tlsConfiguration: nil
        )
        
        // Connect to MySQL
        let connection = try await MySQLConnection.connect(
            to: mysqlConfig.address(),
            username: mysqlConfig.username,
            database: mysqlConfig.database ?? mysqlConfig.username,
            password: mysqlConfig.password,
            tlsConfiguration: mysqlConfig.tlsConfiguration,
            logger: Logger(label: "com.penai.test"),
            on: eventLoopGroup.next()
        )
        defer { try? connection.close().wait() }
        
        // Query content_history table
        let query = "SELECT * FROM content_history WHERE user_id = ? ORDER BY enhance_datetime DESC LIMIT 100"
        let parameters: [MySQLData] = [MySQLData(int: 4)]
        
        let rows = try await connection.query(query, parameters).get()
        
        print("Found \(rows.count) rows in content_history table")
        
        for (index, row) in rows.enumerated() {
            print("\nRow \(index + 1):")
            
            // Print all columns
            if let idData = row.column("id"), let id = idData.int {
                print("  ID: \(id)")
            }
            if let userIdData = row.column("user_id"), let userId = userIdData.int {
                print("  User ID: \(userId)")
            }
            if let uuidData = row.column("uuid"), let uuid = uuidData.string {
                print("  UUID: \(uuid)")
            }
            if let enhanceDatetimeData = row.column("enhance_datetime"), let enhanceDatetime = enhanceDatetimeData.string {
                print("  Enhance DateTime: \(enhanceDatetime)")
            }
            if let originalContentData = row.column("original_content"), let originalContent = originalContentData.string {
                print("  Original Content length: \(originalContent.count)")
                print("  Original Content: \(originalContent.prefix(50))...")
            }
            if let enhancedContentData = row.column("enhanced_content"), let enhancedContent = enhancedContentData.string {
                print("  Enhanced Content length: \(enhancedContent.count)")
                print("  Enhanced Content: \(enhancedContent.prefix(50))...")
            }
            if let promptTextData = row.column("prompt_text"), let promptText = promptTextData.string {
                print("  Prompt Text length: \(promptText.count)")
                print("  Prompt Text: \(promptText.prefix(50))...")
            }
            if let aiProviderData = row.column("ai_provider"), let aiProvider = aiProviderData.string {
                print("  AI Provider: \(aiProvider)")
            }
        }
        
    } catch {
        print("Error: \(error)")
    }
}

// Run the test
Task {
    await testHistoryLoad()
    print("\nTest completed.")
    exit(0)
}

// Keep the program running until the task completes
RunLoop.main.run()
