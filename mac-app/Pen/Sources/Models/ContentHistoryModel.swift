import Foundation

// Forward declaration of ContentHistoryService
class ContentHistoryService

class ContentHistoryModel {
    let uuid: UUID
    let userID: UUID
    let enhanceDateTime: Date
    let originalContent: String
    let enhancedContent: String
    let promptText: String
    let aiProvider: String
    var isHidden: Bool
    let createdAt: Date
    let updatedAt: Date
    
    init(
        uuid: UUID = UUID(),
        userID: UUID,
        enhanceDateTime: Date = Date(),
        originalContent: String,
        enhancedContent: String,
        promptText: String,
        aiProvider: String,
        isHidden: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.uuid = uuid
        self.userID = userID
        self.enhanceDateTime = enhanceDateTime
        self.originalContent = originalContent
        self.enhancedContent = enhancedContent
        self.promptText = promptText
        self.aiProvider = aiProvider
        self.isHidden = isHidden
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Initialize from database row
    init(from row: [String: Any]) {
        self.uuid = UUID(uuidString: row["uuid"] as? String ?? UUID().uuidString) ?? UUID()
        self.userID = UUID(uuidString: row["user_id"] as? String ?? UUID().uuidString) ?? UUID()
        
        if let enhanceDateTimeStr = row["enhance_datetime"] as? String {
            self.enhanceDateTime = Self.dateFromISOString(enhanceDateTimeStr) ?? Date()
        } else {
            self.enhanceDateTime = Date()
        }
        
        self.originalContent = row["original_content"] as? String ?? ""
        self.enhancedContent = row["enhanced_content"] as? String ?? ""
        self.promptText = row["prompt_text"] as? String ?? ""
        self.aiProvider = row["ai_provider"] as? String ?? ""
        self.isHidden = row["is_hidden"] as? Bool ?? false
        
        if let createdAtStr = row["created_at"] as? String {
            self.createdAt = Self.dateFromISOString(createdAtStr) ?? Date()
        } else {
            self.createdAt = Date()
        }
        
        if let updatedAtStr = row["updated_at"] as? String {
            self.updatedAt = Self.dateFromISOString(updatedAtStr) ?? Date()
        } else {
            self.updatedAt = Date()
        }
    }
    
    // Convert to dictionary for database insertion
    func toDictionary() -> [String: Any] {
        return [
            "uuid": uuid.uuidString,
            "user_id": userID.uuidString,
            "enhance_datetime": ContentHistoryService.isoStringFromDate(enhanceDateTime),
            "original_content": originalContent,
            "enhanced_content": enhancedContent,
            "prompt_text": promptText,
            "ai_provider": aiProvider,
            "is_hidden": isHidden,
            "created_at": ContentHistoryService.isoStringFromDate(createdAt),
            "updated_at": ContentHistoryService.isoStringFromDate(updatedAt)
        ]
    }
    
    // Helper methods for date formatting
    private static func dateFromISOString(_ string: String) -> Date? {
        return ContentHistoryService.dateFromISOString(string)
    }
}
