-----------------
AI Connection Management
-----------------
## User Story ID: US-001
As a Pen user, I want to create AI connections by using the AIConnectionService, so that I can use AI connection from multiple providers.

### Acceptance Criteria ID: US-001-001
Scenario: Create local AI_CONNECTION and save to DB - success
Given: The app is running
AND the user has logged in
AND the AI_MODEL_PROVIDER objects are created
AND have providers' information loaded from the database
When: The user starts creating an AI_API_CONNECTION
AND the user has selected a provider
AND the user enters a valid API key
AND the user clicks the save button to save the new AI_CONNECTION
Then: The AI_CONNECTION service creates a new connection object
AND saves the connection object information to the database successfully
AND prints in terminal " $$$$$$$$$$$$$$$$$$$$ AI Connection " + provider + " saved! $$$$$$$$$$$$$$$$$$$$"
AND the new connection appears in the user's list of AI connections

### Acceptance Criteria ID: US-001-002
Scenario: Create local AI_CONNECTION and save to DB - failure
Given: The app is running
AND the user has logged in
AND the AI_MODEL_PROVIDER objects are created
AND have providers' information loaded from the database
When: The user starts creating an AI_API_CONNECTION
AND the user has selected a provider
AND the user clicks the save button to save the new AI_CONNECTION
AND the database connection fails
Then: The AI_CONNECTION service creates a new connection object
AND fails to save the connection object information to the database
AND prints in terminal " $$$$$$$$$$$$$$$$$$$$ Failed to save AI Connection " + provider + " !!!  $$$$$$$$$$$$$$$$$$$$"
AND displays an error message to the user

### Acceptance Criteria ID: US-001-003
Scenario: Create AI connection with invalid API key
Given: The app is running
AND the user has logged in
AND the AI_MODEL_PROVIDER objects are created
AND have providers' information loaded from the database
When: The user starts creating an AI_API_CONNECTION
AND the user has selected a provider
AND the user enters an invalid API key
AND the user clicks the save button
Then: The AI_CONNECTION service validates the API key
AND displays an error message to the user
AND does not save the connection to the database

## User Story ID: US-002
As a Pen user, I want to test AI connections, so that I can verify they work correctly before using them.

### Acceptance Criteria ID: US-002-001
Scenario: Test AI connection - success
Given: The app is running
AND the user has logged in
AND the user has at least one AI connection
When: The user selects an AI connection
AND the user clicks the test button
Then: The AI_CONNECTION service sends a test request to the provider
AND receives a valid response
AND prints in terminal " $$$$$$$$$$$$$$$$$$$$ AI Connection " + provider + " is established $$$$$$$$$$$$$$$$$$$$"
AND displays a success message to the user

### Acceptance Criteria ID: US-002-002
Scenario: Test AI connection - failure
Given: The app is running
AND the user has logged in
AND the user has at least one AI connection
When: The user selects an AI connection
AND the user clicks the test button
AND the connection fails
Then: The AI_CONNECTION service attempts to connect to the provider
AND receives an error response
AND prints in terminal " $$$$$$$$$$$$$$$$$$$$ AI Connection " + provider + " is failed $$$$$$$$$$$$$$$$$$$$"
AND displays an error message to the user

## User Story ID: US-003
As a Pen user, I want to list all my AI connections, so that I can manage them easily.

### Acceptance Criteria ID: US-003-001
Scenario: List all AI connections
Given: The app is running
AND the user has logged in
AND the user has multiple AI connections
When: The user navigates to the AI connections section
Then: The AI_CONNECTION service retrieves all connections for the user
AND displays them in a list
AND shows the provider name and API key (masked) for each connection

## User Story ID: US-004
As a Pen user, I want to update AI connections, so that I can change API keys or providers when needed.

### Acceptance Criteria ID: US-004-001
Scenario: Update AI connection - success
Given: The app is running
AND the user has logged in
AND the user has at least one AI connection
When: The user selects an AI connection to edit
AND the user updates the API key
AND the user clicks the save button
Then: The AI_CONNECTION service updates the connection in the database
AND prints in terminal " $$$$$$$$$$$$$$$$$$$$ AI Connection " + provider + " updated! $$$$$$$$$$$$$$$$$$$$"
AND displays a success message to the user

## User Story ID: US-005
As a Pen user, I want to delete AI connections, so that I can remove unused or invalid connections.

### Acceptance Criteria ID: US-005-001
Scenario: Delete AI connection - success
Given: The app is running
AND the user has logged in
AND the user has at least one AI connection
When: The user selects an AI connection to delete
AND the user confirms the deletion
Then: The AI_CONNECTION service deletes the connection from the database
AND prints in terminal " $$$$$$$$$$$$$$$$$$$$ AI Connection " + provider + " deleted! $$$$$$$$$$$$$$$$$$$$"
AND the connection is removed from the user's list

## User Story ID: US-006
As a Pen user, I want to use AI connections for different AI tasks, so that I can leverage different providers for different use cases.

### Acceptance Criteria ID: US-006-001
Scenario: Use AI connection for chat completion
Given: The app is running
AND the user has logged in
AND the user has at least one AI connection
When: The user selects an AI connection for chat
AND the user sends a chat request
Then: The AI_CONNECTION service uses the selected connection
AND sends the request to the provider
AND returns the response to the user

### Acceptance Criteria ID: US-006-002
Scenario: Use AI connection for embedding generation
Given: The app is running
AND the user has logged in
AND the user has at least one AI connection that supports embeddings
When: The user selects an AI connection for embeddings
AND the user requests an embedding
Then: The AI_CONNECTION service uses the selected connection
AND sends the request to the provider
AND returns the embedding to the user

## User Story ID: US-007
As a Pen user, I want to set a default AI connection, so that I don't have to select one every time.

### Acceptance Criteria ID: US-007-001
Scenario: Set default AI connection
Given: The app is running
AND the user has logged in
AND the user has multiple AI connections
When: The user selects an AI connection
AND the user sets it as default
Then: The AI_CONNECTION service saves the default connection preference
AND uses this connection by default for future requests
AND displays a confirmation message to the user

