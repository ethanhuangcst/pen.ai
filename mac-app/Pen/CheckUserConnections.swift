import Foundation

// Import the Pen module to access the database pool
import Pen

print("Checking AI connections for user me@ethanhuang.com...")

// Get the database pool
let databasePool = DatabaseConnectivityPool.shared

// Wait for the pool to be ready
print("Waiting for database pool to be ready...")
while !databasePool.isReady {
    Thread.sleep(forTimeInterval: 0.5)
}

print("Database pool is ready")

// Get a connection from the pool
guard let connection = databasePool.getConnection() else {
    print("Error: Failed to get database connection")
    databasePool.shutdown()
    exit(1)
}

defer {
    // Return the connection to the pool
    databasePool.returnConnection(connection)
    // Shutdown the pool
    databasePool.shutdown()
}

// Query to find user by email
let userQuery = "SELECT id, email, name FROM users WHERE email = 'me@ethanhuang.com'"
print("Executing user query: \(userQuery)")

do {
    let userResults = try connection.execute(query: userQuery)
    print("Found \(userResults.count) users")
    
    for user in userResults {
        print("User: \(user)")
        
        if let userId = user["id"] as? Int {
            print("User ID: \(userId)")
            
            // Query to find AI connections for this user
            let connectionsQuery = "SELECT * FROM ai_connections WHERE user_id = \(userId)"
            print("Executing connections query: \(connectionsQuery)")
            
            let connectionsResults = try connection.execute(query: connectionsQuery)
            print("Found \(connectionsResults.count) AI connections for user \(userId)")
            
            for connection in connectionsResults {
                print("Connection: \(connection)")
            }
        }
    }
    
    // Also check all AI connections
    let allConnectionsQuery = "SELECT * FROM ai_connections"
    print("\nExecuting all connections query: \(allConnectionsQuery)")
    
    let allConnectionsResults = try connection.execute(query: allConnectionsQuery)
    print("Found \(allConnectionsResults.count) total AI connections")
    
    for connection in allConnectionsResults {
        print("Connection: \(connection)")
    }
    
} catch {
    print("Error executing query: \(error)")
}

print("Done")
