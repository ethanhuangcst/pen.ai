# Global Objects in Pen AI

This document lists all global objects used in the Pen AI application, including singletons and static properties.

## Singleton Objects

| Object Name | Type | Location | Purpose |
|------------|------|----------|--------|
| `PenWindowService.shared` | Singleton | Sources/Services/PenWindowService.swift | Manages the Pen application window, including creation, positioning, and UI updates |
| `AIManager.shared` | Singleton | Sources/Services/AIManager.swift | Manages AI configurations and providers, handles API calls to AI services |
| `UserService.shared` | Singleton | Sources/Services/UserService.swift | Manages user information, login status, and user-related operations |
| `PromptsService.shared` | Singleton | Sources/Services/PromptsService.swift | Manages user prompts, including loading, saving, and updating prompts |
| `LocalizationService.shared` | Singleton | Sources/Services/LocalizationService.swift | Provides localized strings for the UI |
| `ShortcutService.shared` | Singleton | Sources/Services/ShortcutService.swift | Manages keyboard shortcuts for the application |
| `DatabaseConnectivityPool.shared` | Singleton | Sources/Services/DatabaseConnectivityPool.swift | Manages database connections and pool |
| `DatabaseConfig.shared` | Singleton | Sources/Services/DatabaseConfig.swift | Loads and provides database configuration |
| `AuthenticationService.shared` | Singleton | Sources/Services/AuthenticationService.swift | Handles user authentication, login, and logout |
| `InternetConnectivityServiceTest.shared` | Singleton | Sources/Services/InternetConnectivityServiceTest.swift | Tests internet connectivity |
| `KeychainService.shared` | Singleton | Sources/Services/KeychainService.swift | Manages secure storage of user credentials |

## Static Properties

| Property Name | Type | Location | Purpose |
|--------------|------|----------|--------|
| `NewOrEditPrompt.isWindowOpen` | Bool | Sources/Views/NewOrEditPrompt.swift | Tracks if the NewOrEditPrompt window is currently open |
| `NewOrEditPrompt.currentInstance` | NewOrEditPrompt? | Sources/Views/NewOrEditPrompt.swift | Holds the current instance of NewOrEditPrompt window |
| `BaseWindow.messageQueue` | [String] | Sources/Views/BaseWindow.swift | Queue for popup messages |
| `BaseWindow.isDisplayingMessage` | Bool | Sources/Views/BaseWindow.swift | Tracks if a popup message is currently being displayed |

## Global State Management

The application uses a combination of singleton services to manage global state:

1. **User State**: Managed by `UserService.shared`
   - Current user information
   - Login status
   - User preferences

2. **AI Configuration State**: Managed by `AIManager.shared`
   - AI provider configurations
   - API keys
   - Connection status

3. **Prompt State**: Managed by `PromptsService.shared`
   - User prompts
   - System prompts

4. **Window State**: Managed by `PenWindowService.shared`
   - Window position and visibility
   - UI component states

5. **Database State**: Managed by `DatabaseConnectivityPool.shared`
   - Database connections
   - Connection pool management

## Usage Patterns

Global objects are typically accessed using the singleton pattern:

```swift
// Accessing a singleton
someValue = SomeService.shared.someMethod()

// Setting global state
SomeService.shared.someProperty = newValue
```

## Considerations

- **Thread Safety**: Some singletons may require thread safety considerations, especially when accessed from multiple threads
- **Memory Management**: Singletons persist for the lifetime of the application, so memory usage should be monitored
- **Testing**: Singletons can make unit testing more challenging, as they introduce global state
- **Dependency Injection**: Consider using dependency injection for better testability and flexibility

## Conclusion

The Pen AI application uses a singleton-based approach for managing global state and services. This provides a consistent way to access shared resources throughout the application, but also introduces some challenges that should be considered during development and testing.