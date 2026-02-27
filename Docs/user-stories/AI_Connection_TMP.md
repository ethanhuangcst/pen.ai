-----------------
Establish AI connection
-----------------
## User Story ID: US-001
As a Pen user, I want the system to have a back-end AI connection service, named as "AI_API_CONNECTION", so that all features will use one centralized way to communicate with AI

### Acceptance Criteria ID: US-001-001
Scenario: AI_API_CONNECTION service initialization
Given: The system is starting up
AND the user has logged in
AND the AI provider information is stored in the database
AND the database includes default model settings for each provider
When: The system initializes the AI_API_CONNECTION service
Then: The service should load the current user's API_Key from the database,
AND the current user's AI service providers from the database,
AND the default model for each provider from the database,
AND the other settings from the database
AND initialize connection pools for supported providers
AND be ready to handle connection requests

### Acceptance Criteria ID: US-001-002
Scenario: Provider connection success with primary URL
Given: The user has configured an AI provider
AND the provider's primary base URL is loaded from database
AND the provider's default model is loaded from database
AND the primary base URL is available
AND the user has provided a valid API key
When: The AI_API_CONNECTION service attempts to connect to the provider
Then: The service should use the primary base URL
AND specify the provider's default model in the connection request
AND establish connection successfully
AND not attempt to use alternative URLs
AND return a success status to the calling feature

### Acceptance Criteria ID: US-001-003
Scenario: Provider connection failure
Given: The user has configured an AI provider
AND the provider's base URL is loaded from database
AND the provider's default model is loaded from database
AND the base URL is unavailable
AND the alternative URLs are unavailable
OR the user has provided an invalid API key
When: The AI_API_CONNECTION service attempts to connect to the provider
Then: The service should attempt to use the provider's base URL
AND specify the provider's default model in the connection request
AND upon failure, display a connection error
AND suggest checking network connectivity or API key validity
AND return a failure status to the calling feature

### Acceptance Criteria ID: US-001-004
Scenario: Provider connection with failover to alternative URLs
Given: The user has configured an AI provider
AND the provider has multiple base URLs configured in priority order
AND the provider's default model is loaded from database
AND the primary base URL is unavailable
AND at least one alternative base URL is available
AND the user has provided a valid API key
When: The AI_API_CONNECTION service attempts to connect to the provider
Then: The service should first attempt to use the highest priority base URL
AND specify the provider's default model in the connection request
AND upon failure, automatically try the next priority base URL
AND continue until a connection is established or all URLs are exhausted
AND return a success status to the calling feature if connection is established

### Acceptance Criteria ID: US-001-005
Scenario: Provider connection failure with all URLs
Given: The user has configured an AI provider
AND the provider has multiple base URLs configured
AND the provider's default model is loaded from database
AND all configured base URLs are unavailable
OR the user has provided an invalid API key
When: The AI_API_CONNECTION service attempts to connect to the provider
Then: The service should attempt all configured base URLs in priority order
AND specify the provider's default model in each connection request
AND upon failure of all URLs, display a connection error
AND suggest checking network connectivity or API key validity
AND return a failure status to the calling feature

## User Story ID: US-002
As a Pen user, I want the AI_API_CONNECTION service to automatically fail over to alternative base URLs for providers that have multiple URLs configured, so that I can maintain connection even if some endpoints are unavailable

### Acceptance Criteria ID: US-002-001
Scenario: Provider connection with primary URL
Given: The user has configured an AI provider
AND the provider's primary base URL is loaded from database
AND the provider's default model is loaded from database
AND the primary base URL is available
AND the user has provided a valid API key
When: The AI_API_CONNECTION service attempts to connect to the provider
Then: The service should use the primary base URL
AND specify the provider's default model in the connection request
AND establish connection successfully
AND not attempt to use alternative URLs

### Acceptance Criteria ID: US-002-002
Scenario: Provider connection with failover to next priority URL
Given: The user has configured an AI provider
AND the provider has multiple base URLs configured in priority order
AND the provider's default model is loaded from database
AND the highest priority base URL is unavailable
AND the next priority base URL is available
AND the user has provided a valid API key
When: The AI_API_CONNECTION service attempts to connect to the provider
Then: The service should first attempt to use the highest priority base URL
AND specify the provider's default model in the connection request
AND upon failure, automatically try the next priority base URL
AND establish connection successfully

### Acceptance Criteria ID: US-002-003
Scenario: Provider connection failure with all URLs
Given: The user has configured an AI provider
AND the provider has multiple base URLs configured
AND the provider's default model is loaded from database
AND all configured base URLs are unavailable
OR the user has provided an invalid API key
When: The AI_API_CONNECTION service attempts to connect to the provider
Then: The service should attempt all configured base URLs in priority order
AND specify the provider's default model in each connection request
AND upon failure of all URLs, display a connection error
AND suggest checking network connectivity or API key validity

## User Story ID: US-003
As a Pen developer, I want AI provider information to be stored in the database, so that I can easily manage and update connection parameters

### Acceptance Criteria ID: US-003-001
Scenario: Load AI provider configuration from database
Given: The system is initialized
AND the AI provider information is stored in the database
AND the database includes default model settings for each provider
When: The AI_API_CONNECTION service loads AI connection settings
Then: The service should read the provider information from the database
AND use the defined base URLs for each provider
AND use the defined default model for each provider
AND apply any other provider-specific settings

### Acceptance Criteria ID: US-003-002
Scenario: Update AI provider configuration
Given: The system is running
AND the AI provider information in the database is updated with new settings
AND the updated configuration includes changes to default model settings
When: The AI_API_CONNECTION service reloads AI connection settings
Then: The service should use the updated configuration
AND apply the new base URLs and model settings
AND not require a restart
AND continue to handle connection requests without interruption

### Acceptance Criteria ID: US-003-003
Scenario: Provider configuration management
Given: The AI provider information is stored in the database
AND the database includes provider information with ID, name, base URLs, and default model
When: The system initializes
Then: The AI_API_CONNECTION service should load all provider configurations
AND the registration/settings page should load provider options from the database
AND the provider options should not be hardcoded
AND the default model for each provider should be loaded from the database

### Acceptance Criteria ID: US-003-004
Scenario: Add new provider to database
Given: The database is updated with a new provider
AND the new provider includes ID, name, base URLs, and default model
When: The system reloads configuration
Then: The AI_API_CONNECTION service should recognize the new provider
AND load the new provider's default model from the database
AND the registration/settings page should display the new provider as an option
AND the service should be able to connect to the new provider using the specified model

### Acceptance Criteria ID: US-003-005
Scenario: Provider with multiple base URLs configuration
Given: The database includes a provider with multiple base URLs in priority order
AND the provider has a default model specified in the database
When: The system loads configuration
Then: The AI_API_CONNECTION service should load all base URLs for the provider
AND load the provider's default model from the database
AND use them in the configured priority order for failover
AND specify the provider's default model in all connection requests
AND the failover logic should be generic for all providers

## User Story ID: US-004
As a Pen user, I want to configure multiple AI connections per user, so that I can use different AI providers for different tasks

### Acceptance Criteria ID: US-004-001
Scenario: Add multiple AI connections for a user
Given: The user is logged in
AND the system supports multiple AI connections per user
AND the database has AI provider information
When: The user adds multiple AI connections
Then: The system should store all AI connections for the user in the database
AND the user should be able to select between different connections
AND the AI_API_CONNECTION service should be able to use any of the user's connections

### Acceptance Criteria ID: US-004-002
Scenario: Switch between AI connections
Given: The user has multiple AI connections configured
AND the AI_API_CONNECTION service is initialized
When: The user switches to a different AI connection
Then: The AI_API_CONNECTION service should use the selected connection
AND all subsequent AI requests should use the new connection
AND the system should remember the user's selection

### Acceptance Criteria ID: US-004-003
Scenario: Delete an AI connection
Given: The user has multiple AI connections configured
AND the user wants to remove one of the connections
When: The user deletes an AI connection
Then: The system should remove the connection from the database
AND the AI_API_CONNECTION service should no longer use that connection
AND the user should no longer see that connection in their list

## User Story ID: US-005
As a Pen user, I want the AI_API_CONNECTION service to perform a test call after establishing connection, so that I can verify the AI model is functioning properly

### Acceptance Criteria ID: US-005-001
Scenario: Successful test call after connection
Given: The AI_API_CONNECTION service has successfully established connection to an AI provider
AND the service has a test prompt defined
AND the provider's default model is loaded from database
When: The service performs a test call
Then: The service should send a test prompt to the AI model using the provider's default model
AND receive a valid response
AND display the test result as "PASS"
AND show the response content
AND return the test result to the calling feature

### Acceptance Criteria ID: US-005-002
Scenario: Failed test call after connection
Given: The AI_API_CONNECTION service has established connection to an AI provider
AND the provider's default model is loaded from database
AND the AI model returns an error for the test prompt
When: The service performs a test call
Then: The service should send a test prompt to the AI model using the provider's default model
AND receive an error response
AND display the test result as "FAIL"
AND show the error message
AND return the test result to the calling feature

### Acceptance Criteria ID: US-005-003
Scenario: Test call timeout
Given: The AI_API_CONNECTION service has established connection to an AI provider
AND the provider's default model is loaded from database
AND the AI model takes longer than the timeout to respond
When: The service performs a test call
Then: The service should send a test prompt to the AI model using the provider's default model
AND wait for the configured timeout period
AND upon timeout, display the test result as "FAIL"
AND show a timeout error message
AND return the test result to the calling feature

## User Story ID: US-006
As a Pen developer, I want all features to use the centralized AI_API_CONNECTION service, so that I can maintain consistent connection management across the application

### Acceptance Criteria ID: US-006-001
Scenario: Feature uses AI_API_CONNECTION service
Given: The AI_API_CONNECTION service is initialized and ready
AND a feature needs to connect to an AI provider
AND the provider's default model is loaded from database
When: The feature calls the AI_API_CONNECTION service
Then: The service should handle the connection request
AND specify the provider's default model in the connection request
AND return the connection status to the feature
AND log the connection attempt for debugging

### Acceptance Criteria ID: US-006-002
Scenario: Multiple features use AI_API_CONNECTION service concurrently
Given: The AI_API_CONNECTION service is initialized and ready
AND multiple features need to connect to AI providers simultaneously
AND each provider's default model is loaded from database
When: The features call the AI_API_CONNECTION service concurrently
Then: The service should handle all connection requests
AND specify each provider's default model in their respective connection requests
AND maintain separate connections for each feature
AND not block other features during connection attempts

### Acceptance Criteria ID: US-006-003
Scenario: AI_API_CONNECTION service error handling
Given: The AI_API_CONNECTION service encounters an unexpected error
When: A feature calls the service
Then: The service should catch the error
AND return a meaningful error message to the feature
AND log the error for debugging
AND continue to handle other connection requests