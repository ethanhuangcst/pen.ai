# AI Manager Architecture

This document describes the architecture of the AI integration system in the Pen AI application.

## Overview

The AIManager class centralizes the management of AI interactions in the Pen AI application. It follows a singleton pattern and provides a unified interface for interacting with various AI providers (OpenAI, DeepSeek, Qwen, etc.).

## Architecture

```
App
└── AIManager (Singleton)
    ├── Provider Configuration
    ├── Request Builder
    ├── Transport Layer
    ├── Response Parser
    ├── Error Mapper
    └── Provider Strategy
```

## Core Components

### 1. AIManager Service

**Location**: `/mac-app/Pen/Sources/Services/AIManager.swift`

The AIManager is a singleton service that handles all AI-related operations:

| Method | Purpose |
|--------|---------|
| `callAI(prompt:content:)` | Main method for AI content enhancement |
| `testConnection(apiKey:provider:)` | Test AI provider connection |
| `loadProviderByName(_:)` | Load provider configuration from database |
| `loadAllProviders()` | Load all available providers |

### 2. AI Model Provider

**Location**: `/mac-app/Pen/Sources/Models/AIModelProvider.swift`

| Field | Type | Description |
|-------|------|-------------|
| `id` | `Int` | Unique identifier (primary key) |
| `name` | `String` | Provider name (e.g., "gpt-4o-mini", "deepseek3.2") |
| `baseURLs` | `[String]` | Array of API endpoint URLs |
| `defaultModel` | `String` | Default model to use |
| `requiresAuth` | `Bool` | Whether authentication is required |
| `authHeader` | `String` | Authentication header name |

### 3. AI Configuration

**Location**: `/mac-app/Pen/Sources/Models/AIConfiguration.swift`

| Field | Type | Description |
|-------|------|-------------|
| `id` | `Int` | Unique identifier |
| `userId` | `Int` | User who owns this configuration |
| `apiKey` | `String` | User's API key for the provider |
| `apiProvider` | `String` | Provider name |

## Supported AI Providers

| Provider | Name in DB | Default Model | Endpoint |
|----------|------------|---------------|----------|
| OpenAI | gpt-4o-mini | gpt-4o-mini | api.openai.com/v1 |
| DeepSeek | deepseek3.2 | deepseek-chat | api.deepseek.com/v1 |
| Qwen | qwen-plus | qwen-plus | dashscope.aliyuncs.com |

## Data Flow

```
1. User selects AI provider in Preferences
2. AIConfigurationTabView saves configuration to database
3. User triggers AI enhancement in Pen window
4. AIManager loads provider configuration
5. AIManager builds request with user's API key
6. Request sent to AI provider API
7. Response parsed and displayed to user
8. Enhancement saved to content_history table
```

## Provider Strategy Pattern

The AIManager uses a strategy pattern to handle different provider implementations:

```swift
protocol AIProviderStrategy {
    func buildChatPayload(messages: [AIMessage]) -> [String: Any]
    func parseChatResponse(data: Data) throws -> AIResponse
    var chatEndpoint: String { get }
}
```

### Generic Provider Strategy

Most providers follow the OpenAI-compatible API format:

```swift
class GenericProviderStrategy: AIProviderStrategy {
    private let provider: AIModelProvider
    
    func buildChatPayload(messages: [AIMessage]) -> [String: Any] {
        return [
            "model": provider.defaultModel,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": 0.7
        ]
    }
}
```

## Error Handling

```swift
enum AIError: Error {
    case invalidAPIKey
    case rateLimited
    case networkError
    case invalidResponse
    case providerError(String)
    case configurationError(String)
}
```

## Database Schema

### ai_providers Table

```sql
CREATE TABLE ai_providers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    base_urls JSON NOT NULL,
    default_model VARCHAR(100),
    requires_auth BOOLEAN DEFAULT TRUE,
    auth_header VARCHAR(50) DEFAULT 'Authorization',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### ai_connections Table

```sql
CREATE TABLE ai_connections (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT REFERENCES users(id),
    provider_id INT REFERENCES ai_providers(id),
    api_key VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## Usage Examples

### Configure and Test Connection

```swift
// Load user's AI configurations
let configurations = try await AIConnectionService.shared.loadConfigurations(for: userId)

// Test a connection
let success = try await AIManager.shared.testConnection(
    apiKey: "sk-...",
    provider: "gpt-4o-mini"
)
```

### Call AI for Content Enhancement

```swift
let response = try await AIManager.shared.callAI(
    prompt: "Improve this text",
    content: "Hello world"
)
print(response.content)
```

## Security Considerations

1. **API Key Storage**: API keys are stored in the database and should be encrypted at rest
2. **Request Security**: All API calls use HTTPS
3. **Error Messages**: Error messages should not expose sensitive information
4. **Rate Limiting**: Providers may have rate limits; handle 429 errors gracefully

## Performance Considerations

1. **Provider Caching**: AIManager caches provider configurations
2. **Connection Pooling**: Database connections are pooled via DatabaseConnectivityPool
3. **Timeout Handling**: API requests have appropriate timeouts
4. **Retry Logic**: Transient errors should be retried with exponential backoff
