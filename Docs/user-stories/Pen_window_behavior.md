# Pen Window Behavior

## Feature: Pen Window Access and Positioning

The Pen window should only open when the app is in online login mode, and it should open in different positions based on how it's accessed (menubar click vs shortcut key).

## User Stories and Acceptance Criteria

### User Story 1: Window Access Control
**As a user**, I want the Pen window to only open when the app is in online login mode,
**So that** I can ensure my data is properly synchronized and I have access to all features.

#### Acceptance Criteria

**Scenario: Opening window when app is in online login mode**
  Given the app is in online login mode
  When I left-click the menubar icon
  Then the Pen window opens

**Scenario: Opening window via shortcut when app is in online login mode**
  Given the app is in online login mode
  When I press the shortcut key
  Then the Pen window opens

**Scenario: Preventing window access when app is not in online login mode**
  Given the app is not in online login mode
  When I left-click the menubar icon
  Then the Pen window does not open

**Scenario: Preventing shortcut access when app is not in online login mode**
  Given the app is not in online login mode
  When I press the shortcut key
  Then the Pen window does not open

### User Story 2: Window Opening via Menubar
**As a user**, I want to open the Pen window by left-clicking on the menubar icon,
**So that** I can quickly access the app without using keyboard shortcuts.

#### Acceptance Criteria

**Scenario: Toggling window visibility via menubar click**
  Given the app is in online login mode
  And the Pen window is closed
  When I left-click the menubar icon
  Then the Pen window opens

**Scenario: Closing window via menubar click**
  Given the app is in online login mode
  And the Pen window is open
  When I left-click the menubar icon
  Then the Pen window closes

### User Story 3: Window Positioning for Menubar Access
**As a user**, I want the Pen window to open at a standard position relative to the menubar icon when accessed via left-click,
**So that** I always know where to find the window.

#### Acceptance Criteria

**Scenario: Window positioning relative to menubar icon**
  Given the app is in online login mode
  And the Pen window is closed
  When I left-click the menubar icon
  Then the Pen window opens 6px to the right and 6px below the menubar icon
  And the window position is consistent regardless of where the menubar icon is located
  And the window position is not affected by the current mouse cursor position

### User Story 4: Window Opening via Shortcut Key
**As a user**, I want to open the Pen window by pressing a keyboard shortcut,
**So that** I can quickly access the app without moving my mouse to the menubar.

#### Acceptance Criteria

**Scenario: Opening window via shortcut key**
  Given the app is in online login mode
  And the Pen window is closed
  When I press the configured shortcut key
  Then the Pen window opens

**Scenario: Repositioning window via shortcut key**
  Given the app is in online login mode
  And the Pen window is already open
  When I press the configured shortcut key
  Then the Pen window is repositioned relative to the current mouse cursor
  And a new window is not opened

### User Story 5: Window Positioning for Shortcut Access
**As a user**, I want the Pen window to open at a position relative to my current mouse cursor when accessed via shortcut key,
**So that** the window appears conveniently near where I'm working.

#### Acceptance Criteria

**Scenario: Window positioning relative to mouse cursor**
  Given the app is in online login mode
  And the Pen window is closed
  When I press the shortcut key
  Then the Pen window opens 6px to the right and 6px below the current mouse cursor position
  And the window position updates based on the mouse cursor position at the time the shortcut is pressed
  And the window position is not affected by the menubar icon location
