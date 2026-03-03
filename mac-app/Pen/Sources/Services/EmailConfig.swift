import Foundation

class EmailConfig {
    // MARK: - Singleton
    static let shared = EmailConfig()
    
    // MARK: - Email Configuration
    let smtpServer: String
    let smtpPort: Int
    let smtpUsername: String
    let smtpPassword: String
    let fromEmail: String
    let fromName: String
    
    // MARK: - Initialization
    private init() {
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        let configPath = "\(currentDirectory)/Resources/config/email.json"
        
        print("[EmailConfig] Loading configuration from: \(configPath)")
        
        guard fileManager.fileExists(atPath: configPath) else {
            fatalError("[EmailConfig] Configuration file not found at: \(configPath)")
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            guard let json = json else {
                fatalError("[EmailConfig] Failed to parse configuration file")
            }
            
            guard let smtpServer = json["smtpServer"] as? String,
                  let smtpPort = json["smtpPort"] as? Int,
                  let smtpUsername = json["smtpUsername"] as? String,
                  let smtpPassword = json["smtpPassword"] as? String,
                  let fromEmail = json["fromEmail"] as? String,
                  let fromName = json["fromName"] as? String else {
                fatalError("[EmailConfig] Invalid configuration file format")
            }
            
            self.smtpServer = smtpServer
            self.smtpPort = smtpPort
            self.smtpUsername = smtpUsername
            self.smtpPassword = smtpPassword
            self.fromEmail = fromEmail
            self.fromName = fromName
            
            print("[EmailConfig] Configuration loaded from JSON file")
            print("[EmailConfig] SMTP Server: \(smtpServer)")
            print("[EmailConfig] SMTP Port: \(smtpPort)")
            print("[EmailConfig] From Email: \(fromEmail)")
            print("[EmailConfig] From Name: \(fromName)")
        } catch {
            fatalError("[EmailConfig] Error loading configuration: \(error.localizedDescription)")
        }
    }
}