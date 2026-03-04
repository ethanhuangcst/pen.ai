# PenAI Preferences Feature

# User Story 0: Close Other Windows when open Preferences window
As a Pen user, I want Pen app to close all other windows when I open Preferences window, so that I can focus on the Preferences window
Scenario: close other windows when open Preferences window
    Given Pen app is running
    AND other windows are open
    When I open Preferences window
    Then all other windows should be closed

## User Story 1

As a PenAI user, I want to enter the Preferences window by right-clicking the menubar icon, so that I can configure my app settings

### Acceptance Criteria

```gherkin
Scenario: User accesses Preferences window via menubar icon
  Given the Pen app is running
  And the menubar icon is visible
  When the user right-clicks on the menubar icon
  Then a menu appears with a "Preferences" option
  And when the user clicks the "Preferences" option
  Then the Preferences window opens

Scenario: Preferences option is accessible in menubar menu
  Given the Pen app is running
  When the user right-clicks on the menubar icon
  Then the menu contains a "Preferences" option
  And the "Preferences" option has a keyboard shortcut "p"
```

