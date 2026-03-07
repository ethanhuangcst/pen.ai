# Pen Window Requirements (ATDD / BDD)

## 0. Index

- F1. Pen Window Startup and Initialization
  - US1. Close non-Pen windows when Pen window opens
  - US2. Load user information on Pen window launch
  - US3. Load AI configurations on Pen window launch
- F2. Input Mode and Clipboard Intake
  - US1. Switch between auto-copy mode and manual-edit mode
  - US2. Persist selected input mode across logout and app restart
  - US3. On switch to auto mode, load clipboard text and preserve manual draft
  - US4. On switch to manual mode, clear enhanced text and restore manual draft
  - US5. Manually load clipboard text into `pen_original_text_text` in auto mode
- F3. Text Enhancement Workflow
  - US1. Post original text to AI and display enhanced text
  - US2. Compare clipboard content before automatic enhancement
  - US3. Click enhanced text to copy
  - US4. Display loading indicator during AI processing
- F4. Default UI Display Reference
  - UI component definitions

---

## F1. Pen Window Startup and Initialization

### US1. Close non-Pen windows when Pen window opens
As a Pen user, I want Pen app to close all other windows when I open the Pen window, so that I can focus on the Pen window.

#### Acceptance Criteria
- AC1. When Pen window opens, all other app windows are closed.
- AC2. Pen window remains active and focused.

#### Scenarios
Scenario F1-US1-S1: Close non-Pen windows on Pen window open
  Given Pen app is running
  And one or more non-Pen windows are open
  When I open the Pen window
  Then all non-Pen windows are closed
  And Pen window stays open and focused

### US2. Load user information on Pen window launch
As a logged-in Pen user, I want Pen app to load my account information and preferences on launch, so that Pen can provide personalized behavior.

#### Acceptance Criteria
- AC1. In online-login mode, user information is loaded on Pen window launch.
- AC2. In online-logout mode, default UI is shown and initialization stops with a clear message.
- AC3. If user information loading fails, default UI is shown, error is logged, and user sees a clear message.

#### Scenarios
Scenario F1-US2-S1: Load user information in online-login mode
  Given Pen is running
  And app initialization is completed
  And user is logged in
  And app is in online-login mode
  When Pen window launches
  Then user information is loaded
  And account settings are available
  And user preferences are available
  And usage history is available
  And user information is logged in terminal

Scenario F1-US2-S2: Handle online-logout mode on launch
  Given Pen is running
  And app initialization is completed
  And user is not logged in
  And app is in online-logout mode
  When Pen window launches
  Then only default UI is shown
  And initialization process is stopped
  And a popup is shown with the localized not-logged-in message

Scenario F1-US2-S3: Handle user information load failure
  Given Pen is running
  And app initialization is completed
  And user is logged in
  And app is in online-login mode
  And user information cannot be loaded
  When Pen window launches
  Then only default UI is shown
  And initialization process is stopped
  And a popup is shown with the localized load-failure message
  And the failure is logged for troubleshooting

### US3. Load AI configurations on Pen window launch
As a logged-in Pen user, I want Pen app to load my AI configurations and prompts on launch, so that AI services are ready immediately.

#### Acceptance Criteria
- AC1. When global `AIManager` exists, Pen loads AI configurations from it.
- AC2. When global `AIManager` is unavailable, Pen creates a fallback `AIManager` and loads configurations.
- AC3. On configuration load failure, Pen shows localized error feedback and keeps clipboard intake available.
- AC4. If no providers are configured, Pen shows setup guidance and still loads clipboard text into original text field.

#### Scenarios
Scenario F1-US3-S1: Load AI configurations from global AIManager
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And global AIManager is initialized with configurations
  When Pen window launches
  Then AI configurations are loaded from global AIManager
  And `pen_controller_provider` is populated with available providers
  And `pen_controller_prompts` is populated with user prompts
  And default provider and prompt are selected
  And success is logged in terminal

Scenario F1-US3-S2: Create fallback AIManager when global object is unavailable
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And global AIManager is unavailable
  When Pen window launches
  Then a new AIManager is created
  And AI configurations are loaded from storage
  And `pen_controller_provider` is populated with available providers
  And `pen_controller_prompts` is populated with user prompts
  And success is logged in terminal

Scenario F1-US3-S3: Handle AI configuration load failure
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And AI configuration loading fails
  When Pen window launches
  Then a localized popup is shown for AI load failure
  And the failure is logged for troubleshooting
  And clipboard text is still loaded into `pen_original_text_text` when available

Scenario F1-US3-S4: Handle no AI providers configured
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And user has no AI providers configured
  When Pen window launches
  Then a localized setup-guidance popup is shown
  And guidance text is displayed in `pen_enhanced_text_text`
  And clipboard text is still loaded into `pen_original_text_text` when available

---

## F2. Input Mode and Clipboard Intake

### US1. Switch between auto-copy mode and manual-edit mode
As a Pen user, I want to switch between auto-copy mode and manual-edit mode, so that I can choose whether source text comes from clipboard or from my own draft.

#### Acceptance Criteria
- AC1. `pen_footer_auto_switch_button` toggles between Auto mode and Manual mode.
- AC2. In Auto mode, source text view is `pen_original_text_text`.
- AC3. In Manual mode, source text view is `pen_original_text_input`.
- AC4. Mode switch updates only input-mode-related UI and does not change selected prompt/provider.

#### Scenarios
Scenario F2-US1-S1: Switch from Auto mode to Manual mode
  Given Pen is running
  And Pen window is open
  And input mode is Auto
  When user toggles `pen_footer_auto_switch_button` to Manual
  Then input mode becomes Manual
  And `pen_original_text_input` is shown as source input view
  And `pen_original_text_text` is hidden as source input view
  And prompt and provider selections remain unchanged

Scenario F2-US1-S2: Switch from Manual mode to Auto mode
  Given Pen is running
  And Pen window is open
  And input mode is Manual
  When user toggles `pen_footer_auto_switch_button` to Auto
  Then input mode becomes Auto
  And `pen_original_text_text` is shown as source input view
  And `pen_original_text_input` is hidden as source input view
  And prompt and provider selections remain unchanged

### US2. Persist selected input mode across logout and app restart
As a Pen user, I want Pen app to remember my last selected input mode, so that I do not need to switch mode every time.

#### Acceptance Criteria
- AC1. The selected input mode is saved when the switch changes.
- AC2. After user logout and next login, Pen restores the last saved input mode.
- AC3. After app quit and relaunch, Pen restores the last saved input mode.
- AC4. If saved mode is unavailable or invalid, Pen falls back to Auto mode.

#### Scenarios
Scenario F2-US2-S1: Restore saved mode after logout and login
  Given Pen is running
  And user has selected Manual mode
  And mode preference is saved
  When user logs out and logs in again
  Then Pen window starts in Manual mode

Scenario F2-US2-S2: Restore saved mode after app relaunch
  Given user has selected Auto mode
  And mode preference is saved
  When user quits and relaunches Pen app
  Then Pen window starts in Auto mode

Scenario F2-US2-S3: Fallback to Auto mode on invalid saved value
  Given mode preference storage contains an invalid mode value
  When Pen window launches
  Then input mode is set to Auto

### US3. On switch to auto mode, load clipboard text and preserve manual draft
As a Pen user, I want Auto mode to immediately refresh source text from clipboard without losing my manual draft, so that I can freely move between both workflows.

#### Acceptance Criteria
- AC1. Switching to Auto mode triggers clipboard intake into `pen_original_text_text`.
- AC2. Existing text in `pen_original_text_input` is preserved and not overwritten.
- AC3. Clipboard validation and fallback behavior follow existing clipboard rules.
- AC4. In Auto mode, enhancement source uses `pen_original_text_text`.

#### Scenarios
Scenario F2-US3-S1: Switch to Auto mode with existing manual draft
  Given Pen is running
  And Pen window is open
  And input mode is Manual
  And `pen_original_text_input` contains draft text A
  And system clipboard contains text B
  When user toggles mode to Auto
  Then `pen_original_text_text` is updated from clipboard text B
  And `pen_original_text_input` still keeps draft text A
  And enhancement source is `pen_original_text_text`

### US4. On switch to manual mode, clear enhanced text and restore manual draft
As a Pen user, I want Manual mode to reset enhanced output and restore my draft, so that I can continue editing without stale enhancement results.

#### Acceptance Criteria
- AC1. Switching to Manual mode clears `pen_enhanced_text_text`.
- AC2. After clearing, `pen_enhanced_text_text` shows default hint text: "Enhanced text will appear here".
- AC3. Switching to Manual mode restores previously saved text in `pen_original_text_input`, if any.
- AC4. If no saved manual draft exists, `pen_original_text_input` starts empty and editable.
- AC5. In Manual mode, enhancement source uses `pen_original_text_input`.
- AC6. In Manual mode, enhancement can be triggered by either `Cmd+Enter` or clicking the send button.
- AC7. In Manual mode, pressing Enter without Command inserts a new line and does not trigger enhancement.

#### Scenarios
Scenario F2-US4-S1: Switch to Manual mode with existing draft
  Given Pen is running
  And Pen window is open
  And input mode is Auto
  And `pen_original_text_input` has saved draft text A
  And `pen_enhanced_text_text` currently shows enhanced result R
  When user toggles mode to Manual
  Then `pen_enhanced_text_text` is reset to "Enhanced text will appear here"
  And `pen_original_text_input` restores draft text A
  And enhancement source is `pen_original_text_input`

Scenario F2-US4-S2: Switch to Manual mode without existing draft
  Given Pen is running
  And Pen window is open
  And input mode is Auto
  And `pen_original_text_input` has no saved draft
  When user toggles mode to Manual
  Then `pen_enhanced_text_text` is reset to "Enhanced text will appear here"
  And `pen_original_text_input` is empty and editable

Scenario F2-US4-S3: Trigger enhancement from manual input by Cmd+Enter
  Given Pen is running
  And Pen window is open
  And input mode is Manual
  And `pen_original_text_input` contains source text
  When user presses Cmd+Enter in `pen_original_text_input`
  Then enhancement flow in F3-US1-S1 is executed
  And source text is taken from `pen_original_text_input`

Scenario F2-US4-S4: Trigger enhancement from manual input by send button click
  Given Pen is running
  And Pen window is open
  And input mode is Manual
  And `pen_original_text_input` contains source text
  When user clicks the manual send button in `pen_original_text_input`
  Then enhancement flow in F3-US1-S1 is executed
  And source text is taken from `pen_original_text_input`

Scenario F2-US4-S5: Enter without Command creates a new line in manual input
  Given Pen is running
  And Pen window is open
  And input mode is Manual
  And `pen_original_text_input` contains source text
  When user presses Enter in `pen_original_text_input` without Command
  Then a new line is inserted in `pen_original_text_input`
  And enhancement is not triggered

### US5. Manually load clipboard text into `pen_original_text_text` in auto mode
As a Pen user, I want to manually load clipboard text in Auto mode, so that I can explicitly refresh source content when needed.

#### Acceptance Criteria
- AC1. Clicking `pen_manual_paste_button` triggers clipboard text intake in Auto mode.
- AC2. Manual intake follows the same validation and display rules as automatic intake.
- AC3. In Manual mode, clicking `pen_manual_paste_button` does not overwrite `pen_original_text_input`.

#### Scenarios
Scenario F2-US5-S1: User clicks manual paste in Auto mode
  Given Pen is running
  And Pen window is open
  And input mode is Auto
  When user clicks `pen_manual_paste_button`
  Then clipboard intake is executed
  And `pen_original_text_text` is updated using clipboard rules

---

## F3. Text Enhancement Workflow

### US1. Post original text to AI and display enhanced text
As a Pen user, I want Pen app to send original text to AI and display enhanced text, so that I can quickly improve content quality.

#### Acceptance Criteria
- AC1. Enhancement request uses selected provider and selected prompt.
- AC2. Generated message follows the standard prompt format.
- AC3. AI response is displayed in `pen_enhanced_text_text` with overflow trimming and ellipsis.
- AC4. All user-visible messaging follows i18n.
- AC5. Enhancement source text is selected by active input mode:
  - Auto mode: source is `pen_original_text_text`
  - Manual mode: source is `pen_original_text_input`

#### Scenarios
Scenario F3-US1-S1: Enhance text with selected prompt and provider
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And AI providers are loaded in `pen_controller_provider`
  And prompts are loaded in `pen_controller_prompts`
  And active input mode has valid source text
  When enhancement is triggered
  Then prompt message is generated from selected prompt and source text
  And generated message follows RULE_GENERATE_MESSAGE
  And AI request is sent using selected provider
  And AI response is displayed in `pen_enhanced_text_text`
  And displayed enhanced text is trimmed with ellipsis when overflow occurs
  And user-visible text follows i18n

Scenario F3-US1-S2: Trigger enhancement on Pen window initialization
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And AI providers and prompts are loaded
  When Pen window initializes
  Then enhancement flow in F3-US1-S1 is executed

Scenario F3-US1-S3: Trigger enhancement on manual paste
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And AI providers and prompts are loaded
  When user clicks `pen_manual_paste_button`
  Then enhancement flow in F3-US1-S1 is executed

Scenario F3-US1-S3b: Trigger enhancement from manual input send action
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And input mode is Manual
  And `pen_original_text_input` contains source text
  When user triggers manual send action
  Then enhancement flow in F3-US1-S1 is executed
  And source text is taken from `pen_original_text_input`

Scenario F3-US1-S3c: Trigger enhancement from manual input Cmd+Enter
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And input mode is Manual
  And `pen_original_text_input` contains source text
  When user presses Cmd+Enter in `pen_original_text_input`
  Then enhancement flow in F3-US1-S1 is executed
  And source text is taken from `pen_original_text_input`

Scenario F3-US1-S4: Trigger enhancement on provider selection change
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And AI providers and prompts are loaded
  When user selects a different provider in `pen_controller_provider`
  Then enhancement flow in F3-US1-S1 is executed

Scenario F3-US1-S5: Trigger enhancement on prompt selection change
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And AI providers and prompts are loaded
  When user selects a different prompt in `pen_controller_prompts`
  Then enhancement flow in F3-US1-S1 is executed

#### RULE_GENERATE_MESSAGE
Generated prompt format:

`PROMPT:\n{current_prompt}\n\nTEXT:\n{current_original_text}`

### US2. Compare clipboard content before automatic enhancement
As a Pen user, I want automatic enhancement to run only when clipboard content changes, so that I do not get duplicate enhancements.

#### Acceptance Criteria
- AC1. Clipboard comparison is executed only in Auto mode.
- AC2. If text is unchanged, enhancement is skipped and current texts are preserved.
- AC3. If text changed, enhancement runs and fields are updated.
- AC4. Manual paste can bypass comparison and force enhancement.

#### Scenarios
Scenario F3-US2-S1: Skip enhancement when clipboard content is unchanged
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And input mode is Auto
  And Pen window is open
  And clipboard text equals current text in `pen_original_text_text`
  When an auto-trigger occurs
  Then clipboard text is re-read
  And comparison is executed
  And AI enhancement is skipped
  And current text in `pen_original_text_text` is preserved
  And current text in `pen_enhanced_text_text` is preserved

Scenario F3-US2-S2: Run enhancement when clipboard content changes
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And input mode is Auto
  And Pen window is open
  And clipboard text changes from A to B
  When clipboard change is detected
  Then new clipboard text B is loaded into `pen_original_text_text`
  And enhancement flow in F3-US1-S1 is executed
  And `pen_enhanced_text_text` is updated with result for B

Scenario F3-US2-S3: Manual paste force-enhances even when content is unchanged
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And input mode is Auto
  And Pen window is open
  And clipboard text equals current text in `pen_original_text_text`
  When user clicks `pen_manual_paste_button`
  Then comparison is bypassed
  And enhancement flow in F3-US1-S1 is executed

### US3. Click enhanced text to copy
As a Pen user, I want to click enhanced text to copy it to clipboard, so that I can reuse it quickly.

#### Acceptance Criteria
- AC1. Clicking `pen_enhanced_text_text` copies full enhanced text to clipboard.
- AC2. A localized success popup is shown.

#### Scenarios
Scenario F3-US3-S1: Copy enhanced text by clicking enhanced text area
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And Pen window is open
  And enhanced text is displayed in `pen_enhanced_text_text`
  When user clicks `pen_enhanced_text_text`
  Then full enhanced text is copied to system clipboard
  And localized copy-success popup is shown

### US4. Display loading indicator during AI processing
As a Pen user, I want to see a loading indicator while waiting for AI response, so that I understand processing is in progress.

#### Acceptance Criteria
- AC1. Loading indicator appears when enhancement request starts.
- AC2. Loading indicator stays visible until response is received or request fails.
- AC3. Loading indicator disappears after completion.

#### Scenarios
Scenario F3-US4-S1: Show loading indicator while sending AI request
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And Pen window is open
  And source text is ready
  When enhancement request starts
  Then loading indicator is shown over `pen_enhanced_text_text`
  And loading indicator remains visible during processing

Scenario F3-US4-S2: Hide loading indicator when AI response arrives
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And Pen window is open
  And loading indicator is visible
  When AI response is received
  Then loading indicator is hidden
  And `pen_enhanced_text_text` is updated with enhanced text

---

## F4. Default UI Display Reference

### UI Component Definitions

- `pen_footer`
  - Container size: `378x30`
  - Coordinate: `(0, 0)`
  - Background: transparent
  - Identifier: `pen_footer`
  - `pen_footer_instruction`
    - Content: localized `pen_footer_instruction`
    - Font: 12pt
    - Color: secondary label color
    - Alignment: left
  - `pen_footer_auto_label`
    - Content: localized `pen_footer_auto`
    - Font: 12pt
    - Color: secondary label color
    - Alignment: right
    - Frame: `(176, -6, 150, 30)`
  - `pen_footer_auto_switch_button`
    - Frame: `(326, 6, 32, 18)`
  - `pen_footer_label`
    - Content: localized `pen_footer_label`
    - Font: 14pt
    - Color: secondary label color
    - Alignment: right

- `pen_enhanced_text`
  - Identifier: `pen_enhanced_text`
  - Text field: `pen_enhanced_text_text`
  - Read-only, transparent, non-resizable
  - Size: `338x198`
  - Coordinate: `(20, 30)`
  - Font size: 12pt
  - Font color: `#6899D2`
  - Border: visible `#C0C0C0`, corner radius `4.0`

- `pen_controller`
  - Container size: `338x30`
  - Coordinate: `(20, 228)`
  - `pen_controller_prompts`: `222x20`, visible border, transparent background, 12pt
  - `pen_controller_provider`: `110x20`, visible border, transparent background, 12pt

- `pen_original_text`
  - Identifier: `pen_original_text`
  - Text field: `pen_original_text_text`
  - Read-only, transparent, non-resizable
  - Size: `338x88`
  - Coordinate: `(20, 258)`
  - Font size: 12pt
  - Border: visible `#C0C0C0`, corner radius `4.0`

- `pen_original_text_input`
  - Identifier: `pen_original_text_input`
  - Container size: `338x88`
  - Coordinate: `(20, 258)` (same frame as `pen_original_text`)
  - Editable text area: scrollable, multi-line, transparent background
  - Footer row (inside component): transparent background
    - Hint text (left): "Command + enter to enhance..."
    - Send button (right): icon-based button (`send.svg`)
  - In Manual mode: visible and used as enhancement source
  - In Auto mode: hidden but keeps existing draft text in memory/state

- `pen_manual_paste`
  - Identifier: `pen_manual_paste`
  - Container size: `300x30`
  - Coordinate: `(20, 353)`
  - `pen_manual_paste_button`: image-based button (`paste.svg`), size `20x20`
  - `pen_manual_paste_text`: read-only label, transparent, 12pt, localized
