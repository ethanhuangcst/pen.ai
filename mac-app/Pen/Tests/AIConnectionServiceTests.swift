import XCTest
@testable import Pen

class AIConnectionServiceTests: XCTestCase {
    private var service: AIConnectionService?
    
    override func setUp() {
        super.setUp()
        let databasePool = DatabaseConnectivityPool.shared
        service = AIConnectionService(databasePool: databasePool)
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    /// Test that AIConnectionService can load all providers
    func testLoadAllProviders() async {
        // Given the AIConnectionService is initialized
        guard let service = service else {
            XCTFail("Service should be initialized")
            return
        }
        
        // When loading all providers
        do {
            let providers = try await service.loadAllProviders()
            
            // Then providers should be loaded successfully
            XCTAssertGreaterThan(providers.count, 0, "Should load at least one provider")
            
            // Print the results for verification
            print("\nLoaded \(providers.count) AI providers:")
            for (index, provider) in providers.enumerated() {
                print("\nProvider \(index + 1):")
                print("ID: \(provider.id)")
                print("Name: \(provider.name)")
                print("Base URLs: \(provider.baseURLs)")
                print("Default Model: \(provider.defaultModel)")
                print("Requires Auth: \(provider.requiresAuth)")
                print("Auth Header: \(provider.authHeader)")
                print("Created At: \(provider.createdAt)")
                print("Updated At: \(provider.updatedAt ?? Date())")
            }
            
        } catch {
            XCTFail("Error loading providers: \(error)")
        }
    }
    
    /// Test that AIConnectionService can load provider by name
    func testLoadProviderByName() async {
        // Given the AIConnectionService is initialized
        guard let service = service else {
            XCTFail("Service should be initialized")
            return
        }
        
        // When loading a provider by name
        do {
            let provider = try await service.loadProviderByName("OpenAI")
            
            // Then provider should be loaded successfully
            XCTAssertNotNil(provider, "Should load OpenAI provider")
            XCTAssertEqual(provider?.name, "OpenAI", "Provider name should be OpenAI")
            
        } catch {
            XCTFail("Error loading provider by name: \(error)")
        }
    }
    
    /// Test that AIConnectionService returns default providers when database fails
    func testDefaultProviders() async {
        // Given the AIConnectionService is initialized
        guard let service = service else {
            XCTFail("Service should be initialized")
            return
        }
        
        // When database loading fails (will fall back to default providers)
        do {
            let providers = try await service.loadAllProviders()
            
            // Then default providers should be returned
            XCTAssertGreaterThan(providers.count, 0, "Should return default providers")
            
            // Verify at least one default provider is present
            let hasOpenAI = providers.contains { $0.name == "OpenAI" }
            XCTAssertTrue(hasOpenAI, "Should include OpenAI as default provider")
            
        } catch {
            XCTFail("Error loading default providers: \(error)")
        }
    }
}
