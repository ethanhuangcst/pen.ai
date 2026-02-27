import Foundation

class LocalizationService {
    static let shared = LocalizationService()
    private var strings: [String: String] = [:]
    
    private init() {
        loadStrings()
    }
    
    private func loadStrings() {
        // Try to find the Localizable.strings file
        let possiblePaths = [
            // Development path
            "\(FileManager.default.currentDirectoryPath)/Resources/en.lproj/Localizable.strings",
            // Build path
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
}