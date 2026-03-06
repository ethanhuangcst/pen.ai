# Pen App Initialization

## Overview

This document describes the 3-step initialization process that Pen performs when launching.

## App Modes

The app can run in different modes based on initialization results:
- `offline-internet-failure` - No internet connectivity
- `offline-db-failure` - Database connection failed
- `online-logout` - Internet and database OK, but user not logged in
- `online-login` - Fully operational with user logged in

## User Stories and Acceptance Criteria

### User Story 1: 3-Step Initialization Process

As a Pen user, I want Pen to do a 3-step initialization process when launching, so that I can be sure it is working properly

#### Acceptance Criteria

```gherkin
Scenario: Pen performs 3-step initialization on launch
  Given the Pen app is not running
  When the user launches the app
  Then the app performs a 3-step initialization process
  And each step is completed successfully
  And the app is ready for use

Scenario: Pen displays initialization progress
  Given the Pen app is launching
  When the initialization process starts
  Then the app prints the current initialization step details in terminal
```

### User Story 2: Internet Connectivity Test (Step 1)

As a Pen user, I want to do internet connectivity test as step 1 initialization when launching, so that I can set myself as online/offline mode

#### Acceptance Criteria

```gherkin
Scenario: Pen tests internet connectivity as step 1
  Given the Pen app is not running
  When the Pen app launches
  Then conduct a internet connectivity test as step 1

Scenario: Initialization step 1 - Pen handles internet connectivity test pass
  Given the Pen app is launching
  When the internet connectivity test returns success
  And sets the flag "Internet Failure" to false
  And print in terminal： " ********************************** Pen Initialization Step 1: Internet Connectivity Test: PASS! **********************************"
  And continue the next step 2 initialization process

Scenario: Pen handles internet connectivity test failure
  Given the Pen app is launching
  When the internet connectivity test returns failure
  And sets the flag "Internet Failure" to true
  And the app sets itself to offline-internet-failure mode
  And print in terminal： " ********************************** Pen Initialization Step 1: Internet Connectivity Test: FAIL! **********************************"
  And print in terminal： " ********************************** OFFLINE-Internet-FAILURE MODE **********************************"
  And load the Mac menu bar icon and it's behaviors as offline-internet-failure mode
  AND do not open any window
  AND end the initialization process without proceeding to step 2
```

### User Story 3: Database Connectivity Pool (Step 2)

As a Pen user, I want to create a Singleton database connectivity pool as the single global database connectivity service for the entire app throughout it's life cycle as step 2 initialization, so that I can minimize the utilization of system resources

#### Acceptance Criteria

```gherkin
Scenario: Pen initializes database connectivity pool on launch
  Given the Pen app is launching
  When the initialization process step 1 is successfully completed
  Then the app creates a Singleton database connectivity pool as step 2 initialization
  AND run the database connectivity test
  AND return the test result

Scenario: Creating database connectivity pool success
  Given the Pen app is launching
  And the step 2 initialization is successfully completed
  When the database connectivity test returns success
  Then sets the flag "Database Failure" to false
  And print in terminal： " ********************************** Pen Initialization Step 2: Database Connectivity Test: PASS! **********************************"
  And continue the next step 3 initialization process

Scenario: Creating database connectivity pool failure
  Given the Pen app is launching
  And the step 2 initialization is completed
  When the database connectivity test returns failure
  Then sets the flag "Database Failure" to true
  And print in terminal： " ********************************** Pen Initialization Step 2: Database Connectivity Test: FAIL! **********************************"
  And print in terminal： " ********************************** OFFLINE-DB-FAILURE MODE **********************************"
  And the menu bar icon changes to icon_offline.png
  And the tooltip says "Pen (Offline)"
  And the app sets itself to offline-db-failure mode
  AND do not open any window
  AND end the initialization process without proceeding to step 3

Scenario: Pen reuses database connections
  Given the Pen app is running
  And the database connectivity pool is initialized
  When multiple components request database connections
  Then the app provides connections from the pool
  And the app reuses connections when they are returned
  And the app maintains optimal number of connections in the pool
```

### User Story 4: Auto Login and User Data Loading (Step 3)

As a Pen user, I want to automatically login and load my user data as the 3-step initialization process, so that I can login and retrieve all my personal data

#### Acceptance Criteria

```gherkin
Scenario: load pre-stored credentials
  Given the Pen app is launching
  When the step 3 initialization process starts
  Then the app should try to load the pre-stored user credentials
  AND return the result (user credentials or null)

Scenario: Pre-stored credentials loaded successfully
  Given the Pen app is launching
  And the step 3 initialization process starts
  And the app completed loading the pre-stored user credentials
  When it returns the pre-stored user credentials
  Then print in terminal： " ********************************** Load Pre-stored Credentials: " + preStoredCredentials + "  *********************************"
  AND parse the pre-stored user credentials
  AND try to log in with the stored credentials at background without opening any window
  AND returns the login result (success or failure)

Scenario: automatic login process - successful login
  Given the Pen app is launching
  And the step 3 initialization process starts
  And the app completed loading the pre-stored user credentials
  And the app completed the auto login process with the stored credentials
  When it returns success
  Then load the user data from the database
  AND create a global user data object to store the user data
  AND print in terminal： " ********************************** Pen Initialization Step 3: Load User Data: PASS! **********************************"
  AND print in terminal： " ********************************** Hello, " + userData + " **********************************"
  AND sets the app as online-login mode
  AND load the menu bar icon and it's behaviors as online mode
  AND end the initialization process

Scenario: automatic login process - failed login
  Given the Pen app is launching
  And the step 3 initialization process starts
  And the app completed loading the pre-stored user credentials
  And the app completed the auto login process with the stored credentials
  When it returns failure
  Then print in terminal： " ********************************** Auto Login Failed **********************************"
  AND set the app to online-logout mode
  AND print in terminal： " ********************************** ONLINE-LOGOUT MODE **********************************"
  AND the app sets itself to online-logout mode
  AND end the initialization process

Scenario: Pen opens LoginWindow if there is no stored credentials
  Given the Pen app is launching
  And the step 3 initialization process starts
  And the app completed loading the pre-stored user credentials
  When it returns null
  Then print in terminal： " ********************************** No Pre-stored Credentials Found **********************************"
  AND set the app to online-logout mode
  AND end the initialization process
  AND load the menu bar icon and it's behaviors as online-logout mode

Scenario: Pen automatically logs in with stored credentials
  Given the Pen app is launching
  And the user has previously stored login credentials
  When step 2 of initialization runs
  Then the app retrieves stored and encrypted credentials
  And the app attempts to log in automatically
  And the user is logged in without manual input
  And the user's personal data is retrieved

Scenario: Pen handles login failure
  Given the Pen app is launching
  And the stored credentials are invalid
  When the automatic login attempt runs
  Then the app displays a login error
  AND sets the flag "Login Failure" to true
  And it should open the LoginWindow to allow the user to input new credentials
```

### User Story 5: Load Content History Count Options

As a Pen user, I want to have 3 options for system content history count: low, medium, high, as the options in Preference - General - History Settings - Content history to save, so that I can change these numbers in the future through a centralized database table

#### Acceptance Criteria

```gherkin
Scenario: Load system configuration from database table
  Given the application is launched
  When it finds the system configuration in the database
  And the configuration is saved in a centralized system_config table
  Then it will load the system configuration options from the database
  AND set the global constants CONTENT_HISTORY_LOW, CONTENT_HISTORY_MEDIUM, CONTENT_HISTORY_HIGH from the database
  AND load the default prompt settings from the database
  AND print in terminal： " ********************************** Load Content History Count: LOW=" + CONTENT_HISTORY_LOW + ", MEDIUM=" + CONTENT_HISTORY_MEDIUM + ", HIGH=" + CONTENT_HISTORY_HIGH + " **********************************"

Scenario: Database table structure
  Given the application needs to read the system configuration
  When accessing the database table
  Then it should expect the following table structure:
  - Table name: system_config
  - Columns:
    - id (primary key)
    - default_prompt_name (varchar(255), nullable)
    - default_prompt_text (text, nullable)
    - content_history_count_low (integer, default: 10)
    - content_history_count_medium (integer, default: 20)
    - content_history_count_high (integer, default: 40)
    - created_at (timestamp)
    - updated_at (timestamp)

Scenario: Fallback to default values
  Given the application tries to load the system configuration
  When the database record is missing or corrupted
  Then it should fallback to loading default prompt from default_prompt.md file
  And if default_prompt.md is missing or corrupted, it should use hardcoded default values:
    - content_history_count_low=10
    - content_history_count_medium=20
    - content_history_count_high=40
    - default_prompt_name= "Enhance English"
    - default_prompt_text="Enhance English for the following text: "
```

### User Story 6: Load AI Configurations

As a Pen user, I want to establish all AI connections I have set up, and put them into a global pool so that I can easily access and use them in the app.

#### Acceptance Criteria

```gherkin
Scenario: Pen app loads all AI Configurations for the user
  Given Pen app is running
  WHEN the app has completed the initialization
  AND the user has completed the login process
  AND the app launched successfully as online-login mode
  Then it should use AIManager to load all AI Configuration configurations for the user
  AND return all AI Configuration configurations for the user
  AND continue with the next step

Scenario: Pen app loads all AI connection configurations for the user - no AI Configuration
  Given Pen app is running
  AND the app has completed the initialization
  AND the user has completed the login process
  AND the app launched successfully as online-login mode
  AND completed loading the AI Connection configurations from the database
  When it returns an empty list of AI Configuration configurations for the user
  Then wait until menu bar icon is fade out
  AND all other pop up messages are closed
  AND provide a new pop up message: "You don't have any AI Configuration set up yet. " + new line +Please go to Preference -> AI Configuration to set up your AI Configuration."

Scenario: Pen app loads all AI connection configurations for the user - at least one AI Configuration
  Given Pen app is running
  AND the app has completed the initialization
  AND the user has completed the login process
  AND the app launched successfully as online-login mode
  AND completed loading the AI Connection configurations from the database
  When it returns at least one AI Configuration configuration for the user
  Then repeat this process for each AI Configuration:
  - create a AIManager object for this AI Configuration, set as a global object
  - call AIManager.testConnection() to test the connection
  - print in this format: "********************************** Test AI Configuration for " + username + " :  Provider " + number + ":  connectionName + " **********************************"
```
