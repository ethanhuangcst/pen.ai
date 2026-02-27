import Foundation

// Test script to execute loadAllProviders() and print results

// Mock DatabaseConnectivityPool for testing
class MockDatabaseConnectivityPool: DatabaseConnectivityPool {
    init() {
        super.init(configuration: DatabaseConfig())
    }
    
    override func executeQuery(_ query: String, parameters: [Any]) throws -> [[String: Any]] {
        // Return mock data for testing
        return [
            [
                "id": 1,
                "name": "OpenAI",
                "base_urls": "{\"completion\": \"https://api.openai.com/v1/chat/completions\"}",
                "default_model": "gpt-4",
                "requires_auth": 1,
                "auth_header": "Authorization",
                "created_at": "2026-02-27T10:00:00Z",
                "updated_at": "2026-02-27T10:00:00Z"
            ],
            [
                "id": 2,
                "name": "Anthropic",
                "base_urls": "{\"completion\": \"https://api.anthropic.com/v1/messages\"}",
                "default_model": "claude-3-opus-20240229",
                "requires_auth": 1,
                "auth_header": "x-api-key",
                "created_at": "2026-02-27T10:00:00Z",
                "updated_at": "2026-02-27T10:00:00Z"
            ]
        ]
    }
    
    override func executeUpdate(_ query: String, parameters: [Any]) throws {
        // Mock implementation
    }
}

// Test the AIConnectionService
func testLoadAllProviders() {
    print("Testing AIConnectionService.loadAllProviders()...")
    
    do {
        let databasePool = MockDatabaseConnectivityPool()
        let service = AIConnectionService(databasePool: databasePool)
        
        let providers = try service.loadAllProviders()
        
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
        
        print("\nTest completed successfully!")
        
    } catch {
        print("Error: \(error)")
    }
}

// Run the test
testLoadAllProviders()
