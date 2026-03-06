# Shortcut Key Feature

## User Story

As a Mac user, I want to open the Pen app main window by using a shortcut key combination, so that I can quickly access the app from anywhere

## Acceptance Criteria

```gherkin
Scenario: Press Shortcut key when Pen window is closed
  Given the Pen app is running
  AND Pen window is closed
  When the user presses the shortcut key combination
  Then the Pen main window opens
  And the app is ready for interaction

Scenario: Press Shortcut key when Pen window is open
  Given the Pen app is running
  And the Pen window is open
  When the user presses the shortcut key combination again
  Then the Pen window will be repositioned according to Pen-UI-behaviors.md
  And the app is still running with the menubar icon available

Scenario: Shortcut key works from any application
  Given the Pen app is running
  And the user is in a different application
  When the user presses the shortcut key combination
  Then the Pen main window opens
  And the app is ready for interaction

Scenario: Shortcut key is always available
  Given the Pen app is running
  When the user presses the shortcut key combination at any time
  Then the Pen main window opens
  And the app is ready for interaction

Scenario: Window does not open on app launch
  Given the app is not running
  When the app is launched
  Then the Pen main window should not be opened until the user presses the shortcut key combination
```