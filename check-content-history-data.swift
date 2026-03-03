import Foundation
import MySQLKit
import NIO
import System
import Logging

// Database configuration
struct DBConfig {
    let host: String = "101.132.156.250"
    let port: Int = 33320
    let username: String = "wingmandev"
    let password: String = "Wing123_Man"
    let databaseName: String = "wingman_db"
}

func checkContentHistoryData() {
    print("Starting to check content_history table data...")
    
    let config = DBConfig()
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    defer {
        do {
            try eventLoopGroup.syncShutdownGracefully()
        } catch {
            print("Error shutting down event loop: \(error)")
        }
    }
    
    do {
        // Create MySQL configuration
        let mysqlConfig = MySQLKit.MySQLConfiguration(
            hostname: config.host,
            port: config.port,
            username: config.username,
            password: config.password,
            database: config.databaseName,
            tlsConfiguration: nil
        )
        
        // Get socket address
        let address = try mysqlConfig.address()
        
        // Create logger
        var logger = Logger(label: "com.penai.mysql")
        logger.logLevel = .debug
        
        // Create connection
        let connectionFuture = MySQLKit.MySQLConnection.connect(
            to: address,
            username: mysqlConfig.username,
            database: mysqlConfig.database ?? mysqlConfig.username,
            password: mysqlConfig.password,
            tlsConfiguration: mysqlConfig.tlsConfiguration,
            logger: logger,
            on: eventLoopGroup.next()
        )
        
        // Wait for connection
        let connection = try connectionFuture.wait()
        print("Connected to database successfully!")
        
        defer {
            do {
                try connection.close().wait()
                print("Connection closed.")
            } catch {
                print("Error closing connection: \(error)")
            }
        }
        
        // Check the content_history table structure
        let describeQuery = "DESCRIBE content_history"
        print("\nExecuting DESCRIBE content_history...")
        let describeResult = try connection.query(describeQuery).wait()
        
        print("\nTable structure:")
        for row in describeResult {
            if let field = row.column("Field"), let fieldName = field.string,
               let type = row.column("Type"), let typeName = type.string {
                print("\(fieldName): \(typeName)")
            }
        }
        
        // Query the content_history table data
        let dataQuery = "SELECT * FROM content_history ORDER BY enhance_datetime DESC LIMIT 5"
        print("\nExecuting SELECT * FROM content_history...")
        let dataResult = try connection.query(dataQuery).wait()
        
        print("\nContent history data:")
        var count = 1
        for row in dataResult {
            print("\nRow \(count):")
            count += 1
            
            if let uuid = row.column("uuid"), let uuidValue = uuid.string {
                print("  UUID: \(uuidValue)")
            }
            if let user_id = row.column("user_id"), let user_idValue = user_id.string {
                print("  User ID: \(user_idValue)")
            }
            if let enhance_datetime = row.column("enhance_datetime"), let enhance_datetimeValue = enhance_datetime.string {
                print("  Enhance Datetime: \(enhance_datetimeValue)")
            }
            if let created_at = row.column("created_at"), let created_atValue = created_at.string {
                print("  Created At: \(created_atValue)")
            }
            if let enhanced_content = row.column("enhanced_content"), let enhanced_contentValue = enhanced_content.string {
                print("  Enhanced Content: \(enhanced_contentValue.prefix(100))...")
            }
        }
        
        print("\nContent history data check completed!")
        
    } catch {
        print("Error: \(error)")
    }
}

// Run the function
checkContentHistoryData()