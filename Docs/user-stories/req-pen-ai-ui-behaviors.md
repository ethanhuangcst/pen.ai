## User Story

As a mac user, I want to see the PenAI main window in a good design, so that I feel it is easy to use

## Acceptance Criteria

```gherkin



Scenario: PenAI main window has correct size
  Given the Pen app is running
  When the PenAI main window opens
  Then it has a fixed size of 518x600px
  And the user cannot resize it

Scenario: PenAI window positioned at mouse cursor (happy path)
  Given the Pen app is running
  And the current mouse position leaves enough space for the window (distance from x position of mouse cursor to the right edge of screen > the width of PenAI window, AND distance from y position of mouse cursor to the bottom edge of screen > the height of PenAI window)
  When the PenAI window is opened
  Then PenAI window should be placed at this position:
  X postion = X position of the mouse cursor +6px
  y position = y position of the mouse cursor +6px

Scenario: PenAI window positioned at mouse cursor when pressing shortcut (alternative path)
  Given the PenAI window is not open
  And the current mouse position does not leave enough space for the window (distance from x position of mouse cursor to the right edge of screen < the width of PenAI window, OR distance from y position of mouse cursor to the bottom edge of screen < the height of PenAI window)
  When the user presses the shortcut key to open the PenAI window
  Then PenAI window should be placed at this position:
  X position of the top-left corner = X position of the mouse cursor +6px
  y position of the top-left corner = y position of the mouse cursor +6px
  AND part of the window is hidden outside of the screen


Scenario: PenAI window positioned at mouse cursor edge cases when pressing shortcut
  Given the PenAI window is not open
  And the mouse cursor is at the screen edge
  When the user presses the shortcut key to open the PenAI window
  Then PenAI window should be placed at this position:
  X position of the top-left corner = X position of the mouse cursor +6px
  y position of the top-left corner = y position of the mouse cursor +6px
  AND part of the window may be hidden outside of the screen

Scenario: Default popup message displayed position
  Given the Pen app is running
  When a popup message is displayed
  Then it should be positioned at:
  X position = X position of the mouse cursor +6px
  Y position = Y position of the mouse cursor +6px

```