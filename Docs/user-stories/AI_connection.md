# AI Connection Management

## User Stories

### US1: Create AI Connection Service
As a developer,
I want to create an AIConnectionService similar to the Database service,
So that I can manage AI connections efficiently.

### US2: Define AI Provider Model
As a developer,
I want to define an AI_PROVIDER model based on the wingman_db.ai_providers table structure,
So that I can work with AI providers in the application.

### US3: Define AI Connection Model
As a developer,
I want to define an AI_CONNECTION model based on the wingman_db.ai_connections table structure,
So that I can work with AI connections in the application.

### US4: Create AI Connection Test Method
As a developer,
I want to create an AIConnectionTest method to make actual API calls,
So that I can verify AI connections work correctly.

### US5: Load Supported AI Providers
As a user,
I want to load supported AI Model providers from wingman_db.ai_providers,
So that I can create connections to different AI services.

### US6: View Existing AI Connections
As a user,
I want to view all my existing AI connections,
So that I can manage them effectively.

### US7: Add Multiple AI Connections
As a user,
I want to add multiple AI connections by entering API keys and selecting providers,
So that I can use different AI services for different tasks.

### US8: Test AI Connections
As a user,
I want to test my AI connections to ensure they work properly,
So that I can be confident they'll function when needed.

## Acceptance Criteria

### AC1: AIConnectionService Creation
- [ ] AIConnectionService is created with methods for CRUD operations on AI connections
- [ ] Service follows the same pattern as other system services like Database service
- [ ] Service handles database operations for AI connections

### AC2: AI Provider Model Definition
- [ ] AI_PROVIDER model is defined with fields matching the wingman_db.ai_providers table
- [ ] Model includes fields: id, name, base_urls (JSON), default_model, requires_auth, auth_header, created_at, updated_at
- [ ] Model has methods to convert between database rows and model instances

### AC3: AI Connection Model Definition
- [ ] AI_CONNECTION model is defined with fields matching the wingman_db.ai_connections table
- [ ] Model includes fields: id, user_id, apiKey, apiProvider, created_at, updated_at
- [ ] Model has methods to convert between database rows and model instances

### AC4: AI Connection Test Method
- [ ] AIConnectionTest method is created to make actual API calls
- [ ] Method connects to the AI API and performs a test call
- [ ] Method returns the result of the test call

### AC5: Load Supported AI Providers
- [ ] Application loads AI providers from the wingman_db.ai_providers table
- [ ] Providers are available for selection when creating AI connections
- [ ] No UI is provided for viewing or editing providers (system setting)

### AC6: View Existing AI Connections
- [ ] Application loads all existing AI connections for the current user
- [ ] Connections are displayed in a list
- [ ] Each connection item includes:
      - Text field for API key (pre-filled, editable)
      - Drop-down list for Model Provider (pre-filled, changeable)
      - Delete button
      - Test button

### AC7: Add Multiple AI Connections
- [ ] Add button is displayed under the connections list
- [ ] Pressing Add button adds a new blank row to the list
- [ ] New row has empty API key field
- [ ] New row has pre-filled drop-down list for providers

### AC8: Test AI Connections
- [ ] Test button is present for each connection
- [ ] Pressing Test button connects to the AI API and performs a real test call
- [ ] Pop-up message shows the result of the test
- [ ] Result indicates success or failure with appropriate message

## Technical Implementation Details

### Database Tables

#### ai_providers
| Column | Type | Description |
|--------|------|-------------|
| id | int | Primary key |
| name | varchar(191) | Provider name |
| base_urls | json | JSON array of base URLs |
| default_model | varchar(191) | Default model for provider |
| requires_auth | tinyint(1) | Whether authentication is required |
| auth_header | varchar(191) | Authentication header name |
| created_at | datetime(3) | Creation timestamp |
| updated_at | datetime(3) | Update timestamp |

#### ai_connections
| Column | Type | Description |
|--------|------|-------------|
| id | int | Primary key |
| user_id | int | Foreign key to users table |
| apiKey | varchar(191) | API key for the connection |
| apiProvider | varchar(191) | Provider name |
| created_at | datetime(3) | Creation timestamp |
| updated_at | datetime(3) | Update timestamp |

### Model Definitions

#### AI_PROVIDER
```swift
class AIModelProvider {
    let id: Int
    let name: String
    let baseURLs: [String]
    let defaultModel: String
    let requiresAuth: Bool
    let authHeader: String
    
    init(id: Int, name: String, baseURLs: [String], defaultModel: String, requiresAuth: Bool, authHeader: String) {
        self.id = id
        self.name = name
        self.baseURLs = baseURLs
        self.defaultModel = defaultModel
        self.requiresAuth = requiresAuth
        self.authHeader = authHeader
    }
    
    // Methods to convert between database rows and model instances
}
```

#### AI_CONNECTION
```swift
class AIConnection {
    let id: Int
    let userId: Int
    let apiKey: String
    let apiProvider: String
    
    init(id: Int, userId: Int, apiKey: String, apiProvider: String) {
        self.id = id
        self.userId = userId
        self.apiKey = apiKey
        self.apiProvider = apiProvider
    }
    
    // Methods to convert between database rows and model instances
}
```

### Service Methods

#### AIConnectionService
```swift
class AIConnectionService {
    static let shared = AIConnectionService()
    
    // CRUD operations
    func getAllConnections(for userId: Int) -> [AIConnection]
    func getConnection(id: Int) -> AIConnection?
    func createConnection(userId: Int, apiKey: String, apiProvider: String) -> AIConnection
    func updateConnection(id: Int, apiKey: String, apiProvider: String) -> AIConnection
    func deleteConnection(id: Int) -> Bool
    
    // Provider operations
    func getAllProviders() -> [AIModelProvider]
    
    // Test operation
    func testConnection(connection: AIConnection) -> Bool
}
```

### UI Components

#### AI Connections List
- Table view with rows for each connection
- Each row contains:
  - API key text field
  - Provider drop-down menu
  - Test button
  - Delete button
- Add button at the bottom

#### Test Result Popup
- Shows success/failure message
- Includes details about the test result
- Ok button to dismiss