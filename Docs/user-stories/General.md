# User Story: Customizable Shortcut Key

## User Story
As a Pen user,
I want to be able to customize the shortcut key combination to toggle the Pen window,
So that I can use a key combination that works best for my workflow.

## Acceptance Criteria

//Done
### Scenario 1: Accessing Shortcut Key Customization
Given I am in the Pen preferences window,
When I navigate to the General tab,
Then I should see an option to customize the shortcut key combination.

//WIP
### Scenario 2: Single clicking to start a New Shortcut Key
Given I am in the shortcut key customization section,
AND the text field labeled "Click to record your own shortcut:" is at the initial status
AND the text field is inactive
When I click the text field labeled "Click to record your own shortcut:",
Then the text field should become active 
AND display "Press a key combination...".
AND my keybard cursor should be actie in the text field 
AND I can enter my custom shortcut

//WIP
### Scenario 6: Canceling Shortcut Recording
Given I have started recording a shortcut key combination,
AND the text field labeled "Click to record your own shortcut:" is active
When I click anywhere outside the text field,
Then the recording should be canceled.
AND the previous shortcut restores
AND the text field should display the previous shortcut
AND  the text field becones  inactive again

//WIP
### Scenario 3: Recording a New Shortcut Key
Given I am in the shortcut key customization section,
AND the text field labeled "Click to record your own shortcut:" is active by previous clicking
When press a key combination (e.g., Command+Option+P),
Then the text field should display the recorded key combination.
AND check if key combination conflicts with an existing system or application shortcut

//WIP
### Scenario 4: Shortcut Key Conflict Detection - conflict
Given I have entered my custom shortcut
When the new key combination is different from the current shortcut
AND it conflicts with any existing system or application shortcut,
Then the current key combination recording will be canceled.
AND it restores the previous shortcut
AND the text field is set to the initial status
AND it becomes inactive again
AND the application should display a pop up message indicating the conflict.
AND it prints in terminal " *************************************** Shortcut conflict !! ***********************************"

//WIP
### Scenario 5: Shortcut Key Conflict Detection - not conflict
Given I have entered my custom shortcut
When the new key combination is different from the current shortcut
AND it does not conflict with any existing system or application shortcut,
Then the new shortcut should be registerd 
AND the textfield will reset to  the initial status displaying the ccurrent shortcut
AND it become inactive again
AND the application should display a pop up message "Custom shortcut set: " + shortcut
AND it prints in terminal " ############################# New Shortcut Registered !! #############################"

//WIP
### Scenario 5: Shortcut Key Conflict Detection - same as previous shortcut
Given I have entered my custom shortcut
When the key combination is the same shortcut as the current one
Then the textfield will reset to  the initial status displaying the ccurrent shortcut
AND it become inactive again
AND the application should display a pop up message "Custom shortcut set: " + shortcut
AND it prints in terminal " ############################# Same shortcut !! ***********************************"


//Done
### Scenario 7: Mac OS Permission Request
Given I attempt to record a shortcut key combination for the first time,
When the system requires accessibility permissions for global keyboard monitoring,
Then the application should prompt me to grant the necessary permissions.
When I grant the permissions,
Then I should be able to continue recording the shortcut key.



//ToDo
### Scenario 8: Persisting Custom Shortcut Key
Given I have saved a custom shortcut key combination,
When I restart the application,
Then the custom shortcut key should still be active.

## Technical Requirements
- The application should use macOS accessibility APIs for global keyboard monitoring
- Shortcut key combinations should be stored in the application's preferences
- The application should handle permission requests gracefully
- The UI should provide clear feedback during the recording process
- Conflict detection should check both system and application-level shortcuts
- The application should support canceling recording by clicking outside the text field
- The UI should be responsive and provide visual feedback for all user interactions
