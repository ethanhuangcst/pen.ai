import Foundation

class DatabaseConfig {
    // MARK: - Singleton
    static let shared = DatabaseConfig()
    
    // MARK: - Database Configuration
    let host: String
    let port: Int
    let username: String
    let password: String
    let databaseName: String
    
    // MARK: - Initialization
    private init() {
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        let configPath = "\(currentDirectory)/Resources/config/database.json"
        
        print("[DatabaseConfig] Loading configuration from: \(configPath)")
        
        guard fileManager.fileExists(atPath: configPath) else {
            fatalError("[DatabaseConfig] Configuration file not found at: \(configPath)")
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            guard let json = json else {
                fatalError("[DatabaseConfig] Failed to parse configuration file")
            }
            
            guard let host = json["host"] as? String,
                  let port = json["port"] as? Int,
                  let username = json["username"] as? String,
                  let password = json["password"] as? String,
                  let databaseName = json["databaseName"] as? String else {
                fatalError("[DatabaseConfig] Invalid configuration file format")
            }
            
            self.host = host
            self.port = port
            self.username = username
            self.password = password
            self.databaseName = databaseName
            
            print("[DatabaseConfig] Configuration loaded from JSON file")
            print("[DatabaseConfig] Host: \(host)")
            print("[DatabaseConfig] Port: \(port)")
            print("[DatabaseConfig] Username: \(username)")
            print("[DatabaseConfig] Database: \(databaseName)")
        } catch {
            fatalError("[DatabaseConfig] Error loading configuration: \(error.localizedDescription)")
        }
    }
}
