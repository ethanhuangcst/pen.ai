# PenAI Mac App Generic UI Requirements

## User Story 1

As a PenAI user, I want all application windows to have a consistent and professional UI design so that the app feels polished and easy to use

### Acceptance Criteria

```gherkin
Scenario: Windows are always in front
  Given the Pen app is running
  When any application window opens
  Then it is in front of all other windows
  And it remains visible above other windows when other applications are active

Scenario: Windows have consistent visual styling
  Given the Pen app is running
  When any application window opens
  Then it has rounded corners
  And it has a transparent background
  And it has a shadow effect

Scenario: Default Windows open position relative to the Pen icon in Mac system menu bar
  Given the Pen app is running
  When any application window opens
  Then it should open at the default position:
  - Window top-left X = Pen icon X + 6px
  - Window top-left Y = bottom of menu bar + 6px
  - Be correctly aligned on any display
  - Work with notch / different menu bar heights
  - Not rely on guesses or hardcoded screen sizes




Scenario: Window size and positioning parameters are not hard-coded
  Given the Pen app is running
  When any application window opens
  Then window dimensions (width, height) are retrieved from configuration
  And positioning offsets (e.g., 6px from mouse cursor) are retrieved from configuration
  And window position is calculated dynamically based on mouse cursor position
  And no sizing or positioning values are hard-coded in the application code

Scenario: Windows are available in all desktops
  Given the Pen app is running
  And any application window is open
  When the user switches to a different desktop
  Then the window is visible in the new desktop

Scenario: Windows have close buttons
  Given the Pen app is running
  When any application window opens
  Then there is a close button on the top right corner

Scenario: Close buttons function consistently
  Given any application window is open
  When user clicks the close button
  Then the window is closed
  And the app is still running
  And the menubar icon is still available
  And all app functionality remains accessible

Scenario: Windows display PenAI logo
  Given the Pen app is running
  When any PenAI window opens
  Then the window displays the PenAI logo (38x38px)
  And the logo is positioned in front of the window title text label
  AND aligned center vertically with the title text
  And the logo is placed at the same position across all windows

Scenario: Windows do not display system toolbar or window controls
  Given the Pen app is running
  When any application window opens
  Then it does not display the system toolbar
  And it does not display the standard window controls (minimize, maximize, close buttons)
  And it uses custom close button instead

Scenario: System popup messages fade out after 2 seconds
  Given the Pen app is running
  When the app wants to show a system message to the user by a popup message
  Then the popup message should follow the consistent design:
  - It should be a rectangle shape window with rounded corners
  - It should be always on top of all other windows, including the Pen app
  - by default, the size is 240px width x 40px height
  - the size auto adjusts to the content length
  - the background color should be different from the app's main window color, with 75% opacity
  - it should have a shadow effect
  - No toolbar or title bar
  - No buttons
  - Appears as a floating chat bubble
  - Fades in and fades out smoothly
  - By default, it fades out after 3 seconds


Scenario: System popup messages shows at the position relative to the Pen icon in Mac system menu bar
  Given the Pen app is running
  When a popup message is displayed
  Then it should open at the default position:
  - Message window top-left X = Pen icon X + 6px
  - Message window top-left Y = bottom of menu bar + 6px
  - Be correctly aligned on any display
  - Work with notch / different menu bar heights
  - Not rely on guesses or hardcoded screen sizes
```

## User Story 2

As a PenAI user, I want a consistent menubar interface so that I can easily access app functions

### Acceptance Criteria

```gherkin
Scenario: Menubar icon is always present
  Given the Pen app is running
  Then the menubar icon is visible
  And it remains visible even when no windows are open
  And it should not display any background and boarder when left clicked
  And it should not display any background and boarder when right clicked


```

## User Story 3

As a PenAI user, I want tabbed interfaces to be consistent across the app so that navigation is intuitive

### Acceptance Criteria

```gherkin
Scenario: Tabbed interfaces display all tabs clearly
  Given the Pen app is running
  When a window with tabs opens
  Then all tabs are visible
  And tab labels are clear and descriptive
  And the active tab is clearly indicated

Scenario: Tabbed interfaces adjust to content
  Given the Pen app is running
  When a window with tabs opens
  Then the window height adjusts based on the content of the active tab
  And all tab content is fully visible

Scenario: Tab switching works consistently
  Given the Pen app is running
  And a window with tabs is open
  When the user clicks on a different tab
  Then the content changes to match the selected tab
```

## User Story 4

As a PenAI user, I want consistent window sizing behavior so that the app feels predictable

### Acceptance Criteria

```gherkin
Scenario: Main window has fixed width
  Given the Pen app is running
  When the main application window opens
  Then it has a fixed width of 600px unless specified otherwise
  And it maintains this width regardless of content


Scenario: All windows maintain consistent proportions
  Given the Pen app is running
  When any window opens
  Then its dimensions are appropriate for its purpose
  And it provides enough space for all content to be visible
  And it doesn't overwhelm the screen
```

## User Story 5

As a PenAI user, I want window controls to handle user input correctly so that I can interact with the app efficiently

### Acceptance Criteria

```gherkin
Scenario: Window controls handle mouse input correctly
  Given the Pen app is running
  When any application window opens
  And all buttons should respond to mouse clicks
  And all interactive elements should have proper focus states

Scenario: Window controls handle mouse hover effects
  Given the Pen app is running
  When any application window opens
  And the user moves the mouse cursor over interactive elements
  Then those elements should display a visual indication (e.g., change color, add border)
  And provide feedback to the user


Scenario: Window controls recognize keyboard inputs correctly
  Given the Pen app is running
  When any application window opens
  And the user presses the keyboard
  Then Then all input fields should receive keyboard input correctly
  
Scenario: Window controls handle system shortcuts
  Given the Pen app is running
  When any application window opens
  And the user presses system shortcuts (e.g., cmd+c, cmd+v, cmd+x, cmd+a, shift+cmd+arrows etc)
  Then the app should respond with the expected behavior (e.g., copy, paste, cut, select all, move window etc)

Scenario: Using tab key/shift+tab to navigate between UI elements
  Given the Pen app is running
  When any application window opens
  And the user presses the tab key
  Then the focus should move to the next UI element in the tab order
  And the app should respond with a smooth and responsive movement
  And the user can press shift+tab to move to the previous UI element

Scenario: Pressing Enter key triggers active UI control
  Given the Pen app is running
  When any application window opens
  And a UI control (e.g., button) has focus
  And the user presses the Enter key
  Then the app should trigger the action associated with the focused UI control
  And the behavior should be equivalent to clicking the control with the mouse

```

## User Story: Automatic Light/Dark Mode Switching

**US:** As a user, I want the app to automatically switch between light and dark mode based on my system preferences, so that it always matches my system appearance settings.

**AC:**
- Given the user has system dark mode enabled
- When the app is launched
- Then the app should automatically display in dark mode
- And all UI elements should use dark mode colors and styles

- Given the user has system light mode enabled
- When the app is launched
- Then the app should automatically display in light mode
- And all UI elements should use light mode colors and styles

- Given the app is running
- When the user changes their system appearance setting
- Then the app should immediately switch to the new mode
- And the transition should be smooth without disrupting the user's work

- Given the app supports both light and dark modes
- When the user interacts with any UI element
- Then the element should respond appropriately in both modes
- And text should be legible in both light and dark environments


