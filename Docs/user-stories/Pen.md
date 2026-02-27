# Pen Window Positioning

## User Story

As a PenAI user, I want the Pen window to be positioned consistently relative to my mouse cursor when I open it with a shortcut key, so that it appears exactly where I expect it to be.

### Acceptance Criteria

```gherkin
Scenario: Pen Window are positioned consistently relative to mouse cursor when shortcut key is pressed
  Given the Pen app is running
  And the mouse cursor is at position (x, y)
  When the user presses the shortcut key to open the Pen window
  Then the top-left corner of the window is at position (x+6, y+6)
  And part of the window may be hidden outside the screen if necessary
```