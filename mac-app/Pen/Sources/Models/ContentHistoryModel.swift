import Foundation
import MySQLKit

class ContentHistoryModel {
    let uuid: UUID
    let userID: Int
    let enhanceDateTime: Date
    let originalContent: String
    let enhancedContent: String
    let promptText: String
    let aiProvider: String
    let createdAt: Date
    let updatedAt: Date
    
    init(
        uuid: UUID = UUID(),
        userID: Int,
        enhanceDateTime: Date = Date(),
        originalContent: String,
        enhancedContent: String,
        promptText: String,
        aiProvider: String,
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from row: [String: Any]) {
        self.uuid = UUID(uuidString: row["uuid"] as? String ?? UUID().uuidString) ?? UUID()
        
        if let userIDInt = row["user_id"] as? Int {
            self.userID = userIDInt
        } else if let userIDString = row["user_id"] as? String, let userIDInt = Int(userIDString) {
            self.userID = userIDInt
        } else {
            self.userID = 0
        }
        
        if let enhanceDateTimeStr = row["enhance_datetime"] as? String {
            self.enhanceDateTime = Self.dateFromISOString(enhanceDateTimeStr) ?? Date()
        } else {
            self.enhanceDateTime = Date()
        }
        
        self.originalContent = row["original_content"] as? String ?? ""
        self.enhancedContent = row["enhanced_content"] as? String ?? ""
        self.promptText = row["prompt_text"] as? String ?? ""
        self.aiProvider = row["ai_provider"] as? String ?? ""
        
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
    
    func toDictionary() -> [String: Any] {
        return [
            "uuid": uuid.uuidString,
            "user_id": userID,
            "enhance_datetime": ContentHistoryModel.isoStringFromDate(enhanceDateTime),
            "original_content": originalContent,
            "enhanced_content": enhancedContent,
            "prompt_text": promptText,
            "ai_provider": aiProvider,
            "created_at": ContentHistoryModel.isoStringFromDate(createdAt),
            "updated_at": ContentHistoryModel.isoStringFromDate(updatedAt)
        ]
    }
    
    private static func dateFromISOString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        
        var processedString = string
        if let openParen = processedString.range(of: "(") {
            processedString = processedString.prefix(upTo: openParen.lowerBound).trimmingCharacters(in: .whitespaces)
        }
        
        if let range = processedString.range(of: " [+-]\\d{4}$", options: .regularExpression) {
            let substring = processedString[range]
            let fixed = substring.dropFirst()
            processedString.replaceSubrange(range, with: fixed)
        }
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: processedString) {
            return date
        }
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        if let date = formatter.date(from: processedString) {
            return date
        }
        
        formatter.dateFormat = "EEE MMM dd yyyy HH:mm:ss 'GMT'Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: processedString) {
            return date
        }
        
        formatter.dateFormat = "EEE MMM dd yyyy HH:mm:ss Z"
        if let date = formatter.date(from: processedString) {
            return date
        }
        
        formatter.dateFormat = "EEE MMM dd yyyy HH:mm:ss zzzz"
        if let date = formatter.date(from: processedString) {
            return date
        }
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        if let date = formatter.date(from: processedString) {
            return date
        }
        
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        if let date = formatter.date(from: processedString) {
            return date
        }
        
        return nil
    }
    
    public static func isoStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}
