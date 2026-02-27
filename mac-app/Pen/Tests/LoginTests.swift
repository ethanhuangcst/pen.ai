import XCTest
@testable import Pen

class LoginTests: XCTestCase {
    private var loginWindow: LoginWindow?
    
    override func setUp() {
        super.setUp()
        loginWindow = LoginWindow(menuBarIconFrame: nil)
    }
    
    override func tearDown() {
        loginWindow = nil
        super.tearDown()
    }
    
    /// Test that login window has fixed size and cannot be resized
    func testLoginWindowFixedSize() {
        guard let window = loginWindow else {
            XCTFail("Login window not created")
            return
        }
        
        // Verify window size
        XCTAssertEqual(window.frame.width, 518, "Login window should have width 518px")
        XCTAssertEqual(window.frame.height, 318, "Login window should have height 318px")
        
        // Verify window style mask doesn't include resizable
        XCTAssertFalse(window.styleMask.contains(.resizable), "Login window should not be resizable")
    }
    
    /// Test that login window has password toggle button
    func testLoginWindowHasPasswordToggleButton() {
        guard let window = loginWindow else {
            XCTFail("Login window not created")
            return
        }
        
        // Verify password toggle button exists
        XCTAssertNotNil(window.passwordToggleButtonPublic, "Login window should have password toggle button")
    }
    
    /// Test that login window has remember me checkbox
    func testLoginWindowHasRememberMeCheckbox() {
        guard let window = loginWindow else {
            XCTFail("Login window not created")
            return
        }
        
        // Verify remember me checkbox exists
        XCTAssertNotNil(window.rememberMeCheckboxPublic, "Login window should have remember me checkbox")
    }
    
    /// Test that login window has register and forgot password links
    func testLoginWindowHasRegisterAndForgotPasswordLinks() {
        guard let window = loginWindow else {
            XCTFail("Login window not created")
            return
        }
        
        // Verify register link exists
        XCTAssertNotNil(window.registerLinkPublic, "Login window should have register link")
        
        // Verify forgot password link exists
        XCTAssertNotNil(window.forgotPasswordLinkPublic, "Login window should have forgot password link")
    }
    
    /// Test that login window can be closed
    func testLoginWindowCanBeClosed() {
        guard let window = loginWindow else {
            XCTFail("Login window not created")
            return
        }
        
        // Show the window
        window.showAndFocus()
        
        // Verify window is visible
        XCTAssertTrue(window.isVisible, "Login window should be visible")
        
        // Close the window
        window.orderOut(nil)
        
        // Verify window is not visible
        XCTAssertFalse(window.isVisible, "Login window should not be visible after closing")
    }
    
    /// Test that password toggle button works
    func testPasswordToggleButton() {
        guard let window = loginWindow else {
            XCTFail("Login window not created")
            return
        }
        
        // Show the window
        window.showAndFocus()
        
        // Verify initial state (password is secure)
        XCTAssertFalse(window.plainPasswordFieldPublic.isVisible, "Plain password field should be hidden initially")
        XCTAssertTrue(window.securePasswordFieldPublic.isVisible, "Secure password field should be visible initially")
        
        // Toggle password visibility
        window.passwordToggleButtonPublic.performClick(nil)
        
        // Verify state changed (password is not secure)
        XCTAssertTrue(window.plainPasswordFieldPublic.isVisible, "Plain password field should be visible after toggle")
        XCTAssertFalse(window.securePasswordFieldPublic.isVisible, "Secure password field should be hidden after toggle")
    }
    
    /// Test that remember me checkbox works
    func testRememberMeCheckbox() {
        guard let window = loginWindow else {
            XCTFail("Login window not created")
            return
        }
        
        // Show the window
        window.showAndFocus()
        
        // Verify initial state (unchecked)
        XCTAssertEqual(window.rememberMeCheckboxPublic.state, .off, "Remember me checkbox should be unchecked initially")
        
        // Toggle checkbox
        window.rememberMeCheckboxPublic.performClick(nil)
        
        // Verify state changed (checked)
        XCTAssertEqual(window.rememberMeCheckboxPublic.state, .on, "Remember me checkbox should be checked after toggle")
    }
}
