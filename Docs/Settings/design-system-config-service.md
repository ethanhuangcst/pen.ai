# System Config Service Design

## Overview

This document describes the design for the `SystemConfigService` which will manage system configurations stored in the `system_config` database table. The service will replace the existing `ContentHistoryConfigService` and extend its functionality to include default prompt management.

## Design of SystemConfigService

### Architecture

- **Singleton Pattern**: The service will follow the singleton pattern to ensure a single instance throughout the application lifecycle.
- **Database Integration**: Will use the existing database connectivity pool to interact with the `system_config` table.
- **Caching**: Will cache configuration values in memory for fast access during runtime.
- **Lazy Loading**: Will load configuration from the database only when needed.

### Class Structure

```swift
class SystemConfigService {
    static let shared = SystemConfigService()
    
    // Content history count constants
    var CONTENT_HISTORY_LOW = 10
    var CONTENT_HISTORY_MEDIUM = 20
    var CONTENT_HISTORY_HIGH = 40
    
    // Default prompt settings
    var DEFAULT_PROMPT_NAME: String? = "Enhance English"
    var DEFAULT_PROMPT_TEXT: String? = "Enhance English for the following text: "
    
    // Default prompt constant
    static let DEFAULT_PROMPT_FLAG = 1 // Value for is_default column
    
    private init() {
        loadConfig()
    }
    
    func loadConfig() {
        // Load configuration from database
        // If no record exists, load default prompt from file and create database record
    }
    
    func updateConfig() {
        // Update configuration in database
    }
    
    // Default prompt methods
    func getDefaultPrompt() -> (name: String, text: String) {
        // Return default prompt as tuple
    }
    
    func setDefaultPrompt(name: String, text: String) {
        // Update default prompt values
    }
    
    // File loading methods
    private func loadDefaultPromptFromFile() -> (name: String, text: String)? {
        // Load default prompt from default_prompt.md file
    }
}
```

### Key Methods

1. **loadConfig()**: Loads configuration from the `system_config` table. If no record exists, loads default prompt from default_prompt.md file and creates database record with those values.
2. **updateConfig()**: Updates the configuration in the database with current values, including default prompt settings.
3. **getDefaultPrompt()**: Returns the default prompt as a tuple of (name, text).
4. **setDefaultPrompt(name: String, text: String)**: Updates the default prompt values in memory and persists them to the database.
5. **getContentHistoryCount(level: String)**: Returns the content history count for a specific level (LOW, MEDIUM, HIGH).
6. **setContentHistoryCount(level: String, value: Int)**: Updates the content history count for a specific level in memory and persists it to the database.
7. **loadDefaultPromptFromFile()**: Loads default prompt from default_prompt.md file located in the same folder as KeyChain. If file is missing, uses predefined fallback values.

## Code Changes Against Current Implementation

### Current Implementation

- **ContentHistoryConfigService.swift**: Currently uses a local JSON file (`CONTENT_HISTORY_COUNT.json`) to store content history count values.
- **GeneralTabView.swift**: Uses hardcoded values or values from `ContentHistoryConfigService`.
- **Pen.swift**: Initializes `ContentHistoryConfigService` at app launch.
- **Default Prompt Implementation**: Currently loads default prompt from `default_prompt.md` file located in the same folder as KeyChain, with a special DEFAULT prompt ID.

### Proposed Changes

1. **Replace ContentHistoryConfigService with SystemConfigService**:
   - Create `SystemConfigService.swift` that interacts with the `system_config` database table.
   - Remove `ContentHistoryConfigService.swift`.

2. **Update GeneralTabView.swift**:
   - Change to use `SystemConfigService.shared` instead of `ContentHistoryConfigService.shared`.

3. **Update Pen.swift**:
   - Change initialization to use `SystemConfigService.shared` instead of `ContentHistoryConfigService.shared`.

4. **Add Database Migration**:
   - Create a migration to add the `system_config` table with default values, including default prompt settings.

5. **Update Prompt-Related Files**:
   - Modify any files that currently handle default prompts to use `SystemConfigService.shared.getDefaultPrompt()` instead of hardcoded values.
   - Update prompt creation and management logic to integrate with the new service.

6. **Implement Default Prompt File Loading**:
   - Add `loadDefaultPromptFromFile()` method to `SystemConfigService` to load default prompt from `default_prompt.md`.
   - Update `loadConfig()` to use file loading as fallback when database record doesn't exist.
   - Ensure the DEFAULT_PROMPT_ID constant is properly defined and used.

## Impact Analysis

### Positive Impact

1. **Centralized Management**: Configuration can be managed centrally through the database, making it easier to update values without modifying code.
2. **Extended Functionality**: Adds support for default prompt management, allowing users to customize default prompts.
3. **Improved Reliability**: Database storage is more reliable than file storage, especially in case of file system issues.
4. **Consistency**: Uses the same database infrastructure as other parts of the application.
5. **Enhanced User Experience**: Users can now set and persist their preferred default prompts across application restarts.
6. **Backward Compatibility**: Maintains compatibility with existing default_prompt.md file structure while adding database persistence.
7. **Fallback Mechanism**: Provides a robust fallback to file-based loading when database record doesn't exist.

### Potential Risks

1. **Database Dependency**: The service will be dependent on database connectivity. If the database is unavailable, the service will need to fall back to default values.
2. **Migration Complexity**: Adding a new database table requires a migration, which must be handled carefully.
3. **Performance Impact**: Database operations may be slower than file operations, but caching should mitigate this.

### Mitigation Strategies

1. **Fallback Mechanism**: Implement a fallback to hardcoded default values if database operations fail.
2. **Caching**: Cache configuration values in memory to reduce database access.
3. **Error Handling**: Implement robust error handling for database operations.
4. **Migration Plan**: Create a clear migration plan to ensure the `system_config` table is created correctly.

## Step-by-Step Implementation Plan

### Phase 1: Database Migration

1. **Create Migration Script**: Create a SQL script to add the `system_config` table with default values.
2. **Test Migration**: Test the migration in a development environment to ensure it works correctly.
3. **Apply Migration**: Apply the migration to the production database.

### Phase 2: SystemConfigService Implementation

1. **Create SystemConfigService.swift**: Implement the singleton service with database integration.
2. **Implement Core Methods**: Implement `loadConfig()`, `updateConfig()`, and other key methods, including default prompt methods.
3. **Implement Default Prompt File Loading**: Add `loadDefaultPromptFromFile()` method to load default prompt from `default_prompt.md` file.
4. **Add Error Handling**: Add robust error handling for database operations and file loading.
5. **Implement Caching**: Add in-memory caching of configuration values, including default prompt settings.

### Phase 3: Integration

1. **Update Pen.swift**: Change initialization to use `SystemConfigService.shared`.
2. **Update GeneralTabView.swift**: Change to use `SystemConfigService.shared` for content history count values.
3. **Update Prompt-Related Files**: Modify any files that handle default prompts to use `SystemConfigService.shared.getDefaultPrompt()` instead of hardcoded values.
4. **Remove ContentHistoryConfigService**: Remove the old service and its related files.

### Phase 4: Testing

1. **Unit Tests**: Write unit tests for the `SystemConfigService`, including tests for default prompt methods and file loading functionality.
2. **Integration Tests**: Test the service with the actual database, including testing default prompt persistence and file-based fallback.
3. **End-to-End Tests**: Test the entire flow from app launch to configuration loading, including default prompt initialization from file and database.
4. **Edge Case Tests**: Test scenarios such as database unavailability, corrupted records, and missing default_prompt.md file.
5. **File Loading Tests**: Test loading default prompt from various file formats and edge cases.

### Phase 5: Deployment

1. **Code Review**: Conduct a code review to ensure quality and security.
2. **Deployment**: Deploy the changes to production.
3. **Monitoring**: Monitor the service in production to ensure it works correctly.

## Conclusion

The `SystemConfigService` will provide a robust and flexible way to manage system configurations, including content history count values and default prompt settings. By storing configurations in the database, we enable centralized management and extend the functionality to include default prompt management. This allows users to customize their default prompts and have those preferences persist across application restarts.

The implementation incorporates a hybrid approach that maintains compatibility with the existing `default_prompt.md` file structure while adding database persistence. This ensures backward compatibility while providing the benefits of centralized configuration management. The service includes a robust fallback mechanism that loads default prompts from the file system when database records don't exist, ensuring reliable operation even in edge cases.

The implementation plan provides a clear roadmap for transitioning from the current file-based approach to the new database-based approach, including specific steps for integrating default prompt handling into the existing codebase. The service will enhance the user experience by providing a consistent and reliable way to manage system configurations, including both content history settings and default prompt preferences.