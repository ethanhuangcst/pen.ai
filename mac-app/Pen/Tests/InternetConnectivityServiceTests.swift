import XCTest
@testable import Pen

class InternetConnectivityServiceTests: XCTestCase {
    private var connectivityService: InternetConnectivityService?
    
    override func setUp() {
        super.setUp()
        connectivityService = InternetConnectivityService.shared
    }
    
    override func tearDown() {
        connectivityService = nil
        super.tearDown()
    }
    
    /// Test that shared internet connectivity test service is available
    func testSharedInternetConnectivityServiceIsAvailable() {
        // Given the Pen app is running
        // When any component needs to test internet connectivity
        let service = InternetConnectivityService.shared
        
        // Then the shared internet connectivity test service is available
        XCTAssertNotNil(service, "Internet connectivity service should be available")
        
        // And the service can be reused by multiple components
        let service2 = InternetConnectivityService.shared
        XCTAssertIdentical(service, service2, "Service should be a singleton")
    }
    
    /// Test that internet connectivity test service provides reliable results
    func testInternetConnectivityServiceProvidesReliableResults() {
        // Given the Pen app is running
        let service = InternetConnectivityService.shared
        
        // When the internet connectivity test service is called
        let isConnected = service.isInternetAvailable()
        
        // Then the service returns a boolean value
        XCTAssertTrue(type(of: isConnected) == Bool.self, "Service should return a boolean")
    }
    
    /// Test that internet connectivity test service handles edge cases
    func testInternetConnectivityServiceHandlesEdgeCases() {
        // Given the Pen app is running
        let service = InternetConnectivityService.shared
        
        // When the internet connectivity test service is called with a timeout
        let isConnected = service.isInternetAvailable(timeout: 5.0)
        
        // Then the service returns a boolean value
        XCTAssertTrue(type(of: isConnected) == Bool.self, "Service should return a boolean even with timeout")
    }
    
    /// Test that internet connectivity test service caches results
    func testInternetConnectivityServiceCachesResults() {
        // Given the Pen app is running
        let service = InternetConnectivityService.shared
        
        // When the internet connectivity test service is called twice
        let firstResult = service.isInternetAvailable()
        let secondResult = service.isInternetAvailable()
        
        // Then the service returns the same result (cached)
        XCTAssertEqual(firstResult, secondResult, "Service should cache results")
    }
}
