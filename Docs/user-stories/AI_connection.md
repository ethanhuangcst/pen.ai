-----------------
AI Connection Management
-----------------

//DONE
## User Story ID: US-001
As a Pen user, I want to list all my AI connections, so that I can manage them easily.
//DONE
### Acceptance Criteria ID: US-001-001
Scenario: List all AI connections
Given: The app is running
AND the user has logged in
AND the user has multiple AI connections
When: The user navigates to the AI connections section
Then: The AI_CONNECTION service retrieves all connections for the user
AND displays them in a list
- Column 1: Provider Name, dropdown menu, loaded from AI_MODEL_PROVIDER objects
- Column 2: API Key (prefilled with existing key if any), text field, editable
- Column 3: Delete button, to delete the connection from database and remove from the list
- Column 4: Save button, to test & save the AI connection to the database
AND the Save button will be disabled unless the API key or provider is changed
AND supports scrolling to view all connections if there are more than fit on the screen

//DONE
## User Story ID: US-002
As a Pen user, I want to add a new AI connection to the list, so that I can enter the provider and API key for the connection and save it to the database.
//DONE
### Acceptance Criteria ID: US-002-001
Scenario: Create a new AI connection row to the list
Given: The app is running
AND the user has logged in
AND the user opened Preferences window, AI Connection tab
When: The user clicks the New button to create a new AI connection
Then: A new row is added to the list with default provider "OpenAI" and empty API Key field
AND the Save button is disabled until the user enters a API key or changes the provider

//DONE
### Acceptance Criteria ID: US-002-002
Scenario: Save button disabled when API key is empty
Given: The app is running
AND the user has logged in
AND the user opened Preferences window, AI Connection tab
AND there are at least one existing AI connection row in the list
When: the API Key field of the new row is empty
Then: the Save button is disabled

//DONE
### Acceptance Criteria ID: US-002-003
Scenario: Save button enabled when API key is not empty
Given: The app is running
AND the user has logged in
AND the user opened Preferences window, AI Connection tab
AND there are at least one existing AI connection row in the list
When: the API Key field of the new row is not empty
Then: the Save button is enabled    

//DONE
## User Story ID: US-003
As a Pen user, I want to delete AI connections, so that I can remove unused or invalid connections.
//DONE
### Acceptance Criteria ID: US-003-001
Scenario: Delete AI connection - success
Given: The app is running
AND the user has logged in
AND the user has at least one AI connection
When: The user clicks the delete button next to the AI connection
AND the user confirms the deletion from a popup dialog
Then: The AI_CONNECTION will be deleted from the list and from the database
AND print in terminal "$$$$$$$$$$$$$$$$$$$$ AI Configuration " + provider + " deleted! $$$$$$$$$$$$$$$$$$$$"




## User Story ID: US-004
As a Pen user, I want to test & save AI connections, so that I have working AI connections to use.

//DONE
### Acceptance Criteria ID: US-004-001
Scenario: Test & Save AI connection from list row- duplicated information
Given: The app is running
AND the user has logged in
AND the user has at least one AI connection displayed in the list, regardless if they are from the database or manually added
AND the current row of the AI connection has the same provider and API key as other rows in the list
When: The clicks the Save button next to the current row of the AI connection
Then: The API Key field of all rows with the same provider and API key as the current row will be highlighted in red for 2 seconds
AND displays a popup message "Duplicated API Key or Provider, AI Connection configuration not saved. " + new line + "Please check the API Key and Provider." 

//DONE
### Acceptance Criteria ID: US-004-002
Scenario: Test & Save AI connection from list row - not duplicated information
Given: The app is running
AND the user has logged in
AND the user has at least one AI connection displayed in the list, regardless if they are from the database or manually added
AND the current row of the AI connection does not have same provider and API key as other rows in the list
When: The clicks the test button next to the AI connection
Then: call AIManager.testConnection()
AND Display a pop up message "Testing " + provider + " beforing saving the configuration..."
AND return the result of the test

//WIP
### Acceptance Criteria ID: US-004-003
Scenario: Test AI connection - success with existing connection
Given: The app is running
AND the user has logged in
AND the user has at least one AI connection displayed in the list, regardless if they are from the database or manually added
AND the user clicks the test button next to an existing AI connection loaded from the database
AND AIManager.testConnection() is called
When: the test returns sucess
Then: update the AI connection for this user in the database, with the current API key and provider
AND prints in terminal " $$$$$$$$$$$$$$$$$$$$ AI Connection " + provider + " is updated $$$$$$$$$$$$$$$$$$$$"
AND highlight the API key of this AI connection in the list in red for 2 seconds
AND the other rows in the list should still be displayed
AND wait until previous popup message is dismissed
AND display a pop up message "AI Connection test passed!" + new line + "AI Connection configuration " + provider + " updated for " + user.username

//WIP
### Acceptance Criteria ID: US-004-004
Scenario: Test AI connection - failed with existing connection
Given: The app is running
AND the user has logged in
AND the user has at least one AI connection displayed in the list, regardless if they are from the database or manually added
AND the user clicks the test button next to an existing AI connection loaded from the database
AND AIManager.testConnection() is called
When: the test returns failure
Then: prints in terminal " $$$$$$$$$$$$$$$$$$$$ AI Connection test failed $$$$$$$$$$$$$$$$$$$$"
AND highlight the API key of this AI connection in the list in red for 2 seconds
AND the other rows in the list should still be displayed
AND wait until previous popup message is dismissed
AND display a pop up message "AI Connection test failed!" + new line + "AI Connection configuration " + provider + " not updated for " + user.username + ". " + new line + "Please check your configuration and try again."

//WIP
### Acceptance Criteria ID: US-004-004
Scenario: Test AI connection - success with new connection
Given: The app is running
AND the user has logged in
AND the user has at least one AI connection displayed in the list, regardless if they are from the database or manually added
AND the user clicks the test button next to a new AI connection manually added
AND AIManager.testConnection() is called
When: the test returns sucess
Then: create a new AI connection for this user in the database, with the current API key and provider
AND prints in terminal " $$$$$$$$$$$$$$$$$$$$ AI Connection " + provider + " is added $$$$$$$$$$$$$$$$$$$$"
AND highlight the API key of this AI connection in the list in red for 2 seconds
AND the other rows in the list should still be displayed
AND wait until previous popup message is dismissed
AND display a pop up message "AI Connection test passed!" + new line + " "New AI Connection " + provider + " created for " + user.username

//DONE
### Acceptance Criteria ID: US-004-005
Scenario: Test AI connection - fail with new connection
Given: The app is running
AND the user has logged in
AND the user has at least one AI connection displayed in the list, regardless if they are from the database or manually added
AND the user clicks the test button next to a new AI connection manually added
AND AIManager.testConnection() is called
When: the test returns failure
Then: prints in terminal " $$$$$$$$$$$$$$$$$$$$ AI Connection test failed $$$$$$$$$$$$$$$$$$$$"
AND highlight the API key of this AI connection in the list in red for 2 seconds
AND the other rows in the list should still be displayed
AND wait until previous popup message is dismissed
AND display a pop up message "AI Connection test failed!" + new line + "No new AI Connection " + provider + " created for " + user.username + ". " + new line + "Please check your configuration and try again."



