import Foundation

// Test script to verify AI provider loading functionality
print("Testing AI provider loading...")

// Get the shared database connectivity pool
let pool = DatabaseConnectivityPool.shared

// Wait for the pool to be ready
print("Waiting for database pool to be ready...")
for _ in 0..<10 {
    if pool.isReady {
        print("Database pool is ready!")
        break
    }
    sleep(1)
}

if !pool.isReady {
    print("ERROR: Database pool failed to initialize")
    exit(1)
}

// Create AIConnectionService instance
let service = AIConnectionService(databasePool: pool)

// Test loading all providers
Task {
    do {
        print("\nLoading all AI providers...")
        let providers = try await service.loadAllProviders()
        
        print("Loaded \(providers.count) AI providers:")
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
        
        // Test loading provider by name
        if !providers.isEmpty {
            let firstProviderName = providers[0].name
            print("\nLoading provider by name: \(firstProviderName)")
            if let provider = try await service.loadProviderByName(firstProviderName) {
                print("Successfully loaded provider: \(provider.name)")
            } else {
                print("Failed to load provider by name")
            }
        }
        
        print("\nTest completed successfully!")
        exit(0)
        
    } catch {
        print("Error loading providers: \(error)")
        exit(1)
    }
}

// Keep the program running until the async task completes
RunLoop.main.run()
