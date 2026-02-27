import XCTest
@testable import Pen

class DatabaseConnectivityPoolTests: XCTestCase {
    private var pool: DatabaseConnectivityPool?
    
    override func setUp() {
        super.setUp()
        pool = DatabaseConnectivityPool.shared
    }
    
    override func tearDown() {
        pool?.shutdown()
        pool = nil
        super.tearDown()
    }
    
    /// Test that singleton Database Connectivity pool is initialized
    func testDatabaseConnectivityPoolIsInitializedAsSingleton() {
        // Given the Pen app is launching
        // When the application starts
        let pool1 = DatabaseConnectivityPool.shared
        
        // Then the Database Connectivity pool is initialized as a singleton
        XCTAssertNotNil(pool1, "Database connectivity pool should be available")
        
        // And the pool has a default size based on system resources
        XCTAssertGreaterThan(pool1.poolSize, 0, "Pool size should be greater than 0")
        
        // And the pool is ready for use by all components
        XCTAssertTrue(pool1.isReady, "Pool should be ready for use")
        
        // Verify singleton behavior
        let pool2 = DatabaseConnectivityPool.shared
        XCTAssertIdentical(pool1, pool2, "Pool should be a singleton")
    }
    
    /// Test that Database Connectivity pool manages connections efficiently
    func testDatabaseConnectivityPoolManagesConnectionsEfficiently() {
        // Given the Pen app is running
        // And the Database Connectivity pool is initialized
        let pool = DatabaseConnectivityPool.shared
        
        // When multiple components request database connections
        let connection1 = pool.getConnection()
        let connection2 = pool.getConnection()
        
        // Then the pool provides connections from the pool
        XCTAssertNotNil(connection1, "Pool should provide a connection")
        XCTAssertNotNil(connection2, "Pool should provide a second connection")
        
        // And the pool reuses connections when they are returned
        pool.returnConnection(connection1)
        let connection3 = pool.getConnection()
        XCTAssertNotNil(connection3, "Pool should reuse returned connection")
        
        // Return all connections
        pool.returnConnection(connection2)
        pool.returnConnection(connection3)
    }
    
    /// Test that Database Connectivity pool handles connection errors
    func testDatabaseConnectivityPoolHandlesConnectionErrors() {
        // Given the Pen app is running
        // And the Database Connectivity pool is initialized
        let pool = DatabaseConnectivityPool.shared
        
        // When a database connection fails
        let connection = pool.getConnection()
        XCTAssertNotNil(connection, "Pool should provide a connection")
        
        // Simulate connection failure
        pool.reportConnectionError(connection!)
        
        // Then the pool should still be able to provide connections
        let newConnection = pool.getConnection()
        XCTAssertNotNil(newConnection, "Pool should provide a new connection after error")
        
        // Return the connection
        pool.returnConnection(newConnection!)
    }
    
    /// Test that Database Connectivity pool is properly cleaned up
    func testDatabaseConnectivityPoolIsProperlyCleanedUp() {
        // Given the Pen app is running
        // And the Database Connectivity pool is initialized
        let pool = DatabaseConnectivityPool.shared
        
        // When the application is shutting down
        pool.shutdown()
        
        // Then the pool should be shut down
        XCTAssertFalse(pool.isReady, "Pool should not be ready after shutdown")
    }
}
