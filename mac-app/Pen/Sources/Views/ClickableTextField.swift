import Cocoa

class ClickableTextField: NSTextField {
    var clickAction: (() -> Void)?
    
    override func mouseDown(with event: NSEvent) {
        // Trigger the closure if set
        clickAction?()
        
        // Trigger the target-action if set
        if let target = target, let action = action {
            NSApp.sendAction(action, to: target, from: self)
        }
        
        super.mouseDown(with: event)
    }
    
    override var acceptsFirstResponder: Bool {
        // Always allow becoming first responder to receive mouse events
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        // Always allow becoming first responder to receive mouse events
        return true
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSCursor.arrow.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSCursor.arrow.set()
    }
    
    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: NSCursor.arrow)
    }
}