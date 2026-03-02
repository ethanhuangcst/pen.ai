# Content History Design

## 1. ContentHistoryModel

### 1.1 Data Structure

| Field Name | Data Type | Description | Constraints |
|------------|-----------|-------------|-------------|
| `uuid` | `UUID` | Unique identifier for the history record | Primary key |
| `userID` | `UUID` | ID of the user who owns this history record | Foreign key to users table |
| `enhanceDateTime` | `Date` | Timestamp when the content was enhanced | Not null |
| `originalContent` | `String` | The original content before enhancement | Not null |
| `enhancedContent` | `String` | The content after enhancement by AI | Not null |
| `promptText` | `String` | The prompt used for enhancement | Not null |
| `aiProvider` | `String` | The AI provider used for enhancement | Not null |
| `isHidden` | `Bool` | Soft delete flag | Default: false |

### 1.2 Initialization

```swift
init(
    uuid: UUID = UUID(),
    userID: UUID,
    enhanceDateTime: Date = Date(),
    originalContent: String,
    enhancedContent: String,
    promptText: String,
    aiProvider: String,
    isHidden: Bool = false
)
```

## 2. ContentHistoryService

### 2.1 Overview

The `ContentHistoryService` is responsible for managing all operations related to content history, including creating, reading, and managing history records.

### 2.2 Methods

#### 2.2.1 readHistoryCount

**Purpose**: Get the count of non-deleted history records for a user.

**Parameters**:
- `userID: UUID` - The ID of the user whose history count is to be read.

**Returns**:
- `Result<Int, Error>` - The count of history records or an error.

**Implementation**:
```swift
func readHistoryCount(userID: UUID) -> Result<Int, Error> {
    do {
        let count = try wingman_db.users.content_history
            .filter({ $0.userID == userID && !$0.isHidden })
            .count
        return .success(count)
    } catch {
        return .failure(error)
    }
}
```

#### 2.2.2 loadHistoryByUserID

**Purpose**: Load recent history records for a user, sorted by date (most recent first).

**Parameters**:
- `userID: UUID` - The ID of the user whose history records are to be loaded.
- `count: Int` - The maximum number of history records to load.

**Returns**:
- `Result<[ContentHistoryModel], Error>` - An array of history records or an error.

**Implementation**:
```swift
func loadHistoryByUserID(userID: UUID, count: Int) -> Result<[ContentHistoryModel], Error> {
    do {
        let history = try wingman_db.users.content_history
            .filter({ $0.userID == userID && !$0.isHidden })
            .sorted(by: { $0.enhanceDateTime > $1.enhanceDateTime })
            .prefix(count)
            .map { ContentHistoryModel(from: $0) }
        return .success(history)
    } catch {
        return .failure(error)
    }
}
```

#### 2.2.3 addToHistoryByUserID

**Purpose**: Add a new history record for a user.

**Parameters**:
- `history: ContentHistoryModel` - The history record to add.
- `userID: UUID` - The ID of the user to whom the history record belongs.

**Returns**:
- `Result<Bool, Error>` - `true` if the addition was successful, or an error.

**Implementation**:
```swift
func addToHistoryByUserID(history: ContentHistoryModel, userID: UUID) -> Result<Bool, Error> {
    do {
        try wingman_db.users.content_history.insert(history)
        // After adding, check if we need to trim old records
        try trimHistoryIfNeeded(userID: userID)
        return .success(true)
    } catch {
        return .failure(error)
    }
}
```

#### 2.2.4 resetHistoryByUserID

**Purpose**: Soft delete all history records for a user.

**Parameters**:
- `userID: UUID` - The ID of the user whose history records are to be reset.

**Returns**:
- `Result<Bool, Error>` - `true` if the reset was successful, or an error.

**Implementation**:
```swift
func resetHistoryByUserID(userID: UUID) -> Result<Bool, Error> {
    do {
        try wingman_db.users.content_history
            .filter({ $0.userID == userID && !$0.isHidden })
            .forEach { record in
                record.isHidden = true
            }
        return .success(true)
    } catch {
        return .failure(error)
    }
}
```

#### 2.2.5 trimHistoryIfNeeded (Private)

**Purpose**: Trim old history records if the count exceeds the user's limit.

**Parameters**:
- `userID: UUID` - The ID of the user whose history to trim.

**Returns**:
- `Result<Bool, Error>` - `true` if trimming was successful, or an error.

**Implementation**:
```swift
private func trimHistoryIfNeeded(userID: UUID) throws -> Bool {
    // Get user's history limit from preferences
    let historyLimit = try wingman_db.users.preferences
        .filter({ $0.userID == userID })
        .first?
        .contentHistoryCount ?? 10
    
    // Get current history count
    let currentCount = try readHistoryCount(userID: userID).get()
    
    if currentCount > historyLimit {
        // Get oldest records to delete
        let recordsToDelete = try wingman_db.users.content_history
            .filter({ $0.userID == userID && !$0.isHidden })
            .sorted(by: { $0.enhanceDateTime < $1.enhanceDateTime })
            .prefix(currentCount - historyLimit)
        
        // Soft delete the oldest records
        for record in recordsToDelete {
            record.isHidden = true
        }
    }
    
    return true
}
```

## 3. Database Schema

### 3.1 content_history Table

| Column Name | Data Type | Constraints |
|-------------|-----------|-------------|
| `uuid` | `VARCHAR(36)` | PRIMARY KEY |
| `user_id` | `VARCHAR(36)` | FOREIGN KEY REFERENCES users(uuid) |
| `enhance_datetime` | `DATETIME` | NOT NULL |
| `original_content` | `TEXT` | NOT NULL |
| `enhanced_content` | `TEXT` | NOT NULL |
| `prompt_text` | `TEXT` | NOT NULL |
| `ai_provider` | `VARCHAR(255)` | NOT NULL |
| `is_hidden` | `BOOLEAN` | DEFAULT FALSE |
| `created_at` | `DATETIME` | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | `DATETIME` | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |

## 4. Integration

### 4.1 With PenWindowService

The `PenWindowService` will use `ContentHistoryService` to:
1. Add a new history record after successfully enhancing content
2. Load history records when the user opens the History tab in Preferences

### 4.2 With PreferencesService

The `PreferencesService` will use `ContentHistoryService` to:
1. Reset history when the user requests it
2. Trim history when the user changes the history limit

## 5. Error Handling

| Error Type | Description | Handling |
|------------|-------------|----------|
| `DatabaseError` | Database operation failed | Return error to caller, log detailed error |
| `InvalidUserError` | User ID is invalid or not found | Return error to caller, show user-friendly message |
| `HistoryLimitError` | History limit exceeded | Auto-trim old records, no error returned |

## 6. Performance Considerations

1. **Indexing**: Add index on `user_id` and `enhance_datetime` columns for faster queries
2. **Batch Operations**: Use batch operations when trimming multiple history records
3. **Lazy Loading**: Implement lazy loading for history records to improve performance with large histories
4. **Caching**: Consider caching recent history records for faster access

## 7. Security

1. **Access Control**: Ensure users can only access their own history records
2. **Data Validation**: Validate all input data before storing in the database
3. **Sanitization**: Sanitize content to prevent SQL injection and other security issues
4. **Encryption**: Consider encrypting sensitive content in the database