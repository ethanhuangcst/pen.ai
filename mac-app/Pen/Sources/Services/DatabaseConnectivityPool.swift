import Foundation
import MySQLKit
import NIO
import System
import Logging

// Protocol for database connection
protocol DatabaseConnection {
    var id: UUID { get }
    var isConnected: Bool { get }
    func close()
    func execute(query: String, parameters: [MySQLData]) async throws -> [[String: Any]]
    func execute(query: String) async throws -> [[String: Any]]
    func beginTransaction() async throws
    func commitTransaction() async throws
    func rollbackTransaction() async throws
}

// MySQL database connection implementation using MySQLKit
class MySQLConnection: DatabaseConnection {
    let id = UUID()
    var isConnected: Bool = false
    
    private let config: DatabaseConfig
    private var connection: MySQLKit.MySQLConnection?
    private let eventLoopGroup: EventLoopGroup
    
    init() {
        self.config = DatabaseConfig.shared
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        connect()
    }
    
    private func connect() {
        print("[MySQLConnection] Connecting to database...")
        
        do {
            // Create MySQL configuration with TLS disabled for development
            let mysqlConfig = MySQLKit.MySQLConfiguration(
                hostname: config.host,
                port: config.port,
                username: config.username,
                password: config.password,
                database: config.databaseName,
                tlsConfiguration: nil
            )
            
            // Get socket address from configuration
            let address = try mysqlConfig.address()
            
            // Create logger
            var logger = Logger(label: "com.penai.mysql")
            logger.logLevel = .debug
            
            // Connect to MySQL
            let connectionFuture = MySQLKit.MySQLConnection.connect(
                to: address,
                username: mysqlConfig.username,
                database: mysqlConfig.database ?? mysqlConfig.username,
                password: mysqlConfig.password,
                tlsConfiguration: mysqlConfig.tlsConfiguration,
                logger: logger,
                on: eventLoopGroup.next()
            )
            
            self.connection = try connectionFuture.wait()
            isConnected = true
            print("[MySQLConnection] Connected successfully")
        } catch {
            print("[MySQLConnection] Connection failed: \(error)")
            isConnected = false
        }
    }
    
    func execute(query: String, parameters: [MySQLData]) async throws -> [[String: Any]] {
        guard isConnected, let connection = connection else {
            throw NSError(domain: "MySQLConnection", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected to database"])
        }
        
        do {
            // Execute the query
            let rows = try await connection.query(query, parameters).get()
            
            // Process the result
            var resultRows: [[String: Any]] = []
            
            for (rowIndex, row) in rows.enumerated() {
                var rowData: [String: Any] = [:]

                // Process all columns dynamically
                // First, try common columns
                if let idData = row.column("id") {
                    if let id = idData.string {
                        rowData["id"] = id
                    } else if let id = idData.int {
                        rowData["id"] = id
                    }
                }
                if let nameData = row.column("name"), let name = nameData.string {
                    rowData["name"] = name
                }
                if let emailData = row.column("email"), let email = emailData.string {
                    rowData["email"] = email
                }
                if let passwordData = row.column("password"), let password = passwordData.string {
                    rowData["password"] = password
                }
                if let passwordHashData = row.column("password_hash"), let passwordHash = passwordHashData.string {
                    rowData["password_hash"] = passwordHash
                }
                if let profileImageData = row.column("profileImage"), let profileImage = profileImageData.string {
                    rowData["profileImage"] = profileImage
                }
                if let createdAtData = row.column("createdAt"), let createdAt = createdAtData.string {
                    rowData["createdAt"] = createdAt
                }
                if let systemFlagData = row.column("system_flag"), let systemFlag = systemFlagData.string {
                    rowData["system_flag"] = systemFlag
                }
                
                // Add any additional columns that might be present in DESCRIBE query
                if let fieldData = row.column("Field"), let field = fieldData.string {
                    rowData["Field"] = field
                }
                if let typeData = row.column("Type"), let type = typeData.string {
                    rowData["Type"] = type
                }
                if let nullData = row.column("Null"), let nullable = nullData.string {
                    rowData["Null"] = nullable
                }
                if let keyData = row.column("Key"), let key = keyData.string {
                    rowData["Key"] = key
                }
                if let defaultData = row.column("Default"), let defaultValue = defaultData.string {
                    rowData["Default"] = defaultValue
                }
                if let extraData = row.column("Extra"), let extra = extraData.string {
                    rowData["Extra"] = extra
                }
                if let columnNameData = row.column("COLUMN_NAME"), let columnName = columnNameData.string {
                    rowData["COLUMN_NAME"] = columnName
                }
                
                // Add AI provider specific columns
                if let baseURLsData = row.column("base_urls"), let baseURLs = baseURLsData.string {
                    rowData["base_urls"] = baseURLs
                }
                if let defaultModelData = row.column("default_model"), let defaultModel = defaultModelData.string {
                    rowData["default_model"] = defaultModel
                }
                if let requiresAuthData = row.column("requires_auth"), let requiresAuth = requiresAuthData.int {
                    rowData["requires_auth"] = requiresAuth
                }
                if let authHeaderData = row.column("auth_header"), let authHeader = authHeaderData.string {
                    rowData["auth_header"] = authHeader
                }
                if let createdAtData = row.column("created_at"), let createdAt = createdAtData.string {
                    rowData["created_at"] = createdAt
                }
                if let updatedAtData = row.column("updated_at"), let updatedAt = updatedAtData.string {
                    rowData["updated_at"] = updatedAt
                }
                
                // Add common columns for all tables
                if let userIdData = row.column("user_id"), let userId = userIdData.int {
                    rowData["user_id"] = userId
                }
                if let penContentHistoryData = row.column("pen_content_history"), let penContentHistory = penContentHistoryData.int {
                    rowData["pen_content_history"] = penContentHistory
                }
                
                // Add AI connection specific columns
                if let apiKeyData = row.column("apiKey"), let apiKey = apiKeyData.string {
                    rowData["apiKey"] = apiKey
                }
                if let apiProviderData = row.column("apiProvider"), let apiProvider = apiProviderData.string {
                    rowData["apiProvider"] = apiProvider
                }
                if let createdAtData = row.column("createdAt"), let createdAt = createdAtData.string {
                    rowData["createdAt"] = createdAt
                }
                if let updatedAtData = row.column("updatedAt"), let updatedAt = updatedAtData.string {
                    rowData["updatedAt"] = updatedAt
                }
                
                // Add prompt specific columns
                if let promptNameData = row.column("prompt_name"), let promptName = promptNameData.string {
                    rowData["prompt_name"] = promptName
                }
                if let promptTextData = row.column("prompt_text"), let promptText = promptTextData.string {
                    rowData["prompt_text"] = promptText
                }
                if let createdDatetimeData = row.column("created_datetime"), let createdDatetime = createdDatetimeData.string {
                    rowData["created_datetime"] = createdDatetime
                }
                if let updatedDatetimeData = row.column("updated_datetime"), let updatedDatetime = updatedDatetimeData.string {
                    rowData["updated_datetime"] = updatedDatetime
                }
                if let systemFlagData = row.column("system_flag"), let systemFlag = systemFlagData.string {
                    rowData["system_flag"] = systemFlag
                }
                if let isDefaultData = row.column("is_default"), let isDefault = isDefaultData.int {
                    rowData["is_default"] = isDefault
                }
                
                // Add system config specific columns
                if let defaultPromptNameData = row.column("default_prompt_name"), let defaultPromptName = defaultPromptNameData.string {
                    rowData["default_prompt_name"] = defaultPromptName
                }
                // Handle TEXT column for default_prompt_text
                if let defaultPromptTextData = row.column("default_prompt_text") {
                    // Try to get as string directly
                    if let defaultPromptText = defaultPromptTextData.string {
                        rowData["default_prompt_text"] = defaultPromptText
                    } else {
                        // For TEXT columns, try to convert to string using description
                        let description = defaultPromptTextData.description
                        // Remove any surrounding quotes or formatting
                        let cleanedDescription = description.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                        if !cleanedDescription.isEmpty {
                            rowData["default_prompt_text"] = cleanedDescription
                        }
                    }
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
                
                // Add content history specific columns
                if let originalContentData = row.column("original_content"), let originalContent = originalContentData.string {
                    rowData["original_content"] = originalContent
                }
                if let enhancedContentData = row.column("enhanced_content"), let enhancedContent = enhancedContentData.string {
                    rowData["enhanced_content"] = enhancedContent
                }
                if let promptTextData = row.column("prompt_text"), let promptText = promptTextData.string {
                    rowData["prompt_text"] = promptText
                }
                if let aiProviderData = row.column("ai_provider"), let aiProvider = aiProviderData.string {
                    rowData["ai_provider"] = aiProvider
                }
                if let enhanceDatetimeData = row.column("enhance_datetime") {
                    if let enhanceDatetime = enhanceDatetimeData.string {
                        rowData["enhance_datetime"] = enhanceDatetime
                    } else {
                        let description = enhanceDatetimeData.description
                        rowData["enhance_datetime"] = description
                    }
                }
                if let uuidData = row.column("uuid"), let uuid = uuidData.string {
                    rowData["uuid"] = uuid
                }
                
                // Try to get all other columns (for JSON columns like base_urls)
                // We'll try common column names that might be present
                let possibleColumns = ["base_urls", "config", "metadata", "settings"]
                for columnName in possibleColumns {
                    if !rowData.keys.contains(columnName), let columnData = row.column(columnName) {
                        if let stringValue = columnData.string {
                            rowData[columnName] = stringValue
                        }
                    }
                }
                
                resultRows.append(rowData)
            }
            
            return resultRows
        } catch {
            print("[MySQLConnection] Query failed: \(error)")
            throw error
        }
    }
    
    /// Begins a transaction
    func beginTransaction() async throws {
        guard isConnected else {
            throw NSError(domain: "MySQLConnection", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected to database"])
        }
        
        print("[MySQLConnection] Beginning transaction")
        
        do {
            let query = "START TRANSACTION"
            _ = try await execute(query: query)
        } catch {
            print("[MySQLConnection] Failed to begin transaction: \(error)")
            throw error
        }
    }
    
    /// Commits a transaction
    func commitTransaction() async throws {
        guard isConnected else {
            throw NSError(domain: "MySQLConnection", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected to database"])
        }
        
        print("[MySQLConnection] Committing transaction")
        
        do {
            let query = "COMMIT"
            _ = try await execute(query: query)
        } catch {
            print("[MySQLConnection] Failed to commit transaction: \(error)")
            throw error
        }
    }
    
    /// Rolls back a transaction
    func rollbackTransaction() async throws {
        guard isConnected else {
            throw NSError(domain: "MySQLConnection", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected to database"])
        }
        
        print("[MySQLConnection] Rolling back transaction")
        
        do {
            let query = "ROLLBACK"
            _ = try await execute(query: query)
        } catch {
            print("[MySQLConnection] Failed to rollback transaction: \(error)")
            throw error
        }
    }
    
    func execute(query: String) async throws -> [[String: Any]] {
        return try await execute(query: query, parameters: [])
    }
    
    func close() {
        print("[MySQLConnection] Closing connection...")
        do {
            try connection?.close().wait()
            try eventLoopGroup.syncShutdownGracefully()
        } catch {
            print("[MySQLConnection] Error closing connection: \(error)")
        }
        isConnected = false
        print("[MySQLConnection] Connection closed")
    }
    
    /// Gets the underlying MySQLKit connection for direct access
    func getConnection() -> MySQLKit.MySQLConnection? {
        return connection
    }
}

class DatabaseConnectivityPool {
    // MARK: - Singleton
    static let shared = DatabaseConnectivityPool()
    private init() {
        initializePool()
    }
    
    // MARK: - Database Configuration
    private let config = DatabaseConfig.shared
    
    // MARK: - Properties
    private let minConnections: Int = 2
    private let maxConnections: Int = 10
    private var connections: [DatabaseConnection] = []
    private var availableConnections: [DatabaseConnection] = []
    private let queue = DispatchQueue(label: "com.penai.database.pool", attributes: .concurrent)
    private var _isReady: Bool = false
    
    // MARK: - Public Properties
    var poolSize: Int {
        return queue.sync { _isReady ? connections.count : 0 }
    }
    
    var isReady: Bool {
        return queue.sync { _isReady }
    }
    
    // MARK: - Public Methods
    
    /// Gets a database connection from the pool
    func getConnection() -> DatabaseConnection? {
        return queue.sync(flags: .barrier) { () -> DatabaseConnection? in
            guard _isReady else {
                logError("Pool is not ready")
                return nil
            }
            
            // Try to get an available connection
            if !availableConnections.isEmpty {
                return availableConnections.removeLast()
            }
            
            // Create a new connection if under max limit
            if connections.count < maxConnections {
                let connection = createConnection()
                connections.append(connection)
                return connection
            }
            
            // Wait for a connection to become available (simplified)
            // In a real implementation, this would use semaphores or async waiting
            logError("No available connections in pool")
            return nil
        }
    }
    
    /// Returns a database connection to the pool
    func returnConnection(_ connection: DatabaseConnection) {
        queue.sync(flags: .barrier) { 
            if connection.isConnected {
                availableConnections.append(connection)
            } else {
                // Remove disconnected connection
                connections.removeAll { $0.id == connection.id }
                // Create a new connection to replace it
                if connections.count < minConnections {
                    let newConnection = createConnection()
                    connections.append(newConnection)
                    availableConnections.append(newConnection)
                }
            }
        }
    }
    
    /// Reports a connection error
    func reportConnectionError(_ connection: DatabaseConnection) {
        queue.sync(flags: .barrier) { 
            // Remove the failed connection
            connections.removeAll { $0.id == connection.id }
            availableConnections.removeAll { $0.id == connection.id }
            
            // Create a new connection to replace it
            let newConnection = createConnection()
            connections.append(newConnection)
            availableConnections.append(newConnection)
            
            logError("Connection error reported, replaced with new connection")
        }
    }
    
    /// Shuts down the pool and closes all connections
    func shutdown() {
        queue.sync(flags: .barrier) { 
            guard _isReady else {
                return
            }
            
            // Close all connections
            for connection in connections {
                connection.close()
            }
            
            // Clear pools
            connections.removeAll()
            availableConnections.removeAll()
            
            _isReady = false
            logInfo("Database connection pool shut down")
        }
    }
    
    /// Tests database connectivity asynchronously
    func testConnectivity() async -> Bool {
        logInfo("Testing database connectivity...")
        
        // Check if pool is ready
        if !isReady {
            logError("Database connection pool is not ready")
            return false
        }
        
        // Get a connection from the pool
        guard let connection = getConnection() else {
            logError("Failed to get database connection")
            return false
        }
        
        defer {
            returnConnection(connection)
        }
        
        // Test the connection with a simple query
        do {
            // Execute a simple query to test the connection
            let query = "SELECT 1 as test"
            let results = try await connection.execute(query: query)
            
            if !results.isEmpty {
                logInfo("Database connectivity test passed")
                return true
            } else {
                logError("Database connectivity test failed: No results returned")
                return false
            }
        } catch {
            logError("Database connectivity test failed: \(error)")
            return false
        }
    }
    
    /// Tests database connectivity synchronously (blocking)
    func testConnectivitySync() -> Bool {
        logInfo("Testing database connectivity (sync)...")
        
        // Check if pool is ready
        if !isReady {
            logError("Database connection pool is not ready")
            return false
        }
        
        // Get a connection from the pool
        guard let connection = getConnection() else {
            logError("Failed to get database connection")
            return false
        }
        
        defer {
            returnConnection(connection)
        }
        
        // Return pool readiness as a simple check
        // For a more comprehensive test, use the async version
        logInfo("Database connectivity test (sync) passed")
        return isReady
    }
    
    // MARK: - Private Methods
    
    /// Initializes the connection pool
    private func initializePool() {
        queue.sync(flags: .barrier) { 
            // Create minimum number of connections
            for _ in 0..<minConnections {
                let connection = createConnection()
                connections.append(connection)
                availableConnections.append(connection)
            }
            
            // Wait a bit for connections to establish
            Thread.sleep(forTimeInterval: 1.0)
            
            // Check if all connections are connected
            let allConnected = connections.allSatisfy { $0.isConnected }
            _isReady = allConnected
            
            if allConnected {
                logInfo("Database connection pool initialized with \(minConnections) connections")
            } else {
                logError("Failed to initialize database connection pool - some connections failed")
            }
        }
    }
    
    /// Creates a new database connection
    private func createConnection() -> DatabaseConnection {
        // Create a new MySQL connection
        return MySQLConnection()
    }
    
    /// Logs information messages
    private func logInfo(_ message: String) {
        print("[DatabaseConnectivityPool] Info: \(message)")
    }
    
    /// Logs error messages
    private func logError(_ message: String) {
        print("[DatabaseConnectivityPool] Error: \(message)")
    }
}
