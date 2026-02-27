import Foundation

// Direct test to retrieve base_urls column

print("Testing direct base_urls retrieval...")

// Create database pool
let databasePool = DatabaseConnectivityPool.shared

// Wait for pool to initialize
print("Waiting for database pool to initialize...")
Thread.sleep(forTimeInterval: 2.0)

if !databasePool.isReady {
    print("Error: Database pool is not ready")
    exit(1)
}

print("Database pool ready. Getting connection...")

// Get a connection from the pool
guard let connection = databasePool.getConnection() else {
    print("Failed to get database connection")
    exit(1)
}

defer {
    // Return the connection to the pool
    databasePool.returnConnection(connection)
    // Shutdown the pool
    databasePool.shutdown()
}

// Run the async task
Task {
    do {
        // Direct query to get base_urls for gpt-4o-mini
        print("\n=== Testing direct base_urls query ====")
        let query = "SELECT base_urls FROM ai_providers WHERE name = 'gpt-4o-mini'"
        print("Executing query: \(query)")
        
        let results = try await connection.execute(query: query)
        
        print("Found \(results.count) rows")
        for (index, row) in results.enumerated() {
            print("\nRow \(index + 1):")
            for (key, value) in row {
                print("  \(key): \(value)")
                print("  Type: \(type(of: value))")
            }
        }
        
        // Also try a different approach - let's use MySQLKit directly
        print("\n=== Testing MySQLKit direct access ====")
        
        // Get the underlying MySQLConnection
        if let mysqlConnection = connection as? MySQLConnection {
            // Access the internal connection
            if let internalConnection = mysqlConnection.getConnection() {
                // Execute a query directly
                let directQuery = "SELECT base_urls FROM ai_providers WHERE name = 'gpt-4o-mini'"
                let directRows = try await internalConnection.query(directQuery).get()
                
                print("Direct query found \(directRows.count) rows")
                for row in directRows {
                    // Try to access the column directly
                    if let baseURLs = row.base_urls {
                        print("Direct access base_urls: \(baseURLs)")
                    } else {
                        print("Direct access base_urls: nil")
                    }
                }
            }
        }
        
        print("\n=== Test completed ====")
        exit(0)
        
    } catch {
        print("Error: \(error)")
        exit(1)
    }
}

// Keep the program running until the task completes
RunLoop.main.run()
