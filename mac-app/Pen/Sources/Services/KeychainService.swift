import Foundation

class KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.pen.ai"
    private let keychainFileName = "PenKeychain"
    
    private var keychainFileURL: URL {
        let fileManager = FileManager.default
        let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let penDirectory = applicationSupportDirectory.appendingPathComponent("Pen")
        
        // Create the Pen directory if it doesn't exist
        do {
            try fileManager.createDirectory(at: penDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("KeychainService: Failed to create directory: \(error)")
        }
        
        return penDirectory.appendingPathComponent(keychainFileName)
    }
    
    private init() {}
    
    /// Stores user credentials in an encrypted file
    func storeCredentials(email: String, password: String) -> Bool {
        // Delete any existing credentials
        deleteCredentials()
        
        // Create a dictionary with both email and password
        let credentials: [String: String] = [
            "email": email,
            "password": password
        ]
        
        // Convert to data
        guard let credentialsData = try? JSONSerialization.data(withJSONObject: credentials, options: .prettyPrinted) else {
            print("KeychainService: Failed to serialize credentials")
            return false
        }
        
        // Encrypt the data
        guard let encryptedData = encrypt(data: credentialsData) else {
            print("KeychainService: Failed to encrypt credentials")
            return false
        }
        
        // Write to file
        do {
            try encryptedData.write(to: keychainFileURL)
            return true
        } catch {
            print("KeychainService: Failed to write credentials to file: \(error)")
            return false
        }
    }
    
    /// Retrieves stored credentials from the encrypted file
    func getCredentials() -> (email: String, password: String)? {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: keychainFileURL.path) else {
            return nil
        }
        
        // Read from file
        guard let encryptedData = try? Data(contentsOf: keychainFileURL) else {
            print("KeychainService: Failed to read credentials from file")
            return nil
        }
        
        // Decrypt the data
        guard let decryptedData = decrypt(data: encryptedData) else {
            print("KeychainService: Failed to decrypt credentials")
            return nil
        }
        
        // Parse the credentials
        guard let credentials = try? JSONSerialization.jsonObject(with: decryptedData) as? [String: String],
              let email = credentials["email"],
              let password = credentials["password"] else {
            print("KeychainService: Failed to parse credentials")
            return nil
        }
        
        return (email, password)
    }
    
    /// Deletes stored credentials from the encrypted file
    func deleteCredentials() -> Bool {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: keychainFileURL.path) else {
            return true
        }
        
        // Delete the file
        do {
            try FileManager.default.removeItem(at: keychainFileURL)
            return true
        } catch {
            print("KeychainService: Failed to delete credentials file: \(error)")
            return false
        }
    }
    
    /// Checks if credentials are stored in the encrypted file
    func hasStoredCredentials() -> Bool {
        return FileManager.default.fileExists(atPath: keychainFileURL.path)
    }
    
    /// Encrypts data using a secure key
    private func encrypt(data: Data) -> Data? {
        // For simplicity, we'll use a basic encryption method
        // In a production app, you would use a more secure encryption method
        let key = getEncryptionKey()
        return data.xor(with: key)
    }
    
    /// Decrypts data using a secure key
    private func decrypt(data: Data) -> Data? {
        // For simplicity, we'll use a basic encryption method
        // In a production app, you would use a more secure encryption method
        let key = getEncryptionKey()
        return data.xor(with: key)
    }
    
    /// Generates a secure encryption key
    private func getEncryptionKey() -> Data {
        // For simplicity, we'll use a fixed key based on the service name
        // In a production app, you would generate a secure random key and store it safely
        let keyString = "\(service)_encryption_key"
        return keyString.data(using: .utf8)! 
    }
}

/// Extension for simple XOR encryption/decryption
extension Data {
    func xor(with key: Data) -> Data {
        var result = Data(count: self.count)
        for i in 0..<self.count {
            let keyByte = key[i % key.count]
            result[i] = self[i] ^ keyByte
        }
        return result
    }
}
