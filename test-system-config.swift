import Foundation
import MySQLKit
import NIO
import System

// Database configuration
struct DatabaseConfig {
    let host = "101.132.156.250"
    let port = 33320
    let username = "wingmandev"
    let password = "Wing123_Man"
    let database = "wingman_db"
}

class SystemConfigTest {
    private let config = DatabaseConfig()
    private var connection: MySQLKit.MySQLConnection?
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    deinit {
        do {
            try eventLoopGroup.syncShutdownGracefully()
        } catch {
            print("Error shutting down event loop: \(error)")
        }
    }
    
    func testSystemConfig() async throws {
        print("Testing system configuration loading...")
        
        // Connect to database
        try await connect()
        
        // Query system config
        try await querySystemConfig()
        
        // Close connection
        try await disconnect()
    }
    
    private func connect() async throws {
        print("Connecting to database...")
        
        let mysqlConfig = MySQLKit.MySQLConfiguration(
            hostname: config.host,
            port: config.port,
            username: config.username,
            password: config.password,
            database: config.database,
            tlsConfiguration: nil
        )
        
        let address = try mysqlConfig.address()
        
        var logger = Logger(label: "com.penai.mysql")
        logger.logLevel = .debug
        
        let connectionFuture = MySQLKit.MySQLConnection.connect(
            to: address,
            username: mysqlConfig.username,
            database: mysqlConfig.database ?? mysqlConfig.username,
            password: mysqlConfig.password,
            tlsConfiguration: mysqlConfig.tlsConfiguration,
            logger: logger,
            on: eventLoopGroup.next()
        )
        
        connection = try await connectionFuture.get()
        print("Connected successfully!")
    }
    
    private func querySystemConfig() async throws {
        guard let connection = connection else {
            throw NSError(domain: "SystemConfigTest", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected to database"])
        }
        
        print("Querying system_config table...")
        
        let query = "SELECT default_prompt_name, default_prompt_text, content_history_count_low, content_history_count_medium, content_history_count_high FROM system_config LIMIT 1"
        
        let rows = try await connection.query(query).get()
        
        if let row = rows.first {
            // Parse the row
            var rowData: [String: Any] = [:]
            
            // Parse default prompt columns
            if let defaultPromptNameData = row.column("default_prompt_name"), let defaultPromptName = defaultPromptNameData.string {
                rowData["default_prompt_name"] = defaultPromptName
            }
            if let defaultPromptTextData = row.column("default_prompt_text"), let defaultPromptText = defaultPromptTextData.string {
                rowData["default_prompt_text"] = defaultPromptText
            }
            if let contentHistoryCountLowData = row.column("content_history_count_low"), let contentHistoryCountLow = contentHistoryCountLowData.int {
                rowData["content_history_count_low"] = contentHistoryCountLow
            }
            if let contentHistoryCountMediumData = row.column("content_history_count_medium"), let contentHistoryCountMedium = contentHistoryCountMediumData.int {
                rowData["content_history_count_medium"] = contentHistoryCountMedium
            }
            if let contentHistoryCountHighData = row.column("content_history_count_high"), let contentHistoryCountHigh = contentHistoryCountHighData.int {
                rowData["content_history_count_high"] = contentHistoryCountHigh
            }
            
            // Print results
            print("\n=== System Configuration ===")
            print("Default Prompt Name: \(rowData["default_prompt_name"] ?? "nil")")
            print("Default Prompt Text: \(rowData["default_prompt_text"] ?? "nil")")
            print("Content History Count Low: \(rowData["content_history_count_low"] ?? "nil")")
            print("Content History Count Medium: \(rowData["content_history_count_medium"] ?? "nil")")
            print("Content History Count High: \(rowData["content_history_count_high"] ?? "nil")")
        } else {
            print("No system_config record found")
        }
    }
    
    private func disconnect() async throws {
        guard let connection = connection else {
            return
        }
        
        print("Disconnecting from database...")
        try await connection.close().get()
        print("Disconnected successfully!")
    }
}

// Run the test
Task {
    let test = SystemConfigTest()
    do {
        try await test.testSystemConfig()
        print("\nTest completed successfully!")
    } catch {
        print("Test failed: \(error)")
    }
    
    // Exit the process
    exit(0)
}

// Wait for the task to complete
RunLoop.main.run()
