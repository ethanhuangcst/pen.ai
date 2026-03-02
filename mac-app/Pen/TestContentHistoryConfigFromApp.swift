import Foundation

print("Testing ContentHistoryConfigService from app context...")

// Initialize the service
let configService = ContentHistoryConfigService.shared

print("ContentHistoryConfigService initialized successfully")
print("LOW: \(configService.CONTENT_HISTORY_LOW)")
print("MEDIUM: \(configService.CONTENT_HISTORY_MEDIUM)")
print("HIGH: \(configService.CONTENT_HISTORY_HIGH)")

print("Test completed successfully!")
