import Foundation

class LocalizationService {
    static let shared = LocalizationService()
    private var strings: [String: String] = [:]
    
    private init() {
        loadStrings()
    }
    
    private func loadStrings() {
        // Get the user's preferred language
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageCode = preferredLanguage.split(separator: "-").first ?? "en"
        
        // Try to find the Localizable.strings file for the preferred language
        let possiblePaths = [
            // Development path with preferred language
            "\(FileManager.default.currentDirectoryPath)/Resources/\(languageCode)-Hans.lproj/Localizable.strings",
            "\(FileManager.default.currentDirectoryPath)/Resources/\(languageCode).lproj/Localizable.strings",
            // Build path with preferred language
            Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: "\(languageCode)-Hans.lproj"),
            Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: "\(languageCode).lproj"),
            // Fallback to English development path
            "\(FileManager.default.currentDirectoryPath)/Resources/en.lproj/Localizable.strings",
            // Fallback to English build path
            Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: "en.lproj"),
            // Alternative build path
            Bundle.main.path(forResource: "Localizable", ofType: "strings")
        ]
        
        for path in possiblePaths {
            if let path = path, FileManager.default.fileExists(atPath: path) {
                print("LocalizationService: Loading strings from \(path)")
                if let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
                    strings = dict
                    print("LocalizationService: Loaded \(strings.count) strings")
                    return
                }
            }
        }
        
        print("LocalizationService: Failed to load Localizable.strings")
    }
    
    func localizedString(for key: String, comment: String = "") -> String {
        return strings[key] ?? key
    }
    
    func localizedString(for key: String, withFormat arguments: CVarArg..., comment: String = "") -> String {
        let format = localizedString(for: key, comment: comment)
        return String(format: format, arguments: arguments)
    }
    
    // Method to reload strings (useful when language changes)
    func reloadStrings() {
        strings.removeAll()
        loadStrings()
    }
}