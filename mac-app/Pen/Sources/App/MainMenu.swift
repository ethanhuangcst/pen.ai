import AppKit

func installMainMenu() {
    let mainMenu = NSMenu()  
    
    let appMenuItem = NSMenuItem()  
    let appMenu = NSMenu()  
    
    appMenu.addItem(  
        withTitle: "Quit",  
        action: #selector(NSApplication.terminate(_:)),  
        keyEquivalent: "q"  
    )  
    
    appMenuItem.submenu = appMenu  
    mainMenu.addItem(appMenuItem)  
    
    let editMenuItem = NSMenuItem()  
    let editMenu = NSMenu(title: "Edit")  
    
    editMenu.addItem(  
        withTitle: "Undo",  
        action: #selector(NSResponder.undo(_:)),  
        keyEquivalent: "z"  
    )  
    
    editMenu.addItem(  
        withTitle: "Redo",  
        action: #selector(NSResponder.redo(_:)),  
        keyEquivalent: "Z"  
    )  
    
    editMenu.addItem(.separator())  
    
    editMenu.addItem(  
        withTitle: "Cut",  
        action: #selector(NSText.cut(_:)),  
        keyEquivalent: "x"  
    )  
    
    editMenu.addItem(  
        withTitle: "Copy",  
        action: #selector(NSText.copy(_:)),  
        keyEquivalent: "c"  
    )  
    
    editMenu.addItem(  
        withTitle: "Paste",  
        action: #selector(NSText.paste(_:)),  
        keyEquivalent: "v"  
    )  
    
    editMenu.addItem(  
        withTitle: "Select All",  
        action: #selector(NSText.selectAll(_:)),  
        keyEquivalent: "a"  
    )  
    
    editMenu.addItem(.separator())  
    
    editMenu.addItem(  
        withTitle: "Find...",  
        action: #selector(NSResponder.performFindPanelAction(_:)),  
        keyEquivalent: "f"  
    )  
    
    editMenu.addItem(  
        withTitle: "Find Next",  
        action: #selector(NSResponder.findNext(_:)),  
        keyEquivalent: "g"  
    )  
    
    editMenu.addItem(  
        withTitle: "Find Previous",  
        action: #selector(NSResponder.findPrevious(_:)),  
        keyEquivalent: "G"  
    )  
    
    editMenu.addItem(.separator())  
    
    editMenu.addItem(  
        withTitle: "Duplicate",  
        action: #selector(NSResponder.duplicate(_:)),  
        keyEquivalent: "d"  
    )  
    
    editMenuItem.submenu = editMenu  
    mainMenu.addItem(editMenuItem)  
    
    NSApp.mainMenu = mainMenu  
}