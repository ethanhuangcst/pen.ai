import Cocoa

class ColorService {
    static let shared = ColorService()
    
    private init() {}
    
    var backgroundColor: NSColor {
        return NSColor.windowBackgroundColor
    }
    
    var surfaceColor: NSColor {
        return NSColor.underPageBackgroundColor
    }
    
    var textColor: NSColor {
        return NSColor.labelColor
    }
    
    var secondaryTextColor: NSColor {
        return NSColor.secondaryLabelColor
    }
    
    var borderColor: NSColor {
        return NSColor.separatorColor
    }
    
    var textBackgroundColor: NSColor {
        return NSColor.textBackgroundColor
    }
    
    var shadowColor: NSColor {
        return NSColor.shadowColor
    }
    
    var backgroundColorCGColor: CGColor {
        return NSColor.windowBackgroundColor.cgColor
    }
    
    var textBackgroundColorCGColor: CGColor {
        return NSColor.textBackgroundColor.cgColor
    }
    
    func getLogo() -> NSImage? {
        let isDarkMode = NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let logoName = isDarkMode ? "logo_dark" : "logo"
        
        let logoPath = ResourceService.shared.getResourcePath(relativePath: "Assets/\(logoName).png")
        return NSImage(contentsOfFile: logoPath)
    }
    
    func isDarkMode() -> Bool {
        return NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}
