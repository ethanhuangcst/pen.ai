# Rename Plan: AIConnection → AIConfiguration

## FILES NOT TO RENAME:
1. **`AIConnectionService.swift`** (ACTUAL AI) - it handles actual AI connection logic
2. **`AIConnectionServiceTests.swift`** (ACTUAL AI) - it tests the actual AI connection logic


## Files to Rename
1. **`AIConnection.swift`** (CONFIG IN DB) → `AIConfiguration.swift`
2. **`AIConnectionTabView.swift`** (CONFIG IN DB) → `AIConfigurationTabView.swift`
3. **`TestAIConnectionService.swift`** (ACTUAL AI) → `TestAIConfigurationService.swift`

## CLASSES NOT TO RENAME

## Classes to Rename
1. **`AIConnection`** → `AIConfiguration` (CONFIG IN DB) - From AIConnection.swift
2. **`AIConnectionTabView`** → `AIConfigurationTabView` (CONFIG IN DB) - From AIConnectionTabView.swift

## Variables and Properties NOT to Rename
6. **`aiConnectionService`** → `aiConfigurationService` (ACTUAL AI) - From AIConnectionTabView.swift

## Variables and Properties to Rename
1. **`connections`** → `configurations` (CONFIG IN DB) - From AIConnectionTabView.swift
2. **`newConnection`** → `newConfiguration` (CONFIG IN DB) - From AIConnectionTabView.swift
3. **`validConnections`** → `validConfigurations` (CONFIG IN DB) - From AIConnectionTabView.swift
4. **`newlyCreatedConnections`** → `newlyCreatedConfigurations` (CONFIG IN DB) - From AIConnectionTabView.swift
5. **`connectionsForDelete`** → `configurationsForDelete` (CONFIG IN DB) - From AIConnectionTabView.swift


## Methods NOT to Rename
2. **`testAIConnection`** → `testAIConfiguration` (ACTUAL AI) - From AIConnectionTabView.swift



## Methods to Rename
1. **`deleteAIConnection`** → `deleteAIConfiguration` (CONFIG IN DB) - From AIConnectionTabView.swift
3. **`createAIConnectionTab`** → `createAIConfigurationTab` (CONFIG IN DB) - From main.swift
4. **`AIConnection.fromDatabaseRow`** → `AIConfiguration.fromDatabaseRow` (CONFIG IN DB) - From AIConnection.swift

## References to Update
- `PreferencesWindow.swift`
- `main.swift`
- `TestAIProviderLoading.swift`
- `TestProviders.swift`

## Implementation Steps
1. **Rename files** using the `mv` command
2. **Update class names** in each file
3. **Update all references** across the codebase
4. **Test the application** to ensure functionality is preserved

## Database Considerations
- **No database changes** will be made as it's shared with Wingman app
- **Database table names** will remain unchanged (`ai_connections`)
- **Column names** will remain unchanged

## Expected Outcome
- Improved code readability with clearer terminology
- No breaking changes to functionality
- Consistent naming throughout the codebase
- Compatibility with existing database structure