import AppKit

func installMainMenu() {
    let mainMenu = NSMenu()  
    
    let appMenuItem = NSMenuItem()  
    let appMenu = NSMenu()  
    
    appMenu.addItem(  
        withTitle: LocalizationService.shared.localizedString(for: "menu_quit"),  
        action: #selector(NSApplication.terminate(_:)),  
        keyEquivalent: "q"  
    )  
    
    appMenuItem.submenu = appMenu  
    mainMenu.addItem(appMenuItem)  
    
    let editMenuItem = NSMenuItem()  
    let editMenu = NSMenu(title: LocalizationService.shared.localizedString(for: "menu_edit"))  
    
    editMenu.addItem(  
        withTitle: LocalizationService.shared.localizedString(for: "menu_undo"),  
        action: Selector("undo:"),  
        keyEquivalent: "z"  
    )  
    
    editMenu.addItem(  
        withTitle: LocalizationService.shared.localizedString(for: "menu_redo"),  
        action: Selector("redo:"),  
        keyEquivalent: "Z"  
    )  
    
    editMenu.addItem(.separator())  
    
    editMenu.addItem(  
        withTitle: LocalizationService.shared.localizedString(for: "menu_cut"),  
        action: Selector("cut:"),  
        keyEquivalent: "x"  
    )  
    
    editMenu.addItem(  
        withTitle: LocalizationService.shared.localizedString(for: "menu_copy"),  
        action: Selector("copy:"),  
        keyEquivalent: "c"  
    )  
    
    editMenu.addItem(  
        withTitle: LocalizationService.shared.localizedString(for: "menu_paste"),  
        action: Selector("paste:"),  
        keyEquivalent: "v"  
    )  
    
    editMenu.addItem(  
        withTitle: LocalizationService.shared.localizedString(for: "menu_select_all"),  
        action: Selector("selectAll:"),  
        keyEquivalent: "a"  
    )  
    
    editMenu.addItem(.separator())  
    
    editMenu.addItem(  
        withTitle: LocalizationService.shared.localizedString(for: "menu_find"),  
        action: Selector("performFindPanelAction:"),  
        keyEquivalent: "f"  
    )  
    
    editMenu.addItem(  
        withTitle: LocalizationService.shared.localizedString(for: "menu_find_next"),  
        action: Selector("findNext:"),  
        keyEquivalent: "g"  
    )  
    
    editMenu.addItem(  
        withTitle: LocalizationService.shared.localizedString(for: "menu_find_previous"),  
        action: Selector("findPrevious:"),  
        keyEquivalent: "G"  
    )  
    
    editMenuItem.submenu = editMenu  
    mainMenu.addItem(editMenuItem)  
    
    NSApp.mainMenu = mainMenu  
}
