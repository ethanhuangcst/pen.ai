import Foundation

// Test script to execute loadAllProviders() and print results

print("Testing AIConnectionService.loadAllProviders()...")

// Create database pool
let databasePool = DatabaseConnectivityPool.shared

// Wait for pool to initialize
print("Waiting for database pool to initialize...")
Thread.sleep(forTimeInterval: 2.0)

if !databasePool.isReady {
    print("Error: Database pool is not ready")
    exit(1)
}

print("Database pool ready. Creating AIConnectionService...")

// Create AIConnectionService
let aiService = AIConnectionService(databasePool: databasePool)

print("AIConnectionService created. Loading providers...")

do {
    let providers = try aiService.loadAllProviders()
    
    print("\nSuccessfully loaded \(providers.count) AI providers:")
    print("=====================================")
    
    for (index, provider) in providers.enumerated() {
        print("\nProvider \(index + 1):")
        print("ID: \(provider.id)")
        print("Name: \(provider.name)")
        print("Default Model: \(provider.defaultModel)")
        print("Requires Auth: \(provider.requiresAuth)")
        print("Auth Header: \(provider.authHeader)")
        print("Base URLs: \(provider.baseURLs)")
        print("Created At: \(provider.createdAt)")
        if let updatedAt = provider.updatedAt {
            print("Updated At: \(updatedAt)")
        }
        print("-------------------------------------")
    }
    
    print("\nTest completed successfully!")
    
} catch {
    print("Error loading providers: \(error)")
}

// Shutdown the pool
databasePool.shutdown()
print("Database pool shutdown")
