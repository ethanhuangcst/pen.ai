import Foundation

// Test script for ContentHistoryConfigService

print("Testing ContentHistoryConfigService...")

// Initialize the service
let configService = ContentHistoryConfigService.shared

print("ContentHistoryConfigService initialized successfully")
print("LOW: \(configService.CONTENT_HISTORY_LOW)")
print("MEDIUM: \(configService.CONTENT_HISTORY_MEDIUM)")
print("HIGH: \(configService.CONTENT_HISTORY_HIGH)")

print("Test completed successfully!")
