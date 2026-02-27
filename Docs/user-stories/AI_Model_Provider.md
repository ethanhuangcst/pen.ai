# AI Connection Management

## User Story: AI Provider Management

### Title
User can use the AI providers currently supported so that they can create their own AI connections

### Description
As a Pen User,
I want to load supported AI Model providers from database, so that I can use them to manage my AI Connections

### Acceptance Criteria (Gherkin Format)

#### Scenario 1: Create AI_PROVIDER Model
Given the app is running
When the other components need to read the AI_MODEL_PROVIDERS the app currently supports
Then a database query will be executed from the wingman_db.ai_providers table
Then all records from the table should be loaded from database
And one AI_PROVIDER model will be creatd for each records
And the system should handle empty or non-existent tables gracefully
And no UI components should be available for viewing or editing AI providers

#### Scenario 2: Performance
Given the system is initializing
When the system loads AI providers
Then the loading process should complete efficiently without impacting startup time
And the loaded providers should be cached in memory for quick access

#### Scenario 3: Error Handling
Given the system is loading AI providers
When a database connection error occurs
Then appropriate error messages should be logged
And the system should continue to operate with default providers

### Technical Requirements
1. **Database Schema**
   - The `wingman_db.ai_providers` table must have the following fields:
     - `id` (int, primary key, auto_increment)
     - `name` (varchar(191), provider name)
     - `base_urls` (json, API endpoint URLs)
     - `default_model` (varchar(191), default model for the provider)
     - `requires_auth` (tinyint(1), whether authentication is required)
     - `auth_header` (varchar(191), authentication header name)
     - `created_at` (datetime(3), timestamp)
     - `updated_at` (datetime(3), timestamp)

2. **Model Implementation**
   - The `AI_PROVIDER` model must be implemented in the models directory
   - It must include methods for loading from database and validating provider data
   - The model should map to the actual database schema with fields for id, name, base_urls, default_model, requires_auth, auth_header, created_at, and updated_at

3. **Integration Points**
   - The provider loading must be integrated into the system initialization process
   - The AI connection creation process must use the loaded providers

### Notes
- This is a system-level feature and does not require any user-facing UI
- The AI providers are meant to be managed through database operations, not through the application UI
- The system should support at least the following AI providers initially: OpenAI, Anthropic, Google AI, and Azure OpenAI