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

func alterContentHistoryTable() {
    print("Starting to alter content_history table...")
    
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
        
        // Alter the content_history table to rename is_deleted to is_hidden
        let alterTableQuery = "ALTER TABLE content_history CHANGE COLUMN is_deleted is_hidden BOOLEAN DEFAULT FALSE"
        
        print("Executing ALTER TABLE query...")
        
        // Execute the query
        let resultFuture = connection.query(alterTableQuery)
        _ = try resultFuture.wait()
        print("Table alteration query executed successfully.")
        
        // Verify the table structure
        let describeQuery = "DESCRIBE content_history"
        let describeResult = try connection.query(describeQuery).wait()
        
        print("\nUpdated table structure:")
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
        
        print("\nContent history table altered successfully!")
        
    } catch {
        print("Error: \(error)")
    }
}

// Run the function
alterContentHistoryTable()
