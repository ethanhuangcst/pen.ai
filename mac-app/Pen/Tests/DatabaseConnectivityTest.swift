import Foundation

// Test script to verify database connectivity
print("Testing database connectivity...")

// Get the shared database connectivity pool
let pool = DatabaseConnectivityPool.shared

// Wait for the pool to be ready
print("Waiting for database pool to be ready...")
for _ in 0..<10 {
    if pool.isReady {
        print("Database pool is ready!")
        break
    }
    sleep(1)
}

if !pool.isReady {
    print("ERROR: Database pool failed to initialize")
    exit(1)
}

print("Pool size: \(pool.poolSize)")

// Get a connection from the pool
guard let connection = pool.getConnection() else {
    print("ERROR: Failed to get database connection")
    exit(1)
}

print("Got database connection: \(connection.id)")

// Perform the query
Task {
    do {
        let query = "SELECT name FROM users WHERE id = 4"
        let parameters: [String] = []
        
        print("Executing query: \(query)")
        let results = try await connection.execute(query: query, parameters: parameters)
        
        if !results.isEmpty {
            if let name = results[0]["name"] as? String {
                print("SUCCESS: Found user with id 4: \(name)")
            } else {
                print("SUCCESS: Found user with id 4, but name field is missing")
            }
        } else {
            print("INFO: No user found with id 4")
        }
    } catch {
        print("ERROR: Query failed: \(error)")
    } finally {
        // Return the connection to the pool
        pool.returnConnection(connection)
        print("Connection returned to pool")
        
        // Shutdown the pool
        pool.shutdown()
        print("Database pool shutdown")
        
        // Exit the program
        exit(0)
    }
}

// Keep the program running until the async task completes
RunLoop.main.run()