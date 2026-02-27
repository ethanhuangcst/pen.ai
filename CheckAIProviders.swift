import Foundation

// Direct database query to check ai_providers table structure and data

print("Checking ai_providers table structure and data...")

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
        // Query table structure
        print("\n=== Table structure for ai_providers ====")
        let describeQuery = "DESCRIBE ai_providers"
        let describeRows = try await connection.execute(query: describeQuery)
        
        for row in describeRows {
            print(row)
        }
        
        // Query all data
        print("\n=== All data from ai_providers ====")
        let selectQuery = "SELECT * FROM ai_providers"
        let selectRows = try await connection.execute(query: selectQuery)
        
        print("Found \(selectRows.count) rows:")
        for (index, row) in selectRows.enumerated() {
            print("\nRow \(index + 1):")
            for (key, value) in row {
                print("  \(key): \(value)")
            }
        }
        
        // Check if base_urls column exists
        print("\n=== Checking base_urls column ====")
        let checkColumnQuery = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'wingman_db' AND TABLE_NAME = 'ai_providers' AND COLUMN_NAME LIKE '%base%url%'"
        let columnRows = try await connection.execute(query: checkColumnQuery)
        
        print("Found columns:")
        for row in columnRows {
            print(row)
        }
        
        print("\n=== Check completed ====")
        exit(0)
        
    } catch {
        print("Error: \(error)")
        exit(1)
    }
}

// Keep the program running until the task completes
RunLoop.main.run()
