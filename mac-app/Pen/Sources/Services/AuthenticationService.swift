import Foundation
import MySQLKit

class AuthenticationService {
    // MARK: - Singleton
    static let shared = AuthenticationService()
    private init() {}
    
    // MARK: - Public Methods
    
    /// Attempts to automatically login with stored credentials
    func login() async -> (User?, Bool) {
        print("[AuthenticationService] Attempting automatic login...")
        
        // Get stored credentials from Keychain
        guard let credentials = KeychainService.shared.getCredentials() else {
            print("[AuthenticationService] No stored credentials found")
            return (nil, false)
        }
        
        print("[AuthenticationService] Found stored credentials for: \(credentials.email)")
        
        // Get user from database
        if let user = await getUserByEmail(email: credentials.email) {
            print("[AuthenticationService] Login successful")
            return (user, true)
        } else {
            print("[AuthenticationService] Login failed: Invalid credentials")
            // Clear invalid credentials
            KeychainService.shared.deleteCredentials()
            return (nil, false)
        }
    }
    
    /// Gets a user by email from the database
    func getUserByEmail(email: String) async -> User? {
        print("[AuthenticationService] Getting user by email: \(email)")
        
        // Check if we have a database connection
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            print("[AuthenticationService] Failed to get database connection")
            return nil
        }
        
        defer {
            // Return the connection to the pool
            DatabaseConnectivityPool.shared.returnConnection(connection)
        }
        
        do {
            // Query the database for the user
            let query = "SELECT id, name, email, password, profileImage, createdAt, system_flag FROM users WHERE email = ?"
            let parameters: [MySQLData] = [MySQLData(string: email)]
            
            print("[AuthenticationService] Executing query: \(query)")
            let results = try await connection.execute(query: query, parameters: parameters)
            
            // Check if we found a user
            if !results.isEmpty {
                print("[AuthenticationService] User found: \(email)")
                
                // Create user object from database data
                // Note: We're not including password since it's a bcrypt hash
                if let user = User.fromDatabaseRow(results[0]) {
                    return user
                } else {
                    print("[AuthenticationService] Failed to create user from database data")
                    return nil
                }
            } else {
                print("[AuthenticationService] User not found: \(email)")
                return nil
            }
        } catch {
            print("[AuthenticationService] Database query failed: \(error)")
            return nil
        }
    }
    
    /// Stores user credentials securely in Keychain
    func storeCredentials(email: String, password: String) -> Bool {
        print("[AuthenticationService] Storing credentials for: \(email)")
        return KeychainService.shared.storeCredentials(email: email, password: password)
    }
    
    /// Removes stored credentials from Keychain
    func clearCredentials() {
        print("[AuthenticationService] Clearing stored credentials")
        KeychainService.shared.deleteCredentials()
    }
    
    /// Checks if credentials are stored
    func hasStoredCredentials() -> Bool {
        return KeychainService.shared.hasStoredCredentials()
    }
    
    /// Gets stored credentials
    func getStoredCredentials() -> String? {
        if let credentials = KeychainService.shared.getCredentials() {
            return credentials.email
        }
        return nil
    }
    
    /// Validates credentials using local bcrypt verification
    func validateCredentials(email: String, password: String) async -> Bool {
        print("[AuthenticationService] Validating credentials for: \(email)")
        
        // Check if we have a database connection
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            print("[AuthenticationService] Failed to get database connection")
            return false
        }
        
        defer {
            // Return the connection to the pool
            DatabaseConnectivityPool.shared.returnConnection(connection)
        }
        
        do {
            // Query the database for the user with password
            let query = "SELECT id, name, email, password, profileImage, createdAt, system_flag FROM users WHERE email = ?"
            let parameters: [MySQLData] = [MySQLData(string: email)]
            
            print("[AuthenticationService] Executing query: \(query)")
            let results = try await connection.execute(query: query, parameters: parameters)
            
            // Check if we found a user
            if !results.isEmpty {
                print("[AuthenticationService] User found: \(email)")
                
                // Get the stored password hash
                if let passwordHash = results[0]["password"] as? String {
                    print("[AuthenticationService] Found password hash, length: \(passwordHash.count)")
                    
                    // Verify password using bcrypt
                    let isValid = verifyPassword(password, against: passwordHash)
                    print("[AuthenticationService] Password validation result: \(isValid)")
                    return isValid
                } else {
                    print("[AuthenticationService] No password found for user")
                    return false
                }
            } else {
                print("[AuthenticationService] User not found: \(email)")
                return false
            }
        } catch {
            print("[AuthenticationService] Database query failed: \(error)")
            return false
        }
    }
    
    // MARK: - Password Hashing
    
    /// Hashes a password using bcrypt
    private func hashPassword(_ password: String) -> String {
        if let hashed = BCrypt.hash(password, cost: 12) {
            return hashed
        } else {
            print("[AuthenticationService] Error hashing password")
            return password
        }
    }
    
    /// Verifies a password against a stored bcrypt hash
    private func verifyPassword(_ password: String, against storedPassword: String) -> Bool {
        print("[AuthenticationService] verifyPassword called with password: \(password), storedPassword: \(storedPassword)")
        print("[AuthenticationService] storedPassword length: \(storedPassword.count)")
        
        let isValid = BCrypt.verify(password, matchesHash: storedPassword)
        print("[AuthenticationService] Bcrypt verification result: \(isValid)")
        return isValid
    }
    
    /// Updates user information in the database
    func updateUser(id: Int, name: String, email: String, password: String? = nil, profileImage: String? = nil) async -> Bool {
        print("[AuthenticationService] Updating user: \(email)")
        
        // Check if we have a database connection
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            print("[AuthenticationService] Failed to get database connection")
            return false
        }
        
        defer {
            // Return the connection to the pool
            DatabaseConnectivityPool.shared.returnConnection(connection)
        }
        
        do {
            // Build the update query based on provided fields
            var query = "UPDATE users SET name = ?, email = ?"
            var parameters: [MySQLData] = [MySQLData(string: name), MySQLData(string: email)]
            
            if let password = password {
                query += ", password = ?"
                parameters.append(MySQLData(string: hashPassword(password)))
            }
            
            if let profileImage = profileImage {
                query += ", profileImage = ?"
                parameters.append(MySQLData(string: profileImage))
            }
            
            query += " WHERE id = ?"
            parameters.append(MySQLData(string: String(id)))
            
            print("[AuthenticationService] Executing update query: \(query)")
            let results = try await connection.execute(query: query, parameters: parameters)
            
            print("[AuthenticationService] User updated successfully")
            return true
        } catch {
            print("[AuthenticationService] Database update failed: \(error)")
            return false
        }
    }
}
