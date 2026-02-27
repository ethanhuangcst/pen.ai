import XCTest
@testable import Pen

class WindowVisualStylingTests: XCTestCase {
    private var appDelegate: PenAIDelegate?
    
    override func setUp() {
        super.setUp()
        appDelegate = PenAIDelegate()
    }
    
    override func tearDown() {
        appDelegate = nil
        super.tearDown()
    }
    
    /// Test that Pen AI window has consistent visual styling
    func testPenAIWindowVisualStyling() {
        // Simulate app launch to create the window
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        appDelegate?.applicationDidFinishLaunching(notification)
        
        guard let window = appDelegate?.window else {
            XCTFail("Window not created")
            return
        }
        
        // Test window properties
        XCTAssertTrue(window.styleMask.contains(.borderless), "Window should be borderless")
        XCTAssertFalse(window.isOpaque, "Window should be transparent")
        XCTAssertEqual(window.backgroundColor, .clear, "Window background should be clear")
        XCTAssertTrue(window.hasShadow, "Window should have shadow")
        XCTAssertEqual(window.level, .floating, "Window should be floating")
        
        // Test content view properties
        guard let contentView = window.contentView else {
            XCTFail("Content view not found")
            return
        }
        
        XCTAssertTrue(contentView.wantsLayer, "Content view should have layer")
        XCTAssertNotNil(contentView.layer, "Content view should have layer")
        XCTAssertEqual(contentView.layer?.cornerRadius, 12, "Content view should have rounded corners")
    }
    
    /// Test that Login window has consistent visual styling
    func testLoginWindowVisualStyling() {
        // Create login window
        let loginWindow = LoginWindow(menuBarIconFrame: nil)
        
        // Test window properties
        XCTAssertTrue(loginWindow.styleMask.contains(.borderless), "Window should be borderless")
        XCTAssertFalse(loginWindow.isOpaque, "Window should be transparent")
        XCTAssertEqual(loginWindow.backgroundColor, .clear, "Window background should be clear")
        XCTAssertTrue(loginWindow.hasShadow, "Window should have shadow")
        XCTAssertEqual(loginWindow.level, .floating, "Window should be floating")
        
        // Test content view properties
        guard let contentView = loginWindow.contentView else {
            XCTFail("Content view not found")
            return
        }
        
        XCTAssertTrue(contentView.wantsLayer, "Content view should have layer")
        XCTAssertNotNil(contentView.layer, "Content view should have layer")
        XCTAssertEqual(contentView.layer?.cornerRadius, 12, "Content view should have rounded corners")
    }
    
    /// Test that all windows have consistent visual styling
    func testAllWindowsHaveConsistentStyling() {
        // Simulate app launch to create the Pen AI window
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        appDelegate?.applicationDidFinishLaunching(notification)
        
        guard let penWindow = appDelegate?.window else {
            XCTFail("Pen AI window not created")
            return
        }
        
        // Create login window
        let loginWindow = LoginWindow(menuBarIconFrame: nil)
        
        // Verify both windows have the same visual styling properties
        XCTAssertEqual(penWindow.isOpaque, loginWindow.isOpaque, "Both windows should have the same opacity")
        XCTAssertEqual(penWindow.backgroundColor, loginWindow.backgroundColor, "Both windows should have the same background color")
        XCTAssertEqual(penWindow.hasShadow, loginWindow.hasShadow, "Both windows should have shadows")
        XCTAssertEqual(penWindow.level, loginWindow.level, "Both windows should have the same level")
        
        // Verify content views have the same styling
        guard let penContentView = penWindow.contentView, let loginContentView = loginWindow.contentView else {
            XCTFail("Content views not found")
            return
        }
        
        XCTAssertEqual(penContentView.wantsLayer, loginContentView.wantsLayer, "Both content views should have layers")
        XCTAssertEqual(penContentView.layer?.cornerRadius, loginContentView.layer?.cornerRadius, "Both content views should have the same corner radius")
    }
}
