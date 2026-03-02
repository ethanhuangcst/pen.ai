import Foundation

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
                let data = try Data(contentsOf