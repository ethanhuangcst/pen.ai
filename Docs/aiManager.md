# AIManager Design Document

## Overview

The AIManager class is designed to centralize the management of AI interactions in the Pen AI application. It follows a singleton pattern and provides a unified interface for interacting with various AI providers (OpenAI, DeepSeek, Baichuan, Qwen, etc.).

## Architecture

```
App
 └── AIManager (Singleton)
        ├── Provider Configuration
        ├── Request Builder
        ├── Transport Layer
        ├── Response Parser
        ├── Error Mapper
        └── Conversation Store (optional)
```

## Core Components

### 1. Provider Strategy Protocol

```swift
protocol AIProviderStrategy {
    func buildChatPayload(messages: [AIMessage]) -> [String: Any]
    func parseChatResponse(data: Data) throws -> AIResponse
    var chatEndpoint: String { get }
    var embeddingEndpoint: String { get }
    var imageEndpoint: String { get }
}
```

### 2. Integration with Existing Classes

We'll leverage the existing `AIModelProvider` class instead of creating a new configuration structure. The `AIModelProvider` class already contains all the provider-specific details we need.

```swift
class GenericProviderStrategy: AIProviderStrategy {
    private let provider: AIModelProvider
    
    init(provider: AIModelProvider) {
        self.provider = provider
    }
    
    func buildChatPayload(messages: [AIMessage]) -> [String: Any] {
        return [
            "model": provider.defaultModel,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": 0.7
        ]
    }
    
    func parseChatResponse(data: Data) throws -> AIResponse {
        // Parse response based on provider type
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let id = json?["id"] as? String,
              let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String,
              let model = json?["model"] as? String else {
            throw AIError.invalidResponse
        }
        
        return AIResponse(
            id: id,
            content: content,
            model: model,
            usage: nil
        )
    }
    
    var chatEndpoint: String {
        // Get the first completion endpoint from baseURLs
        return provider.baseURLs.first { $0.key.contains("completion") }?.value ?? ""
    }
    
    var embeddingEndpoint: String {
        return provider.baseURLs["embedding"] ?? ""
    }
    
    var imageEndpoint: String {
        return provider.baseURLs["image"] ?? ""
    }
}
```

### 3. Provider Factory

```swift
enum AIProvider {
    case named(String) // Use provider name to load from database
    case custom(AIModelProvider) // Use a custom AIModelProvider instance
}

class ProviderFactory {
    static func make(_ provider: AIProvider) -> AIProviderStrategy {
        switch provider {
        case .named(let name):
            return makeStrategyForProvider(named: name)
        case .custom(let modelProvider):
            return GenericProviderStrategy(provider: modelProvider)
        }
    }
    
    private static func makeStrategyForProvider(named name: String) -> AIProviderStrategy {
        // Use AIConnectionService to load the provider from database
        let databasePool = DatabaseConnectivityPool.shared
        let service = AIConnectionService(databasePool: databasePool)
        
        // Load provider synchronously (blocking)
        var provider: AIModelProvider? = nil
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            do {
                provider = try await service.loadProviderByName(name)
            } catch {
                print("Error loading provider name): \(error)")
                // Create a default provider if loading fails
                provider = createDefaultProvider(for: name)
            } finally {
                semaphore.signal()
            }
        }
        
        semaphore.wait()
        
        guard let modelProvider = provider else {
            // Fallback to OpenAI if no provider found
            let defaultProvider = createDefaultProvider(for: "OpenAI")
            return GenericProviderStrategy(provider: defaultProvider)
        }
        
        return GenericProviderStrategy(provider: modelProvider)
    }
    
    private static func createDefaultProvider(for name: String) -> AIModelProvider {
        // Create a default provider based on name
        let now = Date()
        var baseURLs: [String: String] = [:]
        var defaultModel: String = ""
        
        switch name.lowercased() {
        case "openai", "gpt-4o-mini":
            baseURLs = [
                "completion": "https://api.openai.com/v1/chat/completions",
                "embedding": "https://api.openai.com/v1/embeddings",
                "image": "https://api.openai.com/v1/images/generations"
            ]
            defaultModel = "gpt-4o-mini"
        case "deepseek", "deepseek3.2":
            baseURLs = ["completion": "https://api.deepseek.com/v1/chat/completions"]
            defaultModel = "deepseek-ai/deepseek-v1.5"
        case "baichuan":
            baseURLs = ["completion": "https://api.baichuan-ai.com/v1/chat/completions"]
            defaultModel = "Baichuan2-13B-Chat"
        case "qwen", "qwen-plus":
            baseURLs = ["completion": "https://api.baichuan-ai.com/v1/chat/completions"]
            defaultModel = "Qwen2.5-72B-Instruct"
        default:
            baseURLs = ["completion": "https://api.openai.com/v1/chat/completions"]
            defaultModel = "gpt-4o-mini"
        }
        
        return AIModelProvider(
            id: Int(Date.timeIntervalSinceReferenceDate * 1000),
            name: name,
            baseURLs: baseURLs,
            defaultModel: defaultModel,
            requiresAuth: true,
            authHeader: "Authorization",
            createdAt: now,
            updatedAt: now
        )
    }
}
```

### 4. Data Models

```swift
struct AIMessage {
    let role: String // "user", "assistant", "system"
    let content: String
}

struct AIResponse {
    let id: String
    let content: String
    let model: String
    let usage: AIUsage?
}

struct AIUsage {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
}
```

### 5. Error Handling

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

## AIManager Class Design

```swift
final class AIManager {
    static let shared = AIManager()
    
    private var strategy: AIProviderStrategy?
    private var aiConfiguration: AIConfiguration?
    private var provider: AIProvider?
    
    private init() {}
    
    // Configuration Methods
    func configure(with configuration: AIConfiguration) {
        self.aiConfiguration = configuration
        self.provider = .named(configuration.apiProvider)
        self.strategy = ProviderFactory.make(self.provider!)
    }
    
    func configure(providerName: String, apiKey: String, userId: Int) {
        // Create a new AIConfiguration
        let configuration = AIConfiguration(
            id: 0, // Temporary ID
            userId: userId,
            apiKey: apiKey,
            apiProvider: providerName,
            createdAt: Date(),
            updatedAt: nil
        )
        configure(with: configuration)
    }
    
    // Add a custom provider
    func addCustomProvider(provider: AIModelProvider, apiKey: String, userId: Int) {
        self.provider = .custom(provider)
        self.strategy = ProviderFactory.make(self.provider!)
        
        // Create a new AIConfiguration
        let configuration = AIConfiguration(
            id: 0, // Temporary ID
            userId: userId,
            apiKey: apiKey,
            apiProvider: provider.name,
            createdAt: Date(),
            updatedAt: nil
        )
        self.aiConfiguration = configuration
    }
    
    func switchProvider(providerName: String) {
        self.provider = .named(providerName)
        self.strategy = ProviderFactory.make(self.provider!)
        
        // Update the provider name in the existing configuration
        if var configuration = aiConfiguration {
            configuration.apiProvider = providerName
            self.aiConfiguration = configuration
        }
    }
    
    func clearConfiguration() {
        self.provider = nil
        self.strategy = nil
        self.aiConfiguration = nil
    }
    
    func validateConfiguration() -> Bool {
        return provider != nil && strategy != nil && aiConfiguration != nil
    }
    
    // Core Chat Method
    func sendChat(
        messages: [AIMessage],
        model: String? = nil,
        temperature: Double = 0.7,
        maxTokens: Int? = nil
    ) async throws -> AIResponse {
        guard let strategy = strategy, let apiKey = aiConfiguration?.apiKey else {
            throw AIError.configurationError("Provider not configured")
        }
        
        let payload = strategy.buildChatPayload(messages: messages)
        let data = try await performRequest(
            endpoint: strategy.chatEndpoint,
            body: payload
        )
        
        return try strategy.parseChatResponse(data: data)
    }
    
    // Streaming Version
    func sendChatStream(
        messages: [AIMessage],
        onToken: @escaping (String) -> Void
    ) async throws {
        // Implementation for streaming responses
    }
    
    // Embeddings
    func createEmbedding(
        input: String,
        model: String? = nil
    ) async throws -> [Double] {
        // Implementation for creating embeddings
    }
    
    // Image Generation
    func generateImage(
        prompt: String,
        size: String = "1024x1024"
    ) async throws -> URL {
        // Implementation for generating images
    }
    
    // Health Check
    func testProvider() async throws -> Bool {
        // Implementation for testing provider connectivity
        let testMessage = AIMessage(role: "user", content: "Hello, this is a test.")
        _ = try await sendChat(messages: [testMessage], maxTokens: 5)
        return true
    }
    
    // Get current configuration
    func getCurrentConfiguration() -> AIConfiguration? {
        return aiConfiguration
    }
    
    // Private Methods
    private func performRequest(
        endpoint: String,
        body: [String: Any]
    ) async throws -> Data {
        // Implementation for making HTTP requests
    }
    
    private func mapError(_ data: Data, response: HTTPURLResponse) -> AIError {
        // Implementation for mapping provider-specific errors
    }
}
```

## Conversation Management (Optional)

```swift
typealias ConversationID = String

class ConversationManager {
    private var conversations: [ConversationID: [AIMessage]] = [:]
    
    func createConversation() -> ConversationID {
        let id = UUID().uuidString
        conversations[id] = []
        return id
    }
    
    func appendMessage(to id: ConversationID, message: AIMessage) {
        conversations[id]?.append(message)
    }
    
    func getConversationMessages(id: ConversationID) -> [AIMessage] {
        return conversations[id] ?? []
    }
    
    func clearConversation(id: ConversationID) {
        conversations[id] = []
    }
}
```

## Implementation Details

### 1. Request Building

Each provider has its own payload structure. The strategy pattern handles this by having each provider implementation build the appropriate payload.

### 2. Response Parsing

Similarly, each provider returns responses in different formats. The strategy pattern handles parsing into the unified AIResponse structure.

### 3. Error Handling

The `mapError` method normalizes provider-specific errors into the AIError enum, providing a consistent error handling experience for the app.

### 4. Retry Logic

The `performRequest` method should include retry logic for transient errors like network issues or rate limiting.

### 5. Security

API keys should be stored securely, preferably using the Keychain or a similar secure storage mechanism.

## Usage Example

```swift
// Example 1: Configure with an existing AIConfiguration
// Assuming you have an AIConfiguration object from the database
let userConfiguration: AIConfiguration = // Load from database
AIManager.shared.configure(with: userConfiguration)

// Example 2: Configure with provider name and API key
AIManager.shared.configure(
    providerName: "gpt-4o-mini",
    apiKey: "sk-YourAPIKeyHere",
    userId: 1
)

// Test the provider
Task {
    do {
        let success = try await AIManager.shared.testProvider()
        print("Provider test: \(success ? "Passed" : "Failed")")
    } catch {
        print("Error testing provider: \(error)")
    }
}

// Send a chat message
Task {
    do {
        let messages = [
            AIMessage(role: "user", content: "Hello, how are you?")
        ]
        let response = try await AIManager.shared.sendChat(messages: messages)
        print("AI Response: \(response.content)")
    } catch {
        print("Error sending chat: \(error)")
    }
}

// Example: Adding a custom provider
let customProvider = AIModelProvider(
    id: 999,
    name: "CustomProvider",
    baseURLs: [
        "completion": "https://api.customprovider.com/v1/chat/completions",
        "embedding": "https://api.customprovider.com/v1/embeddings",
        "image": "https://api.customprovider.com/v1/images/generations"
    ],
    defaultModel: "custom-model-1.0",
    requiresAuth: true,
    authHeader: "Authorization",
    createdAt: Date(),
    updatedAt: Date()
)

// Add the custom provider
AIManager.shared.addCustomProvider(
    provider: customProvider,
    apiKey: "your-custom-api-key",
    userId: 1
)

// Switch between providers
AIManager.shared.switchProvider(providerName: "deepseek3.2")

// Get current configuration
if let currentConfig = AIManager.shared.getCurrentConfiguration() {
    print("Current provider: \(currentConfig.apiProvider)")
}
```

## Benefits of This Design

1. **Integration with Existing Code**: Leverages the existing `AIConfiguration` and `AIModelProvider` classes, avoiding duplication
2. **Scalability**: Easy to add new AI providers by adding them to the database or creating custom `AIModelProvider` instances
3. **Maintainability**: Clear separation of concerns with the strategy pattern
4. **Flexibility**: Can easily switch between providers at runtime, including custom providers
5. **Consistency**: Unified interface for all AI interactions regardless of provider
6. **Error Handling**: Consistent error mapping across providers
7. **Extensibility**: Easy to add new features like streaming or additional endpoints
8. **Database Integration**: Provider details are loaded from the database, making it easy to manage providers centrally
9. **Backward Compatibility**: Works with existing `AIConfiguration` objects from the database

## Testing Strategy

1. **Unit Tests**: Test individual methods of the AIManager
2. **Integration Tests**: Test end-to-end interactions with each provider
3. **Mock Tests**: Use mock providers for testing without making actual API calls
4. **Error Tests**: Test error handling for various scenarios

## Conclusion

The AIManager class provides a clean, scalable, and maintainable way to manage AI interactions in the Pen AI application. By using the strategy pattern and a singleton design, it centralizes configuration, request building, and response parsing, while providing a unified interface for all AI providers.