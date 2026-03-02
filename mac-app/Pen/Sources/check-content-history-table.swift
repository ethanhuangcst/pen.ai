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

func checkContentHistoryTable() {
    print("Checking content_history table structure...")
    
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
        
        // Check if the table exists
        let checkTableQuery = "SHOW TABLES LIKE 'content_history'"
        let checkTableResult = try connection.query(checkTableQuery).wait()
        
        if checkTableResult.isEmpty {
            print("Table content_history does not exist.")
            return
        }
        
        print("Table content_history exists.")
        
        // Get full table structure
        let describeQuery = "DESCRIBE content_history"
        let describeResult = try connection.query(describeQuery).wait()
        
        print("\nFull table structure:")
        print("| Field | Type | Null | Key | Default | Extra |")
        print("|-------|------|------|-----|---------|-------|")
        
        for row in describeResult {
            // Extract all columns
            let field = row.column("Field")?.string ?? ""
            let type = row.column("Type")?.string ?? ""
            let nullable = row.column("Null")?.string ?? ""
            let key = row.column("Key")?.string ?? ""
            let defaultValue = row.column("Default")?.string ?? ""
            let extra = row.column("Extra")?.string ?? ""
            
            print("| \(field) | \(type) | \(nullable) | \(key) | \(defaultValue) | \(extra) |")
        }
        
        // Also check with SHOW CREATE TABLE
        let showCreateQuery = "SHOW CREATE TABLE content_history"
        let showCreateResult = try connection.query(showCreateQuery).wait()
        
        print("\nCREATE TABLE statement:")
        for row in showCreateResult {
            if let createStatement = row.column("Create Table")?.string {
                print(createStatement)
            }
        }
        
    } catch {
        print("Error: \(error)")
    }
}

// Run the function
checkContentHistoryTable()
