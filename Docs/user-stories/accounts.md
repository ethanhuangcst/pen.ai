## User Story 1

As a Pen user, I want to see my account details in Account tab in Preferences window

### Acceptance Criteria

```gherkin
Scenario: Account tab displays user information
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  Then the Account tab displays the user's profile image
  And it displays the user's name
  And it displays the user's email

Scenario: User can update profile information
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  When the user updates their name
  And the user updates their email
  And the user clicks the "Save" button
  Then the user's information is updated
  And a success message appears

Scenario: User can change password
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  When the user enters a new password
  And the user confirms the new password
  And the user clicks the "Save" button
  Then the user's password is updated
  And a success message appears

Scenario: Password fields behavior
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  Then the password and confirm password fields are empty by default
  And leaving them blank and clicking "Save" does not change the password
  And a tooltip appears to inform the user about this behavior

```

## User Story 2

As a Pen user, I want to upload a profile image so that I can personalize my account

### Acceptance Criteria

```gherkin
Scenario: User can upload profile image
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  When the user clicks the "Upload Image" button
  Then a file picker window opens
  And the file picker only shows image files
  And a label under the button displays "Maximum file size: 1M, recommended 1:1 ratio"

Scenario: User selects large image file
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  And the user has opened the file picker
  When the user selects an image file larger than 1MB
  Then a message appears asking the user to choose another file

Scenario: User selects valid image file
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  And the user has opened the file picker
  When the user selects an image file smaller than 1MB
  Then the profile image is updated immediately
  And the image is not saved to the database until the user clicks "Save"

Scenario: User does not upload image
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  When the user does not upload any file
  And the user clicks "Save"
  Then the current profile image in the database is kept unchanged

```

## User Story 3

As a Pen user, I want to be able to log out from the Account tab so that I can securely end my session

### Acceptance Criteria

```gherkin
Scenario: User successfully logs out
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  When the user clicks the "Logout" button
  Then the user's information should be cleared from the global user object
  And the user is logged out
  And the user needs to login again to continue using the app
  And the app transitions to online-logout mode
  And the menu bar icon and it's behavior should update to reflect the logged-out state
  And the Preferences window closes
  And the Preferences window will not be opened again until the user logs in again

```

## User Story 4

As a Pen user, I want to enter a new password and have it validated so that I can securely update my account credentials

### Acceptance Criteria

```gherkin
Scenario: Password field instructions
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  Then a text label under the Confirm Password field displays "Leave password fields empty to keep your current password"
  AND the fields are not pre-filled

Scenario: Password validation
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  When the user enters a new password
  And the user enters a different confirm password
  Then the app automatically checks if the confirm password matches the new password in real  time
  And an error message appears if the passwords don't match when typing

Scenario: Empty password fields
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  When the user leaves both password fields empty
  And the user clicks the "Save Changes" button
  Then the user's password is not changed
  And a success message appears

Scenario: Valid password update
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  When the user enters a new password
  And the user enters the same confirm password
  And the user clicks the "Save Changes" button
  Then the user's password is updated
  And a success message appears

```

## User Story 5

As a Pen user, I want to save changes to my account information so that my updates are persisted

### Acceptance Criteria

```gherkin
Scenario: Save changes to database
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  And the user has made changes to their account information
  When the user clicks the "Save Changes" button
  Then the user's information is updated in the database
  And a success message appears

Scenario: Update local user object
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  And the user has made changes to their account information
  When the user clicks the "Save Changes" button
  Then the local global user object is updated with the new information
  And the updated information is reflected in the UI

Scenario: Save with no changes
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  When the user makes no changes
  And the user clicks the "Save Changes" button
  Then no changes are made to the database
  And a success message appears

Scenario: Save with profile image change
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  And the user has uploaded a new profile image
  When the user clicks the "Save Changes" button
  Then the new profile image is saved to the database
  And the local user object is updated with the new profile image
  And a success message appears

Scenario: Save with password change only
  Given the Pen app is running
  And the user is logged in
  And the Preferences window is open
  And the Account tab is selected
  And the user has entered a new password
  And the user has confirmed the new password
  When the user clicks the "Save Changes" button
  Then only the password is updated in the database
  And the local user object is updated
  And a success message appears
  And the Accounts tab reloads
  And the password fields are cleared

```