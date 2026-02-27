import Foundation
import Carbon
import Cocoa

class ShortcutService {
    static let shared = ShortcutService()
    
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyID: EventHotKeyID
    
    private init() {
        // Initialize hotKeyID with proper four-character code
        let signature = OSType(0x50454E00) // "PEN" as four-character code
        hotKeyID = EventHotKeyID(signature: signature, id: UInt32(1))
        
        // Don't setup shortcut listener in init to avoid crash
        // setupShortcutListener()
    }
    
    func setupShortcutListener() {
        // Register the default shortcut: Command+Option+P
        registerShortcut(keyCode: UInt32(kVK_ANSI_P), modifiers: UInt32(cmdKey + optionKey))
    }
    
    func registerShortcut(keyCode: UInt32, modifiers: UInt32) {
        // Unregister any existing shortcut
        unregisterShortcut()
        
        // Create event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        let handler: EventHandlerUPP = { (nextHandler, event, userData) -> OSStatus in
            let selfPtr = Unmanaged<ShortcutService>.fromOpaque(userData!).takeUnretainedValue()
            selfPtr.handleHotKeyEvent()
            return noErr
        }
        
        // Install event handler
        var handlerRef: EventHandlerRef?
        InstallEventHandler(GetEventDispatcherTarget(), handler, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)
        
        // Register hot key
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
        if status != noErr {
            print("Failed to register hot key: \(status)")
        }
    }
    
    func unregisterShortcut() {
        if hotKeyRef != nil {
            UnregisterEventHotKey(hotKeyRef!)
            hotKeyRef = nil
        }
    }
    
    func handleHotKeyEvent() {
        togglePenWindow()
    }
    
    func togglePenWindow() {
        // Get the application delegate
        guard let appDelegate = NSApplication.shared.delegate as? PenAIDelegate else {
            return
        }
        
        // Toggle the main window
        appDelegate.toggleMainWindow()
    }
    
    func checkPermissions() -> Bool {
        // Check if accessibility permissions are granted
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true]
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        return isTrusted
    }
    
    func requestPermissions() -> Bool {
        // This will prompt the user for accessibility permissions
        return checkPermissions()
    }
}
