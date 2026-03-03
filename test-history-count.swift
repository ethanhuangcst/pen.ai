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

func testHistoryCount() {
    print("Testing history count...")
    
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
        
        // Test 1: Count all history records
        print("\nTest 1: Count all history records")
        let countAllQuery = "SELECT COUNT(*) as count FROM content_history"
        let countAllResult = try connection.query(countAllQuery).wait()
        if let firstRow = countAllResult.first {
            print("Total history records: \(firstRow["count"] ?? "nil")")
        }
        
        // Test 2: Count records for user 4 as string
        print("\nTest 2: Count records for user '4' (string)")
        let countUser4StringQuery = "SELECT COUNT(*) as count FROM content_history WHERE user_id = '4'"
        let countUser4StringResult = try connection.query(countUser4StringQuery).wait()
        if let firstRow = countUser4StringResult.first {
            print("History records for user '4': \(firstRow["count"] ?? "nil")")
        }
        
        // Test 3: Count records for user 4 as int
        print("\nTest 3: Count records for user 4 (int)")
        let countUser4IntQuery = "SELECT COUNT(*) as count FROM content_history WHERE user_id = 4"
        let countUser4IntResult = try connection.query(countUser4IntQuery).wait()
        if let firstRow = countUser4IntResult.first {
            print("History records for user 4: \(firstRow["count"] ?? "nil")")
        }
        
        // Test 4: Check table structure
        print("\nTest 4: Table structure")
        let describeQuery = "DESCRIBE content_history"
        let describeResult = try connection.query(describeQuery).wait()
        for row in describeResult {
            if let field = row.column("Field"), let fieldName = field.string,
               let type = row.column("Type"), let typeName = type.string {
                print("\(fieldName): \(typeName)")
            }
        }
        
        // Test 5: Sample records
        print("\nTest 5: Sample records")
        let sampleQuery = "SELECT * FROM content_history LIMIT 5"
        let sampleResult = try connection.query(sampleQuery).wait()
        for (index, row) in sampleResult.enumerated() {
            print("\nRecord \(index + 1):")
            print("  user_id: \(row["user_id"] ?? "nil")")
            print("  uuid: \(row["uuid"] ?? "nil")")
            print("  enhance_datetime: \(row["enhance_datetime"] ?? "nil")")
        }
        
    } catch {
        print("Error: \(error)")
    }
}

// Run the function
testHistoryCount()
