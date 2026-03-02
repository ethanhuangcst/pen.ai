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
        action: Selector("undo:"),  
        keyEquivalent: "z"  
    )  
    
    editMenu.addItem(  
        withTitle: "Redo",  
        action: Selector("redo:"),  
        keyEquivalent: "Z"  
    )  
    
    editMenu.addItem(.separator())  
    
    editMenu.addItem(  
        withTitle: "Cut",  
        action: Selector("cut:"),  
        keyEquivalent: "x"  
    )  
    
    editMenu.addItem(  
        withTitle: "Copy",  
        action: Selector("copy:"),  
        keyEquivalent: "c"  
    )  
    
    editMenu.addItem(  
        withTitle: "Paste",  
        action: Selector("paste:"),  
        keyEquivalent: "v"  
    )  
    
    editMenu.addItem(  
        withTitle: "Select All",  
        action: Selector("selectAll:"),  
        keyEquivalent: "a"  
    )  
    
    editMenu.addItem(.separator())  
    
    editMenu.addItem(  
        withTitle: "Find...",  
        action: Selector("performFindPanelAction:"),  
        keyEquivalent: "f"  
    )  
    
    editMenu.addItem(  
        withTitle: "Find Next",  
        action: Selector("findNext:"),  
        keyEquivalent: "g"  
    )  
    
    editMenu.addItem(  
        withTitle: "Find Previous",  
        action: Selector("findPrevious:"),  
        keyEquivalent: "G"  
    )  
    
      
    
    editMenuItem.submenu = editMenu  
    mainMenu.addItem(editMenuItem)  
    
    NSApp.mainMenu = mainMenu  
}