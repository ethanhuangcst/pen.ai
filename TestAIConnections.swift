import Foundation
import MySQLKit
import NIO

// Test script to check AI connections for user ID 4

print("Testing AI connections for user ID 4...")

// Database configuration
struct DatabaseConfig {
    static let shared = DatabaseConfig()
    
    let host = "10.0.0.188"
    let port = 3306
    let databaseName = "wingman_db"
    let username = "ethan"
    let password = "ethan123"
}

// Create event loop group
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

do {
    // Create MySQL configuration
    let mysqlConfig = MySQLKit.MySQLConfiguration(
        hostname: DatabaseConfig.shared.host,
        port: DatabaseConfig.shared.port,
        username: DatabaseConfig.shared.username,
        password: DatabaseConfig.shared.password,
        database: DatabaseConfig.shared.databaseName,
        tlsConfiguration: nil
    )
    
    // Connect to MySQL
    let connection = try MySQLKit.MySQLConnection.connect(
        to: mysqlConfig.address(),
        username: mysqlConfig.username,
        database: mysqlConfig.database ?? mysqlConfig.username,
        password: mysqlConfig.password,
        tlsConfiguration: mysqlConfig.tlsConfiguration,
        logger: Logger(label: "com.penai.test"),
        on: eventLoopGroup.next()
    ).wait()
    
    defer {
        try? connection.close().wait()
        try? eventLoopGroup.syncShutdownGracefully()
    }
    
    // Test query: Select all AI connections for user ID 4
    let query = "SELECT * FROM ai_connections WHERE user_id = 4"
    print("Executing query: \(query)")
    
    let rows = try connection.query(query).wait()
    
    print("Number of connections found: \(rows.count)")
    
    for row in rows {
        print("\nConnection found:")
        
        // Print all columns
        if let id = row.column("id")?.int {
            print("id: \(id)")
        }
        if let userId = row.column("user_id")?.int {
            print("user_id: \(userId)")
        }
        if let apiKey = row.column("apiKey")?.string {
            print("apiKey: \(apiKey)")
        }
        if let apiProvider = row.column("apiProvider")?.string {
            print("apiProvider: \(apiProvider)")
        }
        if let createdAt = row.column("createdAt")?.string {
            print("createdAt: \(createdAt)")
        }
        if let updatedAt = row.column("updatedAt")?.string {
            print("updatedAt: \(updatedAt)")
        }
    }
    
} catch {
    print("Error: \(error)")
    try? eventLoopGroup.syncShutdownGracefully()
}
