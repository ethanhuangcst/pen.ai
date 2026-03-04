# PenAI Account Management Feature

# User Story 0: Close Other Windows when launch login window
As a Pen user, I want Pen app to close all other windows when I launch login window, so that I can focus on the login window
Scenario: close other windows when launch login window
    Given Pen app is running
    AND other windows are open
    When I launch login window
    Then all other windows should be closed

## User Story 1

As a PenAI user, I want to log in to my account so that I can access my personalized settings and data

### Acceptance Criteria

```gherkin

Scenario: Login window has fixed size and cannot be resized
  Given the Pen app is running
  And the login window is open
  Then the login window has a fixed size of 518x318px
  And the login window cannot be resized

Scenario: User logs in with valid credentials
  Given the Pen app is running
  And the login window is open
  When the user enters a valid email address
  And the user enters a valid password
  And the user clicks the "Login" button
  Then the login window closes
  And the user is logged in
  And set the app as online-login mode
  And print in terminal "********************************* User logged in successfully "*********************************"
  And print in terminal "********************************* Hello, " + username + "  *********************************"
  And print in terminal "********************************* ONLINE-LOGIN MODE "*********************************"
  AND load the menu bar icon and it's behaviors as online mode
  AND create a global user object with the user data
  AND establish all AI connections for this user


Scenario: Login with remember me enabled
  Given the Pen app is running
  And the login window is open
  When the user enters valid credentials
  And the "Remember Me" option is enabled
  And the user clicks the "Login" button
  And the user logs in successfully
  Then the username and password are stored and encrypted in local key chain
  AND print in terminal "********************************* User Credentials Stored Successfully "*********************************"
  AND print in terminal "********************************* Key Chain info: " + keyChainInfo " *********************************"
  And set the app as online-login mode
  AND load the menu bar icon and it's behaviors as online mode
  And even after the app is closed, the app can load the pre-stored user credential from local keychain

Scenario: User logs in with remember me disabled
  Given the Pen app is running
  And the login window is open
  When the user enters valid credentials
  And the "Remember Me" option is disabled
  And the user clicks the "Login" button
  And the user logs in successfully
  Then the local key chain should be cleared
  AND print in terminal "********************************* User Credentials Stored Cleared!!! "*********************************"
  And set the app as online-login mode
  AND load the menu bar icon and it's behaviors as online mode
  And after the app is closed, the user needs to manually login again to access the app

Scenario: User logs in with invalid credentials
  Given the Pen app is running
  And the login window is open
  When the user enters an invalid email address
  And the user enters an invalid password
  And the user clicks the "Login" button
  Then an error message appears
  And the login window remains open
  And the user is not logged in

Scenario: User closes the login window
  Given the Pen app is running
  And the login window is open
  When the user closes the login window
  Then the login window closes
  And the user is not logged in
  And set the flag "UserLoggedIn" to false



Scenario: Login window has password hide/show button
  Given the Pen app is running
  And the login window is open
  When the user is entering a password
  Then there is a hide/show button next to the password field
  And clicking the button toggles between hiding and showing the password
  And the button uses the appropriate icons (hidden.svg and show.svg, 18px)


Scenario: User requests to register a new account
  Given the Pen app is running
  And the login window is open
  When the user clicks the "Register New Account" link
  Then the login window closes
  And the registration window opens

Scenario: User requests to reset password
  Given the Pen app is running
  And the login window is open
  When the user clicks the "Forgot Password?" link
  Then the login window closes
  And the forgot password window opens


```

## User Story 3

As a new user, I want to register for a PenAI account so that I can start using the application

### Acceptance Criteria

```gherkin
Scenario: User registers with valid information
  Given the Pen app is running
  And the registration window is open
  When the user enters a valid email address
  And the user enters a valid password that meets requirements
  And the user confirms the password
  And the user clicks the "Register" button
  Then the registration window closes
  And the user is logged in
  And the main application window appears

Scenario: User registers with invalid email
  Given the Pen app is running
  And the registration window is open
  When the user enters an invalid email address
  And the user enters a valid password
  And the user confirms the password
  And the user clicks the "Register" button
  Then an error message appears
  And the registration window remains open
  And the user is not registered

Scenario: User registers with weak password
  Given the Pen app is running
  And the registration window is open
  When the user enters a valid email address
  And the user enters a password that doesn't meet requirements
  And the user confirms the password
  And the user clicks the "Register" button
  Then an error message appears
  And the registration window remains open
  And the user is not registered

Scenario: User registers with password mismatch
  Given the Pen app is running
  And the registration window is open
  When the user enters a valid email address
  And the user enters a valid password
  And the user confirms with a different password
  And the user clicks the "Register" button
  Then an error message appears
  And the registration window remains open
  And the user is not registered

Scenario: User cancels registration
  Given the Pen app is running
  And the registration window is open
  When the user clicks the "Cancel" button
  Then the registration window closes
  And the login window opens
```

## User Story 2

As a PenAI user, I want to log out of my account so that I can secure my account and prevent unauthorized access

### Acceptance Criteria

```gherkin
Scenario: User logs out successfully
  Given the Pen app is running
  And the user is logged in
  When the logout process is initiated
  Then all app windows are closed
  And the menubar icon remains available
  And user information is cleaned up, including AI configurations and prompts
  And the local global user object is removed
  And the global AIManager object is removed
  And other system resources are cleaned up
  And the app is set to online-logout mode
  And the "UserLoggedIn" flag is set to false

  And a popup message appears: "User logged out. Please log in again to use Pen."
  And the message follows i18n guidelines

Scenario: Consistent logout behavior
  Given the Pen app is running
  And the user is logged in
  When the user selects "Logout" from the right-click menu of the menubar icon
  or clicks the "Logout" button from Preferences window, Account tab
  Then Pen app will trigger the same logout process as described in the "User logs out successfully" scenario
```

## User Story 4

As a PenAI user, I want to reset my password if I forget it so that I can regain access to my account

### Acceptance Criteria

```gherkin
Scenario: User resets password with valid email
  Given the Pen app is running
  And the forgot password window is open
  When the user enters a valid email address
  And the user clicks the "Send Reset Link" button
  Then a success message appears
  And the forgot password window closes
  And the login window opens
  And an email with password reset link is sent to the user

Scenario: User resets password with invalid email
  Given the Pen app is running
  And the forgot password window is open
  When the user enters an invalid email address
  And the user clicks the "Send Reset Link" button
  Then an error message appears
  And the forgot password window remains open
  And no email is sent

Scenario: User cancels password reset
  Given the Pen app is running
  And the forgot password window is open
  When the user clicks the "Cancel" button
  Then the forgot password window closes
  And the login window opens
```

