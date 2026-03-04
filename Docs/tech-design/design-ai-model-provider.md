# AI Model Provider Data Model

## Overview
This document defines the data model structure for AI providers in the Pen AI application. The model maps to the `wingman_db.ai_providers` table and provides a structured way to represent AI service providers.

## Data Model Structure

### AI_PROVIDER Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | `Int` | Unique identifier for the provider (primary key) |
| `name` | `String` | Name of the AI provider (e.g., "OpenAI", "Anthropic") |
| `base_urls` | `JSON` | JSON object containing API endpoint URLs for different services |
| `default_model` | `String` | Default model to use for this provider |
| `requires_auth` | `Bool` | Whether the provider requires authentication |
| `auth_header` | `String` | Name of the authentication header (e.g., "Authorization") |
| `created_at` | `Date` | Timestamp when the provider was created |
| `updated_at` | `Date` | Timestamp when the provider was last updated |

### JSON Structure for `base_urls`

```json
{
  "completion": "https://api.provider.com/v1/chat/completions",
  "embedding": "https://api.provider.com/v1/embeddings",
  "moderation": "https://api.provider.com/v1/moderations"
}
```

## Model Implementation

### Swift Implementation

```swift
struct AIProvider: Codable {
    let id: Int
    let name: String
    let baseUrls: [String: String] // Maps to base_urls JSON
    let defaultModel: String
    let requiresAuth: Bool
    let authHeader: String
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case baseUrls = "base_urls"
        case defaultModel = "default_model"
        case requiresAuth = "requires_auth"
        case authHeader = "auth_header"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Methods for loading from database
    static func loadAll(from database: Database) throws -> [AIProvider] {
        // Implementation for loading all providers from database
    }
    
    static func loadById(from database: Database, id: Int) throws -> AIProvider? {
        // Implementation for loading a single provider by ID
    }
    
    // Validation method
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.missingName
        }
        
        guard !baseUrls.isEmpty else {
            throw ValidationError.missingBaseUrls
        }
        
        guard !defaultModel.isEmpty else {
            throw ValidationError.missingDefaultModel
        }
    }
}

enum ValidationError: Error {
    case missingName
    case missingBaseUrls
    case missingDefaultModel
}
```

### TypeScript Implementation (Backend)

```typescript
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('ai_providers')
export class AIProvider {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'varchar', length: 191, nullable: false })
  name: string;

  @Column({ type: 'json', nullable: false })
  base_urls: Record<string, string>;

  @Column({ type: 'varchar', length: 191, nullable: false })
  default_model: string;

  @Column({ type: 'tinyint', default: 1 })
  requires_auth: boolean;

  @Column({ type: 'varchar', length: 191, nullable: false })
  auth_header: string;

  @CreateDateColumn({ type: 'datetime', precision: 3 })
  created_at: Date;

  @UpdateDateColumn({ type: 'datetime', precision: 3, nullable: true })
  updated_at: Date | null;

  // Validation method
  validate(): void {
    if (!this.name) {
      throw new Error('Provider name is required');
    }
    
    if (!this.base_urls || Object.keys(this.base_urls).length === 0) {
      throw new Error('Base URLs are required');
    }
    
    if (!this.default_model) {
      throw new Error('Default model is required');
    }
  }
}
```

## Usage

### Loading Providers

```swift
// Load all providers
let providers = try AIProvider.loadAll(from: database)

// Load a specific provider
if let openAI = try AIProvider.loadById(from: database, id: 1) {
    print("Loaded provider: \(openAI.name)")
}
```

### Using Providers for AI Connections

```swift
// Create a new AI connection using a provider
let connection = AIConnection(
    userId: currentUser.id,
    apiKey: "sk-...",
    apiProvider: openAI.name
)
```

## Default Providers

The system should include the following default providers:

1. **OpenAI**
   - Name: "OpenAI"
   - Base URLs: `{ "completion": "https://api.openai.com/v1/chat/completions" }`
   - Default Model: "gpt-4"
   - Requires Auth: true
   - Auth Header: "Authorization"

2. **Anthropic**
   - Name: "Anthropic"
   - Base URLs: `{ "completion": "https://api.anthropic.com/v1/messages" }`
   - Default Model: "claude-3-opus-20240229"
   - Requires Auth: true
   - Auth Header: "x-api-key"

3. **Google AI**
   - Name: "Google AI"
   - Base URLs: `{ "completion": "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent" }`
   - Default Model: "gemini-pro"
   - Requires Auth: true
   - Auth Header: "x-goog-api-key"

4. **Azure OpenAI**
   - Name: "Azure OpenAI"
   - Base URLs: `{ "completion": "https://{your-resource-name}.openai.azure.com/openai/deployments/{deployment-id}/chat/completions?api-version=2024-02-01" }`
   - Default Model: "gpt-4"
   - Requires Auth: true
   - Auth Header: "api-key"

## Security Considerations

- Provider information should be loaded securely from the database
- API keys for connections should not be stored in the provider model
- The provider model should only contain configuration information, not sensitive credentials
- Database queries for providers should be optimized to minimize performance impact