import Foundation
import CryptoKit

class BCrypt {
    /// Verifies a password against a bcrypt hash
    static func verify(_ password: String, matchesHash hash: String) -> Bool {
        print("[BCrypt] Verifying password")
        print("[BCrypt] Stored hash length: \(hash.count)")
        
        if hash.hasPrefix("$2a$") || hash.hasPrefix("$2b$") || hash.hasPrefix("$2y$") {
            let isValid = verifyBcrypt(password, matchesHash: hash)
            print("[BCrypt] Bcrypt verification result: \(isValid)")
            return isValid
        }
        
        // Check if it's a SHA256 hash (64 characters)
        if hash.count == 64 {
            let hashedPassword = hashPassword(password)
            let isValid = hashedPassword == hash
            print("[BCrypt] SHA256 verification result: \(isValid)")
            return isValid
        }
        
        // For existing users with plain text passwords
        if password == hash {
            print("[BCrypt] Direct comparison verification result: true")
            return true
        }
        
        print("[BCrypt] Verification result: false")
        return false
    }
    
    /// Hashes a password using SHA256 (temporary solution)
    static func hash(_ password: String, cost: Int = 12) -> String? {
        if let bcryptHash = createBcryptHash(password) {
            return bcryptHash
        }
        return hashPassword(password)
    }
    
    /// Helper method to hash password using SHA256
    private static func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private static func createBcryptHash(_ password: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/htpasswd")
        process.arguments = ["-nbB", "u", password]
        
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                return nil
            }
            let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: outputData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  let separatorIndex = output.firstIndex(of: ":") else {
                return nil
            }
            let hash = String(output[output.index(after: separatorIndex)...])
            return normalizeBcryptPrefixForStorage(hash)
        } catch {
            return nil
        }
    }
    
    private static func verifyBcrypt(_ password: String, matchesHash hash: String) -> Bool {
        let candidateHashes = bcryptCandidatesForVerification(hash)
        
        for candidateHash in candidateHashes {
            if verifyBcryptWithHtpasswd(password, matchesHash: candidateHash) {
                return true
            }
        }
        
        return false
    }
    
    private static func verifyBcryptWithHtpasswd(_ password: String, matchesHash hash: String) -> Bool {
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("pen-bcrypt-\(UUID().uuidString)")
        
        do {
            try "u:\(hash)\n".write(to: tempFileURL, atomically: true, encoding: .utf8)
            defer {
                try? FileManager.default.removeItem(at: tempFileURL)
            }
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/htpasswd")
            process.arguments = ["-vb", tempFileURL.path, "u", password]
            process.standardOutput = Pipe()
            process.standardError = Pipe()
            
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            try? FileManager.default.removeItem(at: tempFileURL)
            return false
        }
    }
    
    private static func bcryptCandidatesForVerification(_ hash: String) -> [String] {
        if hash.hasPrefix("$2y$") {
            return [hash]
        }
        
        if hash.hasPrefix("$2b$") {
            return [hash.replacingOccurrences(of: "$2b$", with: "$2y$")]
        }
        
        if hash.hasPrefix("$2a$") {
            return [hash.replacingOccurrences(of: "$2a$", with: "$2y$")]
        }
        
        return [hash]
    }
    
    private static func normalizeBcryptPrefixForStorage(_ hash: String) -> String {
        if hash.hasPrefix("$2y$") {
            return hash.replacingOccurrences(of: "$2y$", with: "$2b$")
        }
        return hash
    }
}
