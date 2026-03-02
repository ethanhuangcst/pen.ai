# Feature 1: Content History Management
## User Stories & Acceptance Criteria

### User Story 1: View Enhanced Content History
**As a Pen user**, I want to view my enhanced content history with the count defined in Preferences - General, **so that** I can review previous versions of my content.

#### Acceptance Criteria
```gherkin
Scenario: Viewing content history in Preferences
  Given I am logged in to the Pen app
  And I have enhanced content history available
  When I open Preferences window
  And I navigate to the History tab
  Then I should see a scrollable list of my enhanced content history items
  And each item should display the history number, creation date/time, and enhanced content
  And the number of history items should match the count defined in General preferences
  And each history item should be read-only
  And each history item should display a maximum of 3 lines with trimmed content
  And clicking on a history item should copy the enhanced content to the clipboard
  And I should see a confirmation message when content is copied to clipboard
  And items should be ordered by creation date/time in descending order (most recent first)
```

### User Story 2: Empty History State
**As a Pen user**, I want to see a clear message when I have no enhanced content history, **so that** I understand the current state of my history.

#### Acceptance Criteria
```gherkin
Scenario: Viewing empty content history
  Given I am logged in to the Pen app
  And I have no enhanced content history
  When I open Preferences window
  And I navigate to the History tab
  Then I should see a text label in the window indicating that no history is available
  And the message should be clear and informative
  And I should not see any history items in the list
  And the message should include a brief explanation of how to generate content history
```

### User Story 3: History Item Interaction
**As a Pen user**, I want to easily copy enhanced content from my history, **so that** I can quickly reuse previous enhancements.

#### Acceptance Criteria
```gherkin
Scenario: Copying content from history
  Given I am logged in to the Pen app
  And I have enhanced content history available
  When I open Preferences window
  And I navigate to the History tab
  And I click on a history item
  Then the enhanced content should be copied to my clipboard
  And I should see a pop up message indicating the content was copied
  And I should be able to paste the content into other applications
  And the confirmation message should disappear after 1 seconds
```

## UI Design

### Overview
The History tab in Preferences provides users with a read-only view of their enhanced content history, allowing them to review and reuse previous enhancements. The design follows macOS Human Interface Guidelines for consistency with the platform.

### Components

#### 1. HistoryTabView.swift
- **Class**: `HistoryTabView`
- **Inheritance**: Inherits from `NSTableView` within a `NSTabViewItem`
- **Purpose**: Displays the enhanced content history tab in Preferences
- **Location**: `mac-app/Pen/Sources/Views/HistoryTabView.swift`
- **Responsibilities**:
  - Load and display content history from storage
  - Handle user interactions with history items
  - Manage empty state display
  - Show copy confirmation notifications

#### 2. Enhanced Content History Container
- **Type**: Scrollable NSTableView with custom cell rendering
- **Position**: Main content area of the History tab
- **Size**: Fills the available space in the tab with 16px padding on all sides
- **Behavior**: 
  - Scrolls vertically to accommodate multiple history items
  - Automatically resizes with window
  - Displays items in reverse chronological order (most recent first)
  - Updates dynamically when new content is enhanced
- **Styling**: 
  - Background color: System background (NSColor.windowBackgroundColor)
  - Border: 1px solid NSColor.separatorColor, radius 4px
  - Scrollbar: System default with thin style

#### 3. Enhanced Content History Item
- **Type**: Custom NSTableCellView
- **Structure**: 
  - **Top section**: History number (sequential) and creation date/time
  - **Middle section**: Enhanced content preview
  - **Bottom section**: Empty space for spacing
- **Content**: 
  - History number: Sequential numbering (1, 2, 3, ...) in bold
  - Creation date/time: Formatted as "MMM dd, yyyy HH:mm"
  - Enhanced content: Preview of the enhanced text
- **Styling**: 
  - **Font**: System font, 13pt for content (SF Pro Regular), 11pt for date/time (SF Pro Light)
  - **Color**: Text color (NSColor.labelColor) for content, secondary label color (NSColor.secondaryLabelColor) for date/time
  - **Layout**: Content aligned left with 12px padding, date/time aligned right
  - **Truncation**: Content trimmed to 3 lines with ellipsis
  - **Hover effect**: Background color change to NSColor.alternatingContentBackgroundColors[1]
  - **Selection**: Background color NSColor.selectedContentBackgroundColor with white text
  - **Spacing**: 8px between sections, 12px horizontal padding

#### 4. Empty History State
- **Type**: Centered NSStackView with vertical layout
- **Content**: 
  - Icon: System information icon (NSImage(named: NSImage.infoName))
  - Title: "No History Available"
  - Description: "Your enhanced content history will appear here after you use Pen to enhance text"
- **Styling**: 
  - Text color: NSColor.secondaryLabelColor
  - Icon size: 48x48px
  - Spacing: 16px between icon and title, 8px between title and description
  - Centered within the container with minimum 48px padding
  - Font: 14pt SF Pro Regular for title, 13pt SF Pro Light for description

#### 5. Copy Confirmation
- **Type**: Custom NSView with animation
- **Content**: "Content copied to clipboard"
- **Position**: Bottom center of the Preferences window, 20px from bottom
- **Behavior**: 
  - Appears briefly (2-3 seconds)
  - Fades in and out with Core Animation
  - Does not block user interaction
  - Automatically dismisses
- **Styling**: 
  - Background: NSColor.controlAccentColor with 80% opacity
  - Text: White, 13pt SF Pro Regular
  - Rounded corners: 8px
  - Padding: 12px horizontal, 8px vertical
  - Shadow: Subtle drop shadow for depth

### Interaction Flow
1. User opens Preferences window
2. User clicks on the History tab
3. System loads content history from storage
4. System displays either history items or empty state
5. User scrolls through history items (if available)
6. User clicks on a history item
7. System copies the full content to clipboard
8. System displays confirmation toast with animation
9. User can paste the content into other applications
10. Confirmation toast automatically disappears

### Responsiveness
- **Window resizing**: History container adjusts to window size with proper padding
- **Content truncation**: Automatically adjusts to available width, maintaining 3-line limit
- **Scrolling**: Smooth scrolling behavior with inertia for large history lists
- **Adaptability**: Works in both light and dark modes using system colors

### Accessibility
- **Keyboard navigation**: Full keyboard support including arrow keys for navigation and Enter to copy
- **VoiceOver support**: Descriptive labels for all elements, including history items and actions
- **Contrast**: Meets WCAG 2.1 AA standards for text readability
- **Focus indicators**: Clear focus ring for keyboard navigation
- **Dynamic Type**: Supports system text size preferences

### Localization
- All UI text should be localized through Localizable.strings
- Date/time formats should respect system locale settings
- Empty state message should be translatable
- Copy confirmation message should be translatable

# Feature 2: Add Content History Automatically
## User Stories & Acceptance Criterio
user story 1 - Automaically add Content History when receiving enhanced content from AI
// Set user's content_history_count = X
// Set Pen maxumunm_content_history_count = 40
### Scenaro 1 - when the current content history items is less than the user's maximum history count
Given the current content history items in DB is less than X
AND other pre-conditions
When user receives a new enhanced content from AI
and loaded to pen_enhanced_text_text
then 



## UI Design
