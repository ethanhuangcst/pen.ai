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
            let query = "SELECT id, name, email, password, profileImage, createdAt, system_flag, pen_content_history FROM users WHERE email = ?"
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

    func authenticate(email: String, password: String) async -> User? {
        print("[AuthenticationService] Authenticating user: \(email)")

        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            print("[AuthenticationService] Failed to get database connection")
            return nil
        }

        defer {
            DatabaseConnectivityPool.shared.returnConnection(connection)
        }

        do {
            let query = "SELECT id, name, email, password, profileImage, createdAt, system_flag, pen_content_history FROM users WHERE email = ?"
            let parameters: [MySQLData] = [MySQLData(string: email)]
            let results = try await connection.execute(query: query, parameters: parameters)

            guard let firstRow = results.first else {
                print("[AuthenticationService] User not found: \(email)")
                return nil
            }

            guard let passwordHash = firstRow["password"] as? String else {
                print("[AuthenticationService] No password found for user")
                return nil
            }

            let isValid = verifyPassword(password, against: passwordHash)
            print("[AuthenticationService] Authentication result: \(isValid)")
            guard isValid else {
                return nil
            }

            return User.fromDatabaseRow(firstRow)
        } catch {
            print("[AuthenticationService] Authentication query failed: \(error)")
            return nil
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
        print("[AuthenticationService] verifyPassword called")
        print("[AuthenticationService] storedPassword length: \(storedPassword.count)")
        
        let isValid = BCrypt.verify(password, matchesHash: storedPassword)
        print("[AuthenticationService] Bcrypt verification result: \(isValid)")
        return isValid
    }
    
    /// Updates user information in the database
    func updateUser(id: Int, name: String, email: String, password: String? = nil, profileImage: String? = nil, penContentHistory: Int? = nil) async -> Bool {
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
            
            if let penContentHistory = penContentHistory {
                query += ", pen_content_history = ?"
                parameters.append(MySQLData(int: penContentHistory))
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
    
    /// Registers a new user
    func registerUser(name: String, email: String, password: String, profileImage: String? = nil) async -> Bool {
        print("[AuthenticationService] Registering new user: \(email)")
        
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
            // Check if user already exists
            if let _ = await getUserByEmail(email: email) {
                print("[AuthenticationService] User already exists: \(email)")
                return false
            }
            
            // Insert new user
            let query = "INSERT INTO users (name, email, password, profileImage, pen_content_history, createdAt) VALUES (?, ?, ?, ?, ?, NOW())"
            let parameters: [MySQLData] = [
                MySQLData(string: name),
                MySQLData(string: email),
                MySQLData(string: hashPassword(password)),
                MySQLData(string: profileImage ?? ""),
                MySQLData(int: 40) // Default content history limit
            ]
            
            print("[AuthenticationService] Executing insert query: \(query)")
            let results = try await connection.execute(query: query, parameters: parameters)
            
            // Get the last inserted user ID
            let lastInsertIdQuery = "SELECT LAST_INSERT_ID() as id"
            let lastInsertIdResults = try await connection.execute(query: lastInsertIdQuery, parameters: [])
            
            if let lastInsertRow = lastInsertIdResults.first, let userId = lastInsertRow["id"] as? Int {
                print("[AuthenticationService] New user ID: \(userId)")
                
                // Create default prompt for the new user
                do {
                    let promptsService = PromptsService()
                    _ = try await promptsService.createDefaultPrompt(userId: userId)
                    print("[AuthenticationService] Default prompt created for user \(userId)")
                } catch {
                    print("[AuthenticationService] Failed to create default prompt: \(error)")
                    // Continue with registration even if prompt creation fails
                }
            }
            
            print("[AuthenticationService] User registered successfully")
            return true
        } catch {
            print("[AuthenticationService] Database insertion failed: \(error)")
            return false
        }
    }
    
    /// Sends a password reset email
    func sendPasswordResetEmail(email: String) async -> (Bool, String?) {
        print("[AuthenticationService] Sending password reset email to: \(email)")
        
        // Check if user exists
        guard let user = await getUserByEmail(email: email) else {
            print("[AuthenticationService] User not found: \(email)")
            return (false, "user_not_found")
        }
        
        // Generate temporary 8-digit password
        let temporaryPassword = generateTemporaryPassword()
        
        // Update user's password in database
        if await updateUser(id: user.id, name: user.name, email: user.email, password: temporaryPassword) {
            print("[AuthenticationService] Updated user password with temporary password")
        } else {
            print("[AuthenticationService] Failed to update user password")
            return (false, "password_update_failed")
        }
        
        // Send email using EmailService
        let emailService = EmailService.shared
        if await emailService.sendPasswordResetEmail(to: email, temporaryPassword: temporaryPassword) {
            return (true, nil)
        } else {
            return (false, "email_send_failed")
        }
    }
    
    /// Generates a temporary 8-digit password
    private func generateTemporaryPassword() -> String {
        let digits = "0123456789"
        var password = ""
        for _ in 0..<8 {
            password.append(digits.randomElement()!)
        }
        return password
    }
    
    /// Generates a random reset token
    private func generateResetToken() -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var token = ""
        for _ in 0..<32 {
            token.append(chars.randomElement()!)
        }
        return token
    }
}
