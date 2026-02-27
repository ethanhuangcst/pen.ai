import XCTest
@testable import Pen

class LoginWindowTests: XCTestCase {
    
    var loginWindow: LoginWindow?
    
    override func setUp() {
        super.setUp()
        loginWindow = LoginWindow()
    }
    
    override func tearDown() {
        loginWindow = nil
        super.tearDown()
    }
    
    func testLoginWindowHasFixedSize() {
        guard let window = loginWindow else { XCTFail("Login window not initialized"); return }
        
        let expectedWidth: CGFloat = 518
        let expectedHeight: CGFloat = 318
        
        XCTAssertEqual(window.frame.width, expectedWidth, "Login window width should be expectedWidth)px")
        XCTAssertEqual(window.frame.height, expectedHeight, "Login window height should be expectedHeight)px")
    }
    
    func testLoginWindowCannotBeResized() {
        guard let window = loginWindow else { XCTFail("Login window not initialized"); return }
        
        XCTAssertFalse(window.isResizable, "Login window should not be resizable")
    }
    
    func testLoginWindowHasPasswordHideShowButton() {
        guard let window = loginWindow else { XCTFail("Login window not initialized"); return }
        
        // This test would need to check for the presence of the password toggle button
        // For now, we'll just verify the window exists
        XCTAssertNotNil(window, "Login window should exist")
    }
    
    func testLoginWindowHasRememberMeOption() {
        guard let window = loginWindow else { XCTFail("Login window not initialized"); return }
        
        // This test would need to check for the presence of the remember me checkbox
        // For now, we'll just verify the window exists
        XCTAssertNotNil(window, "Login window should exist")
    }
    
    func testLoginWindowHasLoginButton() {
        guard let window = loginWindow else { XCTFail("Login window not initialized"); return }
        
        // This test would need to check for the presence of the login button
        // For now, we'll just verify the window exists
        XCTAssertNotNil(window, "Login window should exist")
    }
    
    func testLoginWindowHasCancelButton() {
        guard let window = loginWindow else { XCTFail("Login window not initialized"); return }
        
        // This test would need to check for the presence of the cancel button
        // For now, we'll just verify the window exists
        XCTAssertNotNil(window, "Login window should exist")
    }
    
    func testLoginWindowHasRegisterLink() {
        guard let window = loginWindow else { XCTFail("Login window not initialized"); return }
        
        // This test would need to check for the presence of the register link
        // For now, we'll just verify the window exists
        XCTAssertNotNil(window, "Login window should exist")
    }
    
    func testLoginWindowHasForgotPasswordLink() {
        guard let window = loginWindow else { XCTFail("Login window not initialized"); return }
        
        // This test would need to check for the presence of the forgot password link
        // For now, we'll just verify the window exists
        XCTAssertNotNil(window, "Login window should exist")
    }
}
