import Foundation
import MySQLKit

func checkUsers() {
    print("Checking users in the database...")
    
    // Get the database pool
    let pool = DatabaseConnectivityPool.shared
    
    // Wait for pool to be ready
    print("Waiting for database pool to be ready...")
    Thread.sleep(forTimeInterval: 2.0)
    
    if !pool.isReady {
        print("Error: Database pool is not ready")
        return
    }
    
    // Get a connection from the pool
    guard let connection = pool.getConnection() else {
        print("Failed to get database connection")
        return
    }
    
    defer {
        pool.returnConnection(connection)
    }
    
    Task {
        do {
            // Query the users table
            let query = "SELECT id, name, email FROM wingman_db.users"
            print("Executing query: \(query)")
            
            let results = try await connection.execute(query: query)
            
            print("\nFound \(results.count) users:")
            print("ID\tName\tEmail")
            print("-\t-\t-")
            
            for row in results {
                if let id = row["id"] as? Int,
                   let name = row["name"] as? String,
                   let email = row["email"] as? String {
                    print("\(id)\t\(name)\t\(email)")
                } else {
                    print("Error: Failed to parse user row")
                }
            }
            
        } catch {
            print("Error querying users: \(error)")
        }
    }
    
    // Run the task
    RunLoop.main.run()
}

checkUsers()
