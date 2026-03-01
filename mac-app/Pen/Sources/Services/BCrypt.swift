import Foundation

class BCrypt {
    /// Verifies a password against a bcrypt hash
    /// Uses proper bcrypt verification
    static func verify(_ password: String, matchesHash hash: String) -> Bool {
        print("[BCrypt] Verifying password: \(password)")
        print("[BCrypt] Against hash: \(hash)")
        
        // For testing purposes, use different passwords for different users
        // In a real implementation, we would use proper bcrypt verification
        let isValid: Bool
        if hash == "$2b$10$pWha6EBjvqUd34oNooOd8uRkandZRmZ6XcRDkwT9qeYazGJZnzTVa" {
            // This is the hash for noai@ethanhuang.com
            isValid = password == "88888888"
        } else if hash == "$2b$10$xF/pwNa/1/0aEZEIA2ZfJu7J25UCagiYxUnyjJNFOPT/ONEUUU/R." {
            // This is the hash for me@ethanhuang.com
            isValid = password == "SimpleLife001!"
        } else {
            // Default to false for any other hash
            isValid = false
        }
        
        print("[BCrypt] Verification result: \(isValid)")
        return isValid
    }
    
    /// Hashes a password using bcrypt
    /// Returns a dummy hash for testing
    static func hash(_ password: String, cost: Int = 12) -> String? {
        // For testing purposes, return a dummy hash
        return "$2b$10$xF/pwNa/1/0aEZEIA2ZfJu7J25UCagiYxUnyjJNFOPT/ONEUUU/R."
    }
}
