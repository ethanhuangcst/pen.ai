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
        
        // Try to find config file in multiple locations
        let configPaths = Self.getConfigPaths()
        
        var configPath: String?
        for path in configPaths {
            print("[DatabaseConfig] Checking: \(path)")
            if fileManager.fileExists(atPath: path) {
                configPath = path
                break
            }
        }
        
        guard let configPath = configPath else {
            // Use environment variables or default values for production
            print("[DatabaseConfig] No config file found, using environment variables or defaults")
            
            self.host = ProcessInfo.processInfo.environment["DB_HOST"] ?? "localhost"
            self.port = Int(ProcessInfo.processInfo.environment["DB_PORT"] ?? "3306") ?? 3306
            self.username = ProcessInfo.processInfo.environment["DB_USERNAME"] ?? "root"
            self.password = ProcessInfo.processInfo.environment["DB_PASSWORD"] ?? ""
            self.databaseName = ProcessInfo.processInfo.environment["DB_NAME"] ?? "pen_ai"
            
            print("[DatabaseConfig] Using defaults - Host: \(host), Port: \(port), Database: \(databaseName)")
            return
        }
        
        print("[DatabaseConfig] Loading configuration from: \(configPath)")
        
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
            
            print("[DatabaseConfig] Configuration loaded successfully")
        } catch {
            fatalError("[DatabaseConfig] Error loading configuration: \(error.localizedDescription)")
        }
    }
    
    private static func getConfigPaths() -> [String] {
        var paths: [String] = []
        
        // 1. App bundle Resources folder (for distributed app)
        if let bundlePath = Bundle.main.resourcePath {
            paths.append("\(bundlePath)/config/database.json")
        }
        
        // 2. Current directory/Resources/config (for development)
        let currentDirectory = FileManager.default.currentDirectoryPath
        paths.append("\(currentDirectory)/Resources/config/database.json")
        
        // 3. Executable directory/../Resources/config (for app bundle)
        if let executablePath = Bundle.main.executablePath {
            let executableDir = URL(fileURLWithPath: executablePath).deletingLastPathComponent().path
            paths.append("\(executableDir)/../Resources/config/database.json")
        }
        
        return paths
    }
}
