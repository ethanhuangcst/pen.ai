import Foundation

// Test script to verify base_urls parsing

print("Testing base_urls parsing...")

// Simulate the row data with the actual JSON array format from the database
let testRow: [String: Any] = [
    "id": "gpt-4o-mini",
    "name": "gpt-4o-mini",
    "base_urls": "[\" `https://openaiss.com/v1` \", \" `https://openaiss.com` \", \" `https://api.openai.com/v1` \"]",
    "default_model": "gpt-4o-mini",
    "requires_auth": 1,
    "auth_header": "Authorization"
]

print("\nTesting with JSON array format:")
print("base_urls: \(testRow["base_urls"] as! String)")

// Test the fromDatabaseRow method
if let provider = AIModelProvider.fromDatabaseRow(testRow) {
    print("\nSuccessfully created provider:")
    print("Name: \(provider.name)")
    print("Base URLs: \(provider.baseURLs)")
} else {
    print("\nFailed to create provider")
}

// Also test with a clean JSON array
let cleanTestRow: [String: Any] = [
    "id": "gpt-4o-mini",
    "name": "gpt-4o-mini",
    "base_urls": "[\"https://openaiss.com/v1\", \"https://openaiss.com\", \"https://api.openai.com/v1\"]",
    "default_model": "gpt-4o-mini",
    "requires_auth": 1,
    "auth_header": "Authorization"
]

print("\n\nTesting with clean JSON array format:")
print("base_urls: \(cleanTestRow["base_urls"] as! String)")

if let provider = AIModelProvider.fromDatabaseRow(cleanTestRow) {
    print("\nSuccessfully created provider:")
    print("Name: \(provider.name)")
    print("Base URLs: \(provider.baseURLs)")
} else {
    print("\nFailed to create provider")
}

print("\n=== Test completed ====")
