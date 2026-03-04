# Global Objects Architecture

This document describes the global objects and singleton services used in the Pen AI application.

## Singleton Objects

### Core Services (Global State Required)

| Object Name | Location | Purpose |
|------------|----------|--------|
| `UserService.shared` | Sources/Services/UserService.swift | Core user state management - current user info, login status, preferences |
| `AuthenticationService.shared` | Sources/Services/AuthenticationService.swift | Handles user authentication, login, logout, and password reset |
| `DatabaseConnectivityPool.shared` | Sources/Services/DatabaseConnectivityPool.swift | Central database connection management and pooling |
| `DatabaseConfig.shared` | Sources/Services/DatabaseConfig.swift | Single source of database configuration |
| `KeychainService.shared` | Sources/Services/KeychainService.swift | Secure credential storage for sensitive data |
| `LocalizationService.shared` | Sources/Services/LocalizationService.swift | Global resource for UI localization and language switching |

### Feature Services (Instantiated Per Use)

| Object Name | Location | Purpose |
|------------|----------|--------|
| `AIManager.shared` | Sources/Services/AIManager.swift | Manages AI configurations and API calls |
| `PenWindowService.shared` | Sources/Services/PenWindowService.swift | Manages the Pen application window |
| `PromptsService.shared` | Sources/Services/PromptsService.swift | Manages user prompts CRUD operations |
| `ShortcutService.shared` | Sources/Services/ShortcutService.swift | Manages keyboard shortcuts |
| `ContentHistoryService.shared` | Sources/Services/ContentHistoryService.swift | Manages content enhancement history |
| `SystemConfigService.shared` | Sources/Services/SystemConfigService.swift | System configuration values |
| `ColorService.shared` | Sources/Services/ColorService.swift | UI color management for light/dark mode |
| `EmailService.shared` | Sources/Services/EmailService.swift | Email sending for password reset |
| `InitializationService.shared` | Sources/Services/InitializationService.swift | App initialization and startup logic |
| `InternetConnectivityServiceTest.shared` | Sources/Services/InternetConnectivityServiceTest.swift | Tests internet connectivity |

## Static Properties

| Property Name | Type | Location | Purpose |
|--------------|------|----------|--------|
| `NewOrEditPrompt.isWindowOpen` | Bool | Sources/Views/NewOrEditPrompt.swift | Tracks if the NewOrEditPrompt window is currently open |
| `NewOrEditPrompt.currentInstance` | NewOrEditPrompt? | Sources/Views/NewOrEditPrompt.swift | Holds the current instance of NewOrEditPrompt window |
| `BaseWindow.messageQueue` | [String] | Sources/Views/BaseWindow.swift | Queue for popup messages |
| `BaseWindow.isDisplayingMessage` | Bool | Sources/Views/BaseWindow.swift | Tracks if a popup message is currently being displayed |

## Global State Management

The application uses a combination of singleton services to manage global state:

### User State
Managed by `UserService.shared`
- Current user information
- Login status
- User preferences

### AI Configuration State
Managed by `AIManager.shared`
- AI provider configurations
- API keys
- Connection status

### Prompt State
Managed by `PromptsService.shared`
- User prompts
- System prompts
- Default prompts

### Window State
Managed by `PenWindowService.shared`
- Window position and visibility
- UI component states

### Database State
Managed by `DatabaseConnectivityPool.shared`
- Database connections
- Connection pool management

## Architecture Decisions

### Why Singletons?

1. **Core Services** - Services like `UserService`, `AuthenticationService`, and `DatabaseConnectivityPool` need to maintain state across the entire application lifecycle and are accessed from multiple components.

2. **Configuration Services** - `DatabaseConfig`, `LocalizationService`, and `KeychainService` provide configuration and resources that should have a single source of truth.

3. **Feature Services** - Services like `AIManager`, `PromptsService`, and `PenWindowService` use singletons for convenience but could be refactored to dependency injection if needed.

### Design Considerations

- **Thread Safety**: Some singletons may require thread safety considerations when accessed from multiple threads
- **Memory Management**: Singletons persist for the lifetime of the application
- **Testing**: Singletons introduce global state which can make unit testing more challenging
- **Future Refactoring**: Feature services could be converted to dependency injection for better testability

## Usage Patterns

Global objects are accessed using the singleton pattern:

```swift
// Accessing a singleton service
let user = UserService.shared.currentUser
let prompts = PromptsService.shared.prompts

// Calling singleton methods
AIManager.shared.callAI(prompt: "Hello")

// Setting global state
LocalizationService.shared.setLanguage(.chineseSimplified)
```

## Service Dependencies

```
UserService
    └── AIManager (per user session)
    └── PromptsService (per user session)

PenWindowService
    └── depends on UserService
    └── depends on AIManager
    └── depends on PromptsService

InitializationService
    └── orchestrates all services during app startup
```
