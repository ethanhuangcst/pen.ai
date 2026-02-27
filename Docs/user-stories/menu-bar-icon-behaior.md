# Menu Bar Icon Feature

## User Story 1

As a mac user, I want the Pen app to load the menu bar icon and it's behaviors as online/offline mode on launch, depending on the initialization result, so that I can use the app successfully in online or offline mode.

### Acceptance Criteria

```gherkin
Scenario: Load menu bar icon and it's behaviors as online-login mode when all initialization steps pass
  Given the Pen app is launching in it's Initialization process
  When Initialization step 1 - test internet connectivity successfully passed
  AND Initialization step 2 - load dabatase connectivity pool successfully passed
  AND Initialization step 3 - User login successfully passed  
  Then the Pen app should run as  online-login mode
  AND a menu bar icon (icon.png) appears
  And the icon is clickable
  And display a tooltip message "Hello, {user_name}, I'm Pen, your AI writing assistent."
  And the tooltip message will fade out after 2 seconds
  And left click the icon opens the PenAI window
  And right click the icon displays a dropdown menu with preferences and exit

Scenario: Load menu bar icon and it's behaviors as online-logout mode when initialization steps 1-2 pass but step 3 fails
  Given the Pen app is launching in it's Initialization process
  When Initialization step 1 - test internet connectivity successfully passed
  AND Initialization step 2 - load dabatase connectivity pool successfully passed
  AND Initialization step 3 - load user data failed
  Then the Pen app should run as  online-logout mode
  AND a menu bar icon (icon.png) appears
  And display a tooltip message "Hello, I'm Pen, your AI writing assistent. Please login to continue." 
  And the tooltip message will fade out after 2 seconds
  And the icon is clickable
  And left click the icon opens the Login window
  And right click the icon displays exit

Scenario: Load menu bar icon and it's behaviors as online-login mode when user manually login
  Given the Pen app is running
  When the user manually login successfully
  Then the Pen app should run as  online-login mode
  AND a menu bar icon (icon.png) appears
  And display a tooltip message "Hello, {user_name}, I'm Pen, your AI writing assistent." 
  And the tooltip message will fade out after 2 seconds
  And the icon is clickable
  And left click the icon opens the PenAI window
  And right click the icon displays a dropdown menu with preferences and exit

Scenario: Load menu bar icon and it's behaviors as online-login mode when user manually logout
  Given the Pen app is running
  When the user manually logout successfully
  Then the Pen app should run as  online-logout mode
  AND a menu bar icon (icon.png) appears
  And display a tooltip message "Hello, I'm Pen, your AI writing assistent. Please login to continue."
  And the tooltip message will fade out after 2 seconds
  And the icon is clickable
  And left click the icon opens the Login window
  And right click the icon displays exit

Scenario: Load menu bar icon and it's behaviors as offline mode when initialization steps 1 pass but step 2 fails
  Given the Pen app is launching in it's Initialization process
  When Initialization step 1 - test internet connectivity successfully passed
  AND Initialization step 2 - load dabatase connectivity pool failed
  Then the Pen app should run as  offline-db-failure mode
  AND a menu bar icon (icon_offline.png) appears
  And display a tooltip message "Oops, something went wrong with our service, please try again later..." 
  And the tooltip message will fade out after 2 seconds
  And the icon is clickable
  And left click the icon displays "Reload" to restart the 3-step initialization process
  And right click the icon displays exit


Scenario: Load menu bar icon and it's behaviors as offline mode when initialization steps 1 fails
  Given the Pen app is launching in it's Initialization process
  When Initialization step 1 - test internet connectivity successfully failed
  Then the Pen app should run as  offline-internet-failure mode
  AND a menu bar icon (icon_offline.png) appears
  And display a tooltip message "You don't seem to have an internet connection, please check your network settings"
  And the tooltip message will fade out after 2 seconds
  And the left click the icon displays "Reload" to restart the 3-step initialization process
  And right click the icon displays exit
```
