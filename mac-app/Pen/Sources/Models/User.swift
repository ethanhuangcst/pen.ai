import Foundation

class User {
    // MARK: - Properties
    
    let id: Int
    let name: String
    let email: String
    let password: String?
    let profileImage: String?
    let createdAt: Date
    let systemFlag: String
    let penContentHistory: Int
    
    // MARK: - Constants
    
    // System flag values
    static let SYSTEM_FLAG_WINGMAN = "WINGMAN" // created by Wingman app
    static let SYSTEM_FLAG_PEN = "PEN" // created by PEN app
    
    init(id: Int, name: String, email: String, password: String = "", profileImage: String?, createdAt: Date, systemFlag: String = "PEN", penContentHistory: Int = 40) {
        self.id = id
        self.name = name
        self.email = email
        self.password = password
        self.profileImage = profileImage
        self.createdAt = createdAt
        self.systemFlag = systemFlag
        self.penContentHistory = penContentHistory
    }
    
    // MARK: - Convenience Methods
    
    /// Creates a User instance from database row
    static func fromDatabaseRow(_ row: [String: Any]) -> User? {
        // Print all row data for debugging
        
        // Check each field
        if let name = row["name"] as? String {
            print("[User] name: \(name)")
        } else {
            print("[User] Missing or invalid name: \(row["name"] ?? "nil")")
        }
        
        if let email = row["email"] as? String {
            print("[User] email: \(email)")
        } else {
            print("[User] Missing or invalid email: \(row["email"] ?? "nil")")
        }
        
        if let id = row["id"] as? Int {
            print("[User] id: \(id)")
        } else {
            print("[User] Missing or invalid id: \(row["id"] ?? "nil")")
        }
        
        // Handle id as string or int
        let id: Int
        if let idInt = row["id"] as? Int {
            id = idInt
            print("[User] id: \(id)")
        } else if let idString = row["id"] as? String, let idInt = Int(idString) {
            id = idInt
            print("[User] id (from string): \(id)")
        } else {
            print("[User] Missing or invalid id: \(row["id"] ?? "nil")")
            return nil
        }
        
        guard let name = row["name"] as? String,
              let email = row["email"] as? String else {
            print("[User] Failed to extract required fields")
            return nil
        }
        
        // Parse createdAt string to Date (optional)
        var createdAt = Date()
        if let createdAtStr = row["createdAt"] as? String {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate, .withTime, .withFractionalSeconds]
            if let parsedDate = dateFormatter.date(from: createdAtStr) {
                createdAt = parsedDate
            } else {
                print("[User] Failed to parse createdAt: \(createdAtStr), using current date")
            }
        } else {
            print("[User] createdAt not found, using current date")
        }
        
        let profileImage = row["profileImage"] as? String
        let systemFlag = row["system_flag"] as? String ?? "PEN"
        
        // Get pen_content_history
        let penContentHistory: Int
        if let historyInt = row["pen_content_history"] as? Int {
            penContentHistory = historyInt
            print("[User] pen_content_history: \(penContentHistory)")
        } else if let historyString = row["pen_content_history"] as? String, let historyInt = Int(historyString) {
            penContentHistory = historyInt
            print("[User] pen_content_history (from string): \(penContentHistory)")
        } else {
            penContentHistory = 40 // Default value
            print("[User] pen_content_history not found, using default: \(penContentHistory)")
        }
        
        print("[User] systemFlag: \(systemFlag)")
        
        // Get password if present (optional)
        let password = row["password"] as? String ?? ""
        
        let user = User(id: id, name: name, email: email, password: password, profileImage: profileImage, createdAt: createdAt, systemFlag: systemFlag, penContentHistory: penContentHistory)
        print("[User] Created user: \(user.name) with email \(user.email)")
        return user
    }
    
    /// Creates a new User instance with default PEN system flag
    static func createNewUser(name: String, email: String, password: String, profileImage: String? = nil) -> User {
        return User(
            id: 0, // Will be set by database
            name: name,
            email: email,
            password: password,
            profileImage: profileImage,
            createdAt: Date(),
            systemFlag: "PEN"
        )
    }
}
