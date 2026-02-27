import Cocoa

/// Custom button that accepts first responder to be included in tab order
class FocusableButton: NSButton {
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override var canBecomeKeyView: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        // Make the button visually indicate it's focused
        if let cell = self.cell as? NSButtonCell {
            cell.highlightsBy = .contentsCellMask
        }
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        // Remove focus indication
        if let cell = self.cell as? NSButtonCell {
            cell.highlightsBy = []
        }
        return true
    }
    

}
