import Cocoa

class ClickableTextField: NSTextField {
    var clickAction: (() -> Void)?
    
    override func mouseDown(with event: NSEvent) {
        clickAction?()
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
}