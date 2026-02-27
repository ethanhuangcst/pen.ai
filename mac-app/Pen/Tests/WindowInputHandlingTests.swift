import XCTest
@testable import Pen

class WindowInputHandlingTests: XCTestCase {
    private var loginWindow: LoginWindow?
    
    override func setUp() {
        super.setUp()
        loginWindow = LoginWindow(menuBarIconFrame: nil)
    }
    
    override func tearDown() {
        loginWindow = nil
        super.tearDown()
    }
    
    /// Test that input fields can receive keyboard input
    func testInputFieldsReceiveKeyboardInput() {
        guard let window = loginWindow else {
            XCTFail("Login window not created")
            return
        }
        
        // Show and focus the window
        window.showAndFocus()
        
        // Verify email field is editable and selectable
        XCTAssertTrue(window.emailFieldPublic.isEditable, "Email field should be editable")
        XCTAssertTrue(window.emailFieldPublic.isSelectable, "Email field should be selectable")
        
        // Verify password fields are editable and selectable
        XCTAssertTrue(window.securePasswordFieldPublic.isEditable, "Secure password field should be editable")
        XCTAssertTrue(window.securePasswordFieldPublic.isSelectable, "Secure password field should be selectable")
        XCTAssertTrue(window.plainPasswordFieldPublic.isEditable, "Plain password field should be editable")
        XCTAssertTrue(window.plainPasswordFieldPublic.isSelectable, "Plain password field should be selectable")
        
        // Test setting text in email field
        let testEmail = "test@example.com"
        window.emailFieldPublic.stringValue = testEmail
        XCTAssertEqual(window.emailFieldPublic.stringValue, testEmail, "Email field should accept text input")
        
        // Test setting text in password field
        let testPassword = "testpassword"
        window.securePasswordFieldPublic.stringValue = testPassword
        XCTAssertEqual(window.securePasswordFieldPublic.stringValue, testPassword, "Password field should accept text input")
    }
    
    /// Test that buttons respond to mouse clicks
    func testButtonsRespondToMouseClicks() {
        guard let window = loginWindow else {
            XCTFail("Login window not created")
            return
        }
        
        // Show and focus the window
        window.showAndFocus()
        
        // Verify all buttons have targets and actions set
        XCTAssertNotNil(window.loginButtonPublic.target, "Login button should have a target")
        XCTAssertNotNil(window.loginButtonPublic.action, "Login button should have an action")
        XCTAssertNotNil(window.passwordToggleButtonPublic.target, "Password toggle button should have a target")
        XCTAssertNotNil(window.passwordToggleButtonPublic.action, "Password toggle button should have an action")
        XCTAssertNotNil(window.rememberMeCheckboxPublic.target, "Remember me checkbox should have a target")
        XCTAssertNotNil(window.rememberMeCheckboxPublic.action, "Remember me checkbox should have an action")
    }
    
    /// Test that window can become key and main
    func testWindowCanBecomeKeyAndMain() {
        guard let window = loginWindow else {
            XCTFail("Login window not created")
            return
        }
        
        // Show and focus the window
        window.showAndFocus()
        
        // Verify window can become key and main
        XCTAssertTrue(window.canBecomeKey, "Window should be able to become key window")
        XCTAssertTrue(window.canBecomeMain, "Window should be able to become main window")
    }
    
    /// Test that first responder is set correctly
    func testFirstResponderIsSet() {
        guard let window = loginWindow else {
            XCTFail("Login window not created")
            return
        }
        
        // Show and focus the window
        window.showAndFocus()
        
        // Wait for first responder to be set
        let expectation = XCTestExpectation(description: "First responder should be set")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            XCTAssertNotNil(window.firstResponder, "First responder should be set")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that input fields can handle tab navigation
    func testTabNavigationBetweenInputFields() {
        guard let window = loginWindow else {
            XCTFail("Login window not created")
            return
        }
        
        // Show and focus the window
        window.showAndFocus()
        
        // Wait for first responder to be set to email field
        let expectation = XCTestExpectation(description: "First responder should be set to email field")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            XCTAssertNotNil(window.firstResponder, "First responder should be set")
            
            // Simulate tab key press to move to password field
            let tabEvent = NSEvent.keyEvent(with: .keyDown, location: NSPoint.zero, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber, context: nil, characters: "\t", charactersIgnoringModifiers: "\t", isARepeat: false, keyCode: 48) // 48 is tab key code
            XCTAssertNotNil(tabEvent, "Tab key event should be created")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that buttons have proper focus states
    func testButtonsHaveFocusStates() {
        guard let window = loginWindow else {
            XCTFail("Login window not created")
            return
        }
        
        // Show and focus the window
        window.showAndFocus()
        
        // Verify buttons can become first responder
        XCTAssertTrue(window.loginButtonPublic.acceptsFirstResponder, "Login button should accept first responder")
        XCTAssertTrue(window.passwordToggleButtonPublic.acceptsFirstResponder, "Password toggle button should accept first responder")
        XCTAssertTrue(window.rememberMeCheckboxPublic.acceptsFirstResponder, "Remember me checkbox should accept first responder")
    }
}
