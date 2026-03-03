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
    
    // Initialize from database row
    init(from row: [String: Any]) {
        print("========== ContentHistoryModel.init START ==========")
        print("[ContentHistoryModel] Row keys: \(row.keys.sorted())")
        fflush(stdout)
        
        self.uuid = UUID(uuidString: row["uuid"] as? String ?? UUID().uuidString) ?? UUID()
        
        // Handle userID as string or int
        if let userIDInt = row["user_id"] as? Int {
            self.userID = userIDInt
        } else if let userIDString = row["user_id"] as? String, let userIDInt = Int(userIDString) {
            self.userID = userIDInt
        } else {
            self.userID = 0
        }
        
        print("[ContentHistoryModel] Looking for enhance_datetime in row...")
        if let enhanceDateTimeStr = row["enhance_datetime"] as? String {
            print("[ContentHistoryModel] Found enhance_datetime: \(enhanceDateTimeStr)")
            fflush(stdout)
            if let date = Self.dateFromISOString(enhanceDateTimeStr) {
                self.enhanceDateTime = date
                print("[ContentHistoryModel] Parsed enhance_datetime: \(date)")
            } else {
                self.enhanceDateTime = Date()
                print("[ContentHistoryModel] Failed to parse enhance_datetime: \(enhanceDateTimeStr)")
            }
        } else {
            print("[ContentHistoryModel] enhance_datetime NOT found in row!")
            print("[ContentHistoryModel] Available keys: \(row.keys.sorted())")
            // Print all values for debugging
            for (key, value) in row.sorted(by: { $0.key < $1.key }) {
                print("[ContentHistoryModel]   \(key): \(value)")
            }
            fflush(stdout)
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
    
    // Convert to dictionary for database insertion
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
    
    // Helper methods for date formatting
    private static func dateFromISOString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        
        // Handle the specific format from MySQL: "Tue Mar 03 2026 11:45:50 GMT+0800 (China Standard Time)"
        // Remove timezone name in parentheses
        var processedString = string
        if let openParen = processedString.range(of: "(") {
            processedString = processedString.prefix(upTo: openParen.lowerBound).trimmingCharacters(in: .whitespaces)
        }
        
        // Handle format with space before timezone offset (e.g., "2026-03-03 14:50:15 +0000")
        // Remove the space before the timezone offset to make it parseable
        // Use regex to find and fix the pattern: space followed by +/- and 4 digits
        if let range = processedString.range(of: " [+-]\\d{4}$", options: .regularExpression) {
            let substring = processedString[range]
            let fixed = substring.dropFirst()
            processedString.replaceSubrange(range, with: fixed)
        }
        
        print("[ContentHistoryModel] Processing date string: \(processedString)")
        
        // Try format with timezone offset (e.g., "2026-03-03 13:33:26+0000")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: processedString) {
            print("[ContentHistoryModel] Successfully parsed with 'yyyy-MM-dd HH:mm:ssZ' format: \(date)")
            return date
        }
        
        // Try format with space before timezone (e.g., "2026-03-03 13:33:26 +0000")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        if let date = formatter.date(from: processedString) {
            print("[ContentHistoryModel] Successfully parsed with 'yyyy-MM-dd HH:mm:ss Z' format: \(date)")
            return date
        }
        
        // Try format with GMT timezone offset (e.g., "GMT+0800")
        formatter.dateFormat = "EEE MMM dd yyyy HH:mm:ss 'GMT'Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: processedString) {
            print("[ContentHistoryModel] Successfully parsed with GMT format: \(date)")
            return date
        }
        
        // Try format with timezone offset (e.g., "+0800")
        formatter.dateFormat = "EEE MMM dd yyyy HH:mm:ss Z"
        if let date = formatter.date(from: processedString) {
            print("[ContentHistoryModel] Successfully parsed with Z format: \(date)")
            return date
        }
        
        // Try format with full timezone name
        formatter.dateFormat = "EEE MMM dd yyyy HH:mm:ss zzzz"
        if let date = formatter.date(from: processedString) {
            print("[ContentHistoryModel] Successfully parsed with zzzz format: \(date)")
            return date
        }
        
        // Try standard MySQL format
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        if let date = formatter.date(from: processedString) {
            print("[ContentHistoryModel] Successfully parsed with MySQL format: \(date)")
            return date
        }
        
        // Try ISO format
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        if let date = formatter.date(from: processedString) {
            print("[ContentHistoryModel] Successfully parsed with ISO format: \(date)")
            return date
        }
        
        print("[ContentHistoryModel] Failed to parse date string: \(processedString)")
        return nil
    }
    
    public static func isoStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}
