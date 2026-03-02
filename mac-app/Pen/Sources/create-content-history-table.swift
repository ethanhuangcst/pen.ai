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

func createContentHistoryTable() {
    print("Starting to create content_history table...")
    
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
        
        // Create the content_history table
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS content_history (
            uuid VARCHAR(36) PRIMARY KEY,
            user_id VARCHAR(36),
            enhance_datetime DATETIME NOT NULL,
            original_content TEXT NOT NULL,
            enhanced_content TEXT NOT NULL,
            prompt_text TEXT NOT NULL,
            ai_provider VARCHAR(255) NOT NULL,
            is_hidden BOOLEAN DEFAULT FALSE,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
        """
        
        print("Executing CREATE TABLE query...")
        
        // Execute the query
        let resultFuture = connection.query(createTableQuery)
        _ = try resultFuture.wait()
        print("Table creation query executed successfully.")
        
        // Verify the table was created
        let describeQuery = "DESCRIBE content_history"
        let describeResult = try connection.query(describeQuery).wait()
        
        print("\nTable structure:")
        for row in describeResult {
            // Use the same approach as in DatabaseConnectivityPool.swift
            if let field = row.column("Field"), let fieldName = field.string,
               let type = row.column("Type"), let typeName = type.string,
               let nullable = row.column("Null"), let nullableValue = nullable.string,
               let key = row.column("Key"), let keyValue = key.string,
               let defaultValue = row.column("Default"), let defaultValueValue = defaultValue.string,
               let extra = row.column("Extra"), let extraValue = extra.string {
                print("\(fieldName): \(typeName) (Null: \(nullableValue), Key: \(keyValue), Default: \(defaultValueValue), Extra: \(extraValue))")
            }
        }
        
        print("\nContent history table created successfully!")
        
    } catch {
        print("Error: \(error)")
    }
}

// Run the function
createContentHistoryTable()
