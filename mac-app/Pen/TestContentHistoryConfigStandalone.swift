import Foundation

// ContentHistoryConfigService implementation
class ContentHistoryConfigService {
    static let shared = ContentHistoryConfigService()
    
    private let configFileName = "CONTENT_HISTORY_COUNT.json"
    private var configFileURL: URL {
        let fileManager = FileManager.default
        let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let penDirectory = applicationSupportDirectory.appendingPathComponent("Pen")
        
        // Create the Pen directory if it doesn't exist
        do {
            try fileManager.createDirectory(at: penDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("ContentHistoryConfigService: Failed to create directory: \(error)")
        }
        
        return penDirectory.appendingPathComponent(configFileName)
    }
    
    // Default values
    private let defaultLow = 10
    private let defaultMedium = 20
    private let defaultHigh = 40
    
    // Global constants
    var CONTENT_HISTORY_LOW = 10
    var CONTENT_HISTORY_MEDIUM = 20
    var CONTENT_HISTORY_HIGH = 40
    
    private init() {
        loadConfig()
    }
    
    /// Loads the content history count configuration
    func loadConfig() {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: configFileURL.path) {
            // File exists, try to load it
            do {
                let data = try Data(contentsOf: configFileURL)
                if let config = try JSONSerialization.jsonObject(with: data) as? [String: Int] {
                    // Load values or use defaults if not present
                    CONTENT_HISTORY_LOW = config["CONTENT_HISTORY_LOW"] ?? defaultLow
                    CONTENT_HISTORY_MEDIUM = config["CONTENT_HISTORY_MEDIUM"] ?? defaultMedium
                    CONTENT_HISTORY_HIGH = config["CONTENT_HISTORY_HIGH"] ?? defaultHigh
                    
                    // Print terminal message
                    print(" ********************************** Load Content History Count: LOW=\(CONTENT_HISTORY_LOW), MEDIUM=\(CONTENT_HISTORY_MEDIUM), HIGH=\(CONTENT_HISTORY_HIGH) **********************************")
                    return
                }
            } catch {
                print("ContentHistoryConfigService: Failed to load config file: \(error)")
            }
        }
        
        // File doesn't exist or is corrupted, create with default values
        createDefaultConfig()
    }
    
    /// Creates the default configuration file
    private func createDefaultConfig() {
        let defaultConfig: [String: Int] = [
            "CONTENT_HISTORY_LOW": defaultLow,
            "CONTENT_HISTORY_MEDIUM": defaultMedium,
            "CONTENT_HISTORY_HIGH": defaultHigh
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: defaultConfig, options: .prettyPrinted)
            try data.write(to: configFileURL)
            
            // Set global constants to default values
            CONTENT_HISTORY_LOW = defaultLow
            CONTENT_HISTORY_MEDIUM = defaultMedium
            CONTENT_HISTORY_HIGH = defaultHigh
            
            // Print terminal message
            print(" ********************************** Load Default Content History Count: LOW=\(CONTENT_HISTORY_LOW), MEDIUM=\(CONTENT_HISTORY_MEDIUM), HIGH=\(CONTENT_HISTORY_HIGH) **********************************")
        } catch {
            print("ContentHistoryConfigService: Failed to create default config file: \(error)")
        }
    }
}

// Test the service
print("Testing ContentHistoryConfigService...")

// Initialize the service
let configService = ContentHistoryConfigService.shared

print("ContentHistoryConfigService initialized successfully")
print("LOW: \(configService.CONTENT_HISTORY_LOW)")
print("MEDIUM: \(configService.CONTENT_HISTORY_MEDIUM)")
print("HIGH: \(configService.CONTENT_HISTORY_HIGH)")

print("Test completed successfully!")
