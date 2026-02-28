import Cocoa
import Foundation
import MySQLKit

// Main entry point for the application
print("Main: Starting Pen AI application")

// Check for command-line arguments
let arguments = CommandLine.arguments
if arguments.count > 1 {
    let command = arguments[1]
    
    if command == "inspect-table" {
        print("Running database table inspection...")
        
        Task {
            do {
                // Get the database pool
                let pool = DatabaseConnectivityPool.shared
                
                // Wait for pool to be ready
                print("Waiting for database pool to be ready...")
                Thread.sleep(forTimeInterval: 2.0)
                
                // Get a connection from the pool
                guard let connection = pool.getConnection() else {
                    print("Failed to get database connection")
                    exit(1)
                }
                
                defer {
                    pool.returnConnection(connection)
                }
                
                // Query table structure
                print("\n=== Table structure for wingman_db.users ===")
                let describeQuery = "DESCRIBE wingman_db.users"
                let describeRows = try await connection.execute(query: describeQuery)
                
                for row in describeRows {
                    if let field = row["Field"] as? String,
                       let type = row["Type"] as? String,
                       let nullable = row["Null"] as? String,
                       let key = row["Key"] as? String,
                       let extra = row["Extra"] as? String {
                        let defaultVal = row["Default"] as? String ?? "NULL"
                        print("\(field)\t\(type)\t\(nullable)\t\(key)\t\(defaultVal)\t\(extra)")
                    }
                }
                
                // Check sample data
                print("\n=== Sample data from users table ===")
                let sampleQuery = "SELECT id, name, email, system_flag FROM wingman_db.users LIMIT 5"
                let sampleRows = try await connection.execute(query: sampleQuery)
                
                for row in sampleRows {
                    if let id = row["id"] as? Int,
                       let name = row["name"] as? String,
                       let email = row["email"] as? String,
                       let systemFlag = row["system_flag"] as? String {
                        print("\(id)\t\(name)\t\(email)\t\(systemFlag)")
                    }
                }
                
                // Check if password_hash column exists
                print("\n=== Checking for password_hash column ====")
                let checkPasswordHashQuery = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'wingman_db' AND TABLE_NAME = 'users' AND COLUMN_NAME = 'password_hash'"
                let passwordHashRows = try await connection.execute(query: checkPasswordHashQuery)
                
                if passwordHashRows.isEmpty {
                    print("WARNING: 'password_hash' column does not exist in Users table")
                } else {
                    print("SUCCESS: 'password_hash' column exists in Users table")
                }
                
                // Check profileImage for Ethan Huang
                print("\n=== Checking profileImage for Ethan Huang ====")
                let checkProfileImageQuery = "SELECT profileImage FROM users WHERE email = 'me@ethanhuang.com'"
                let profileImageRows = try await connection.execute(query: checkProfileImageQuery)
                
                if !profileImageRows.isEmpty {
                    if let profileImage = profileImageRows[0]["profileImage"] as? String {
                        print("profileImage: [BASE64 ENCODED IMAGE]")
                    } else {
                        print("profileImage is NULL or not a string")
                    }
                } else {
                    print("No user found with email 'me@ethanhuang.com'")
                }
                
                print("\n=== Table inspection completed ====")
                exit(0)
                
            } catch {
                print("Error inspecting database: \(error)")
                exit(1)
            }
        }
        
        // Run the task
        RunLoop.main.run()
    }
    
    if command == "test-ai-providers" {
        print("Testing AIConnectionService.loadAllProviders()...")
        
        Task {
            do {
                // Get the database pool
                let pool = DatabaseConnectivityPool.shared
                
                // Wait for pool to be ready
                print("Waiting for database pool to be ready...")
                Thread.sleep(forTimeInterval: 2.0)
                
                if !pool.isReady {
                    print("Error: Database pool is not ready")
                    exit(1)
                }
                
                // Load providers using AIManager
                let providers = try await AIManager.shared.loadAllProviders()
                
                print("\nSuccessfully loaded \(providers.count) AI providers:")
                print("=====================================")
                
                for (index, provider) in providers.enumerated() {
                    print("\nProvider \(index + 1):")
                    print("ID: \(provider.id)")
                    print("Name: \(provider.name)")
                    print("Default Model: \(provider.defaultModel)")
                    print("Requires Auth: \(provider.requiresAuth)")
                    print("Auth Header: \(provider.authHeader)")
                    print("Base URLs: \(provider.baseURLs)")
                    print("Created At: \(provider.createdAt)")
                    if let updatedAt = provider.updatedAt {
                        print("Updated At: \(updatedAt)")
                    }
                    print("-------------------------------------")
                }
                
                print("\nTest completed successfully!")
                exit(0)
                
            } catch {
                print("Error loading providers: \(error)")
                exit(1)
            }
        }
        
        // Run the task
        RunLoop.main.run()
    } else if command == "inspect-ai-providers" {
        print("Inspecting ai_providers table...")
        
        Task {
            do {
                // Get the database pool
                let pool = DatabaseConnectivityPool.shared
                
                // Wait for pool to be ready
                print("Waiting for database pool to be ready...")
                Thread.sleep(forTimeInterval: 2.0)
                
                // Get a connection from the pool
                guard let connection = pool.getConnection() else {
                    print("Failed to get database connection")
                    exit(1)
                }
                
                defer {
                    pool.returnConnection(connection)
                }
                
                // Query table structure
                print("\n=== Table structure for wingman_db.ai_providers ====")
                let describeQuery = "DESCRIBE wingman_db.ai_providers"
                let describeRows = try await connection.execute(query: describeQuery)
                
                for row in describeRows {
                    if let field = row["Field"] as? String,
                       let type = row["Type"] as? String,
                       let nullable = row["Null"] as? String,
                       let key = row["Key"] as? String,
                       let extra = row["Extra"] as? String {
                        let defaultVal = row["Default"] as? String ?? "NULL"
                        print("\(field)\t\(type)\t\(nullable)\t\(key)\t\(defaultVal)\t\(extra)")
                    }
                }
                
                // Check sample data
                print("\n=== Sample data from ai_providers table ====")
                let sampleQuery = "SELECT * FROM wingman_db.ai_providers"
                let sampleRows = try await connection.execute(query: sampleQuery)
                
                print("Found \(sampleRows.count) AI providers:")
                for row in sampleRows {
                    print("\nProvider:")
                    for (key, value) in row {
                        print("  \(key): \(value)")
                    }
                }
                
                print("\n=== Table inspection completed ====")
                exit(0)
                
            } catch {
                print("Error inspecting database: \(error)")
                exit(1)
            }
        }
        
        // Run the task
        RunLoop.main.run()
    }
}

// Create the application instance
let app = NSApplication.shared

// Create and set the delegate
let delegate = PenDelegate()
app.delegate = delegate

// Test bcrypt verification
func testBCrypt() {
    // Test credentials provided by user
    let email = "me@ethanhuang.com"
    let password = "SimpleLife001!"
    let encryptedPassword = "$2b$10$xF/pwNa/1/0aEZEIA2ZfJu7J25UCagiYxUnyjJNFOPT/ONEUUU/R."
    
    print("\n=== Testing BCrypt Verification ===")
    print("User: \(email)")
    print("Password: \(password)")
    print("Encrypted password: \(encryptedPassword)")
    
    // Test the verification
    let result = BCrypt.verify(password, matchesHash: encryptedPassword)
    
    print("Verification result: \(result)")
    print("=== BCrypt Test Completed ===\n")
}

// Run bcrypt test
testBCrypt()

// Run the application
print("Main: Running Pen AI application")
app.run()
