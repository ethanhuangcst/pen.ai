import Foundation
import MySQLKit
import AppKit

class SystemConfigService {
    static let shared = SystemConfigService()
    
    // Content history count constants
    var CONTENT_HISTORY_LOW = 10
    var CONTENT_HISTORY_MEDIUM = 20
    var CONTENT_HISTORY_HIGH = 40
    
    // Default prompt settings
    var DEFAULT_PROMPT_NAME: String? = nil
    var DEFAULT_PROMPT_TEXT: String? = nil
    
    // Default prompt constant
    static let DEFAULT_PROMPT_FLAG = 1 // Value for is_default column
    
    // Appearance preferences
    private let autoSwitchAppearanceKey = "autoSwitchAppearance"
    private let manualAppearanceKey = "manualAppearance"
    
    var autoSwitchAppearance: Bool {
        get {
            return UserDefaults.standard.bool(forKey: autoSwitchAppearanceKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: autoSwitchAppearanceKey)
        }
    }
    
    var manualAppearance: NSAppearance.Name? {
        get {
            let rawValue = UserDefaults.standard.string(forKey: manualAppearanceKey)
            switch rawValue {
            case "dark":
                return .darkAqua
            case "light":
                return .aqua
            default:
                return nil
            }
        }
        set {
            let rawValue: String?
            switch newValue {
            case .darkAqua:
                rawValue = "dark"
            case .aqua:
                rawValue = "light"
            default:
                rawValue = nil
            }
            UserDefaults.standard.set(rawValue, forKey: manualAppearanceKey)
        }
    }
    
    // Configuration loading state
    private var isConfigLoaded = false
    private let configLoadedSemaphore = DispatchSemaphore(value: 0)
    
    private init() {
        loadConfig()
    }
    
    /// Loads the system configuration from the database
    func loadConfig() {
        Task {
            // Use DatabaseConnectivityPool to get a connection
            guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
                print("SystemConfigService: Failed to get database connection")
                useDefaultValues()
                return
            }
            
            defer {
                DatabaseConnectivityPool.shared.returnConnection(connection)
            }
            
            do {
                // Query the system_config table
                let query = "SELECT default_prompt_name, default_prompt_text, content_history_count_low, content_history_count_medium, content_history_count_high FROM system_config LIMIT 1"
                let results = try await connection.execute(query: query)
                
                if !results.isEmpty {
                    let row = results[0]
                    // Load values from database
                    DEFAULT_PROMPT_NAME = row["default_prompt_name"] as? String
                    DEFAULT_PROMPT_TEXT = row["default_prompt_text"] as? String
                    CONTENT_HISTORY_LOW = (row["content_history_count_low"] as? Int) ?? 10
                    CONTENT_HISTORY_MEDIUM = (row["content_history_count_medium"] as? Int) ?? 20
                    CONTENT_HISTORY_HIGH = (row["content_history_count_high"] as? Int) ?? 40
                    
                    // Print terminal message
                    print(" ********************************** Load Content History Count: LOW=\(CONTENT_HISTORY_LOW), MEDIUM=\(CONTENT_HISTORY_MEDIUM), HIGH=\(CONTENT_HISTORY_HIGH) **********************************")
                    print("SystemConfigService: Loaded default prompt from database: \(DEFAULT_PROMPT_NAME ?? "Unknown")")
                } else {
                    // No record found, use defaults and create database record
                    print("SystemConfigService: No system_config record found, using defaults and creating database record")
                    useDefaultValues()
                    // Create database record with default values
                    Task {
                        await updateConfig()
                    }
                }
                
                // Mark config as loaded and signal
                isConfigLoaded = true
                configLoadedSemaphore.signal()
            } catch {
                print("SystemConfigService: Failed to load config: \(error)")
                useDefaultValues()
                // Mark config as loaded and signal even on error
                isConfigLoaded = true
                configLoadedSemaphore.signal()
            }
        }
    }
    
    /// Uses default values when database connection fails
    private func useDefaultValues() {
        // Set default values
        CONTENT_HISTORY_LOW = 10
        CONTENT_HISTORY_MEDIUM = 20
        CONTENT_HISTORY_HIGH = 40
        
        // Load default prompt from file if available
        if let prompt = loadDefaultPromptFromFile() {
            DEFAULT_PROMPT_NAME = prompt.name
            DEFAULT_PROMPT_TEXT = prompt.text
        } else {
            // Use hardcoded fallback values
            DEFAULT_PROMPT_NAME = "Enhance English"
            DEFAULT_PROMPT_TEXT = "Enhance English for the following text: "
        }
        
        // Print terminal message
        print(" ********************************** Load Default Content History Count: LOW=\(CONTENT_HISTORY_LOW), MEDIUM=\(CONTENT_HISTORY_MEDIUM), HIGH=\(CONTENT_HISTORY_HIGH) **********************************")
    }
    
    /// Updates the system configuration in the database
    func updateConfig() async {
        // Use DatabaseConnectivityPool to get a connection
        guard let connection = DatabaseConnectivityPool.shared.getConnection() else {
            print("SystemConfigService: Failed to get database connection")
            return
        }
        
        defer {
            DatabaseConnectivityPool.shared.returnConnection(connection)
        }
        
        do {
            // Update the system_config table
            let query = """
                INSERT INTO system_config (default_prompt_name, default_prompt_text, content_history_count_low, content_history_count_medium, content_history_count_high)
                VALUES (?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    default_prompt_name = VALUES(default_prompt_name),
                    default_prompt_text = VALUES(default_prompt_text),
                    content_history_count_low = VALUES(content_history_count_low),
                    content_history_count_medium = VALUES(content_history_count_medium),
                    content_history_count_high = VALUES(content_history_count_high)
            """
            
            // Convert values to MySQLData
            let params: [MySQLData] = [
                MySQLData(string: DEFAULT_PROMPT_NAME ?? ""),
                MySQLData(string: DEFAULT_PROMPT_TEXT ?? ""),
                MySQLData(int: CONTENT_HISTORY_LOW),
                MySQLData(int: CONTENT_HISTORY_MEDIUM),
                MySQLData(int: CONTENT_HISTORY_HIGH)
            ]
            
            _ = try await connection.execute(query: query, parameters: params)
            
            print("SystemConfigService: Config updated successfully")
        } catch {
            print("SystemConfigService: Failed to update config: \(error)")
        }
    }
    
    /// Returns the default prompt as a tuple of (name, text)
    func getDefaultPrompt() -> (name: String?, text: String?) {
        // Wait for config to be loaded if not already loaded
        if !isConfigLoaded {
            print("SystemConfigService: Waiting for config to load...")
            // Wait with timeout to avoid infinite blocking
            let timeoutResult = configLoadedSemaphore.wait(timeout: .now() + .seconds(5))
            if timeoutResult == .timedOut {
                print("SystemConfigService: Config load timed out, using current values")
            }
        }
        print("SystemConfigService: Returning default prompt: \(DEFAULT_PROMPT_NAME ?? "Unknown")")
        return (DEFAULT_PROMPT_NAME, DEFAULT_PROMPT_TEXT)
    }
    
    /// Updates the default prompt values
    func setDefaultPrompt(name: String, text: String) async {
        DEFAULT_PROMPT_NAME = name
        DEFAULT_PROMPT_TEXT = text
        await updateConfig()
    }
    
    /// Returns the content history count for a specific level
    func getContentHistoryCount(level: String) -> Int {
        switch level.lowercased() {
        case "low":
            return CONTENT_HISTORY_LOW
        case "medium":
            return CONTENT_HISTORY_MEDIUM
        case "high":
            return CONTENT_HISTORY_HIGH
        default:
            return CONTENT_HISTORY_LOW
        }
    }
    
    /// Updates the content history count for a specific level
    func setContentHistoryCount(level: String, value: Int) async {
        switch level.lowercased() {
        case "low":
            CONTENT_HISTORY_LOW = value
        case "medium":
            CONTENT_HISTORY_MEDIUM = value
        case "high":
            CONTENT_HISTORY_HIGH = value
        default:
            break
        }
        await updateConfig()
    }
    
    /// Loads default prompt from default_prompt.md file
    private func loadDefaultPromptFromFile() -> (name: String, text: String)? {
        let defaultPromptPath = "\(FileManager.default.currentDirectoryPath)/default_prompt.md"
        
        guard FileManager.default.fileExists(atPath: defaultPromptPath) else {
            print("[SystemConfigService] default_prompt.md not found at \(defaultPromptPath)")
            return nil
        }
        
        do {
            let content = try String(contentsOfFile: defaultPromptPath, encoding: .utf8)
            
            // Parse the content to extract prompt name and text
            var promptName = "Enhance English"
            var promptText = content
            
            // Simple parsing: first line is the name (after #), rest is the content
            let lines = content.components(separatedBy: "\n")
            if let firstLine = lines.first, firstLine.hasPrefix("# ") {
                promptName = firstLine.replacingOccurrences(of: "# ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                promptText = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            return (name: promptName, text: promptText)
        } catch {
            print("[SystemConfigService] Failed to load default prompt: \(error)")
            return nil
        }
    }
}