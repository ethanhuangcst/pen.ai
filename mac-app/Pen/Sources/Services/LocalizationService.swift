import Foundation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case chineseSimplified = "zh-Hans"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chineseSimplified: return "简体中文"
        }
    }
    
    var lprojName: String {
        switch self {
        case .english: return "en.lproj"
        case .chineseSimplified: return "zh-Hans.lproj"
        }
    }
    
    static func fromString(_ string: String) -> AppLanguage {
        if string.hasPrefix("zh") {
            return .chineseSimplified
        }
        return .english
    }
}

class LocalizationService {
    static let shared = LocalizationService()
    static let languageDidChangeNotification = Notification.Name("LanguageDidChangeNotification")
    
    private var strings: [String: String] = [:]
    private var currentLanguage: AppLanguage = .english
    
    private let userLanguageKey = "pen.userLanguage"
    
    var language: AppLanguage {
        return currentLanguage
    }
    
    private init() {
        loadSavedLanguagePreference()
        loadStrings()
    }
    
    private func loadSavedLanguagePreference() {
        if let savedCode = UserDefaults.standard.string(forKey: userLanguageKey),
           let language = AppLanguage(rawValue: savedCode) {
            currentLanguage = language
            print("LocalizationService: Loaded saved language: \(language.displayName)")
        } else {
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            currentLanguage = AppLanguage.fromString(preferredLanguage)
            print("LocalizationService: Using system language: \(currentLanguage.displayName)")
        }
    }
    
    private func loadStrings() {
        let lprojName = currentLanguage.lprojName
        
        let possiblePaths = [
            ResourceService.shared.getResourcePath(relativePath: "\(lprojName)/Localizable.strings"),
            Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: lprojName),
            Bundle.main.path(forResource: "Localizable", ofType: "strings")
        ]
        
        for path in possiblePaths {
            if let path = path, FileManager.default.fileExists(atPath: path) {
                print("LocalizationService: Loading strings from \(path)")
                if let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
                    strings = dict
                    print("LocalizationService: Loaded \(strings.count) strings for \(currentLanguage.displayName)")
                    return
                }
            }
        }
        
        print("LocalizationService: Failed to load Localizable.strings for \(lprojName)")
    }
    
    func localizedString(for key: String, comment: String = "") -> String {
        return strings[key] ?? key
    }
    
    func localizedString(for key: String, withFormat arguments: CVarArg..., comment: String = "") -> String {
        let format = localizedString(for: key, comment: comment)
        return String(format: format, arguments: arguments)
    }
    
    func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else {
            print("LocalizationService: Language unchanged: \(language.displayName)")
            return
        }
        
        currentLanguage = language
        
        UserDefaults.standard.set(language.rawValue, forKey: userLanguageKey)
        print("LocalizationService: Saved language preference: \(language.displayName)")
        
        reloadStrings()
        
        NotificationCenter.default.post(name: Self.languageDidChangeNotification, object: nil)
        print("LocalizationService: Posted language change notification")
    }
    
    func reloadStrings() {
        strings.removeAll()
        loadStrings()
    }
}
