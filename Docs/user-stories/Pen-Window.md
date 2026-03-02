Feature: Pen window initialization when launch

# User Story 1: Close Other Windows when launch Pen app
As a Pen user, I want Pen app to close all other windows when I launch Pen app, so that I can focus on the Pen window
Scenario: close other windows when launch Pen app
    Given Pen app is running
    AND other windows are open
    When I launch Pen app
    Then all other windows should be closed


# User Story 2: Load user information on window launch
As a Pen user
I want Pen app to load my AI model and settings when I am logged in
So that Pen can provide personalized service according to my own settings

Scenario: Load user information when launching Pen app in online-login mode
  Given Pen is running
  And app initialization is completed
  And user is logged in
  And app is in online-login mode
  When Pen window launches
  Then it should load user information including:
    - Account settings
    - User preferences
    - Usage history
  And it print the user information in terminal

Scenario: Handle online-logout mode on window launch
  Given Pen is running
  And app initialization is completed
  And user is not logged in
  And app is in online-logout mode
  When Pen window launches
  Then it shows only the default UI
  And it ends the initialization process
  And it displays a popup message:
    "Pen cannot serve when you are not logged in.\nPlease log in and try again."

Scenario: Handle user information load failure
  Given Pen is running
  And app initialization is completed
  And user is logged in
  And app is in online-login mode
  When Pen window launches
  And loading user information fails
  Then it shows only the default UI
  And it ends the initialization process
  And it displays a popup message:
    "Pen cannot load your login information.\nPlease log in and try again."
  And it logs the error for troubleshooting

# User Story 3: Load AI configurations on window launch
As a Pen user
I want Pen app to load my AI model and settings when I am logged in
So that my AI services are available immediately

Scenario: Load AI configurations from global AIManager
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And global AIManager object is initialized with AI configurations
  When Pen window launches
  Then it should load AI configurations from the global AIManager object
  And it should populate the AI providers drop-down box with available providers
  And it should populate the prompts drop-down box with user's predefined prompts
  And it should select the user's default AI provider and prompt
  And print in terminal "^^^^^^^^^^^^^^^^^^$$$$$$$$$$$$$$$ AIManager found in global object, AI configuration and Prompts loaded successfully. #################@@@@@@@@@@@@@@@"


Scenario: Create new AIManager as fallback
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And global AIManager object is not available
  When Pen window launches
  Then it should create a new AIManager object
  And it should load AI configurations from storage
  And it should populate the AI providers drop-down box with available providers
  And it should populate the prompts drop-down box with user's predefined prompts
   And print in terminal "^^^^^^^^^^^^^^^^^^$$$$$$$$$$$$$$$ AIManager NOT found in global object and a new one created. AI configuration and Prompts loaded successfully. #################@@@@@@@@@@@@@@@"

Scenario: Handle AI configuration load failure
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  When Pen window launches
  And loading AI configurations fails
  And it should log the error for troubleshooting
  And pops up a popup message: "Failed to load your AI connections.\nPlease try again later."
  And pen_original_text_text should still fetch the text from system clipboard

Scenario: Handle no AI providers configured
  Given Pen is running
  And user is logged in
  And app is in online-login mode
  And user has no AI providers configured
  When Pen window launches
  Then it should display a popup message: "You don't have any available AI connections yet, go to Preference - AI Connections to set up a new connection."
  And it should display the same text in pen_enhanced_text_text
  And pen_original_text_text should still fetch the text from system clipboard

# User Story 4: Automatically load clipboard text type content to pen_original_text_text text field
As a Pen user
I want Pen app to automatically identify text from system clipboard and paste it into the original text field
So that I can easily use Pen to process the text without manual input

Scenario: Paste valid text from clipboard on window launch
  Given Pen is running
  And system clipboard contains valid text content
  When Pen window launches
  Then it should automatically read the most recent text from system clipboard
  And it should paste the text into pen_original_text_text text field
  And trim the text to fit the size with the ellipsis "..." displayed at the last line
  And it should display the text as-is without modification

Scenario: Handle non-text clipboard content
  Given Pen is running
  And system clipboard contains non-text content (e.g., image, file)
  When Pen window launches
  Then it should not paste anything into pen_original_text_text text field
  And it should display the default placeholder text: "The text content in your clipboard will be automatically retrieved here"
  And it should follow i18n 

Scenario: Handle empty clipboard
  Given Pen is running
  And system clipboard is empty
  When Pen window launches
  Then it should display the message: "Clipboard is empty. Copy your text and click paste button, or use hot key [shortcut_key] to process."
  And it should follow i18n 

Scenario: Handle clipboard read failure
  Given Pen is running
  When Pen window launches
  And reading from clipboard fails
  Then it should display the message: "Unable to access clipboard. Please try again."
  And it should enable the manual paste button
  And it should log the error for troubleshooting

# User Story 5: Manually load clipboard text type content to pen_original_text_text text field
As a Pen user
I want to manually load text from system clipboard and paste it into the original text field
So that I can easily use Pen to process the text without manual input

Scenario: user clicks pen_manual_paste_button
  Given Pen is running
  AND pen window is opened
  When user clicks button pen_manual_paste_button
  Then Pen should identify text content from clipboard, consistent with the scenarios described in User Story Automatically load clipboard text type content to pen_original_text_text text field


Feature: Pen window post text to AI and get enhanced text
# User Story 1: post original text to AI and get enhanced text
As a Pen user
I want to post the text in pen_original_text_text text field to AI and get the enhanced text in pen_enhanced_text_text text field
So that I can easily use Pen to process the text without manual input

Scenario: enhance text
  Given Pen is running
  AND user is logged in
  AND app is in online-login mode
  AND user AI Configuratinos are loaded in pen_controller_provider drop-down box
  AND user prompts are loaded in pen_controller_prompts drop-down box
  WHEN generate prompt event is triggered
  THEN it will generate default prompt using the current selected prompt in pen_controller_prompts drop-down box
  AND the current text in pen_original_text_text text field
  AND follow RULE_GENERAGE_MESSAGE
  AND call AIManager and send the gnerated text to AI, initialized with the current selected AI provider in pen_controller_provider drop-down box
  AND display the response in pen_enhanced_text_text text field
  AND it should be trimmed using penWindowController.trimText()
  And it should follow i18n

Scenario: enhance text automatically on Pen window initialized
  Given Pen is running
  AND user is logged in
  AND app is in online-login mode
  AND user AI Configuratinos are loaded in pen_controller_provider drop-down box
  AND user prompts are loaded in pen_controller_prompts drop-down box
  WHEN Pen window is initialized
  OR user presses button pen_manual_paste_button
  OR Pen window is reloaded by pressing shortcut key
  OR Pen window is reloaded by left-clicking the Pen icon in the menu bar
  OR user slects a different AI provider in pen_controller_provider drop-down box
  OR user slects a different prompt in pen_controller_prompts drop-down box
  THEN it will trigger enhence text event as described in enhance text Scenario


  ## RULE_GENERAGE_MESSAGE
  ### The generated prompt should follow the format: "PROMPT:\n{current_prompt}\n\nTEXT:\n{current_original_text}"
  ### Example
  #### prompt:
  ```
    # Enhance English Content
    ## Act as a professional English editor and writing coach.
    Improve the following text to sound natural, fluent, and professional while keeping my original meaning.

    Please:

    1. Correct grammar, spelling, and punctuation.
    2. Improve sentence structure and clarity.
    3. Replace unnatural phrasing with native-level expressions.
    4. Suggest stronger vocabulary where appropriate, but keep it natural and not overly complex.
    5. Briefly explain the most important corrections so I can learn from them.
    6. Provide a final polished version at the end.

    Rewrite this to sound like natural spoken English. Make it conversational and fluent.

    Here is my text:
  ```

  #### Text:
  ```
    Hello, I want to express my gratitude for your help. Your support means a lot to me.
  ```
  #### postMessage:
  ```
    PROMPT:
    # Enhance English Content
    ## Act as a professional English editor and writing coach.
    Improve the following text to sound natural, fluent, and professional while keeping my original meaning.

    Please:

    1. Correct grammar, spelling, and punctuation.
    2. Improve sentence structure and clarity.
    3. Replace unnatural phrasing with native-level expressions.
    4. Suggest stronger vocabulary where appropriate, but keep it natural and not overly complex.
    5. Briefly explain the most important corrections so I can learn from them.
    6. Provide a final polished version at the end.

    Rewrite this to sound like natural spoken English. Make it conversational and fluent.

    Here is my text:

    TEXT:
    Hello, I want to express my gratitude for your help. Your support means a lot to me.
  ```







Feature: Pen window UI default display
As a Pen user
I want Pen app to have well-organized UI sections
So that I can have a good user experience


# UI Components Definition

- pen_footer
  define container view pen_footer
  # pen_footer
  ## size = 378x30
  ## coordinate = 0, 0
  ## background = transparent
  ## identifier = pen_footer
  ### text label pen_footer_instruction
  #### content = "Hot key: [shortcut_key] ."
  #### font = 12pt
  #### color = Secondary label color
  #### alignment = left
  #### position = 30, 9
  #### localization = Uses pen_footer_instruction key in Localizable.strings
  ### text label pen_footer_label
  #### content = " Pen "
  #### font = System font, 14pt
  #### color = Secondary label color
  #### alignment = Right
  #### position = 330, 9
  #### localization = Uses pen_footer_label key in Localizable.strings
  ### logo
  #### size = 26x26
  #### image = logo.png
  #### position = 336, 2

- pen_enhanced_text
  define container view "pen_enhanced_text"
  # text field pen_enhanced_text_text 
  ## read-only 
  ## background = transparent
  ## not resize-able 
  ## size 338x198 
  ## font color = 6899D2
  ## font size = 12pt
  ## border is visible, color = C0C0C0, rounded corner, 4.0
  ## coordinate: 20, 30 

- pen_controller
  define container view pen_controller
  # pen_controller
  ## size = 338x30
  ## coordinate = (20, 228)
  ## drop-down box pen_controller_prompts
  ### border = visible, color = C0C0C0, rounded corner, 4.0
  ### background = transparent
  ### font size = 12pt
  ### size = 222x20
  ### coordinate = (20, 233)
  ## drop-down box pen_controller_provider
  ### size = 110x20
  ### coordinate = (250, 233)
  ### border = visible, color = C0C0C0, rounded corner, 4.0
  ### background = transparent
  ### font size = 12pt

- pen_original_text
  define container view "pen_original_text": 
  # text field Pen_original_text_text
  ## read-only 
  ## background = transparent
  ## not resize-able 
  ## size 338x88 
  ## border is visible, color = C0C0C0, rounded corner, 4.0
  ## coordinate: 20, 258 
  ## font size = 12pt

- pen_manual_paste
  define container view "pen_manual_paste":
  # pen_manual_paste
  ## size = 300x30
  ## background = transparent
  ## coordinate = 20, 346
  ## button "pen_manual_paste_button"
  ### text disabled
  ### image = ../mac-app/Pen/Resources/Assets/paste.svg
  ### size = 20x20
  ### coordinate = -1, 5 (relative to container)
  ### label disabled
  ### selected = false
  ### focused = false
  ## text label "pen_manual_paste_text"
  ### read only
  ### background = transparent
  ### size = 270x30
  ### coordinate = 24, -8 (relative to container)
  ### text = "Paste from clipboard", font size = 12
  ### i18n = yes

# User Story 2: Compare clipboard content before enhancing text
As a Pen user
I want Pen app to only automatically enhance text when the clipboard content changes
So that I don't get duplicate enhancements when the clipboard hasn't changed

Scenario: Pen window reloads with same clipboard content
  Given Pen is running
  AND user is logged in
  AND app is in online-login mode
  AND system clipboard contains text content
  AND Pen window is open with the same text in pen_original_text_text
  WHEN Pen window is initialized
  OR Pen window is reloaded by pressing shortcut key
  OR Pen window is reloaded by left-clicking the Pen icon in the menu bar
  THEN it should get the new content from clipboard
  AND compare it with the current text in pen_original_text_text
  AND only call AIManager to enhance text when they are different
  AND if they are the same, skip the enhancement process
  AND keep the current text in pen_enhanced_text_text
  AND keep the current text in pen_original_text_text

Scenario: When Pen window open, auto enhance text in realtime when clipboard content changes
  Given Pen is running
  AND user is logged in
  AND app is in online-login mode
  AND system clipboard contains text content A
  AND Pen window is open with text in pen_original_text_text
  AND has enhanced text in pen_enhanced_text_text successfully
  WHEN system clipboard content changes to B
  AND Pen atumatically detects the clipbard content change
  AND triggers the enhancement process in real time

Scenario: Click pen_manual_paste_button force enhance text
  Given Pen is running
  AND user is logged in
  AND app is in online-login mode
  AND system clipboard contains text content
  AND Pen window is open with text A in pen_original_text_text
  WHEN user clicks pen_manual_paste_button
  THEN it should get the new content A from clipboard
  AND by pass the comparison process
  AND force trigger the enhancement process

# User Story 3: Click enhanced text to copy and close window
As a Pen user
I want to click the enhanced text to copy it to the clipboard and close the window
So that I can quickly use the enhanced text without manual copying

Scenario: Click enhanced text to copy and close window
  Given Pen is running
  AND user is logged in
  AND app is in online-login mode
  AND Pen window is open
  AND text has been enhanced and displayed in pen_enhanced_text_text
  WHEN user clicks on the text in pen_enhanced_text_text
  THEN it should copy the enhanced text to the system clipboard
  AND it should close the Pen window
  AND it should display a popup message for 1 second
  AND the message should say: "Text has been copied to clipboard"
  AND it should follow i18n

# User Story 4: Display loading indicator during AI processing
As a Pen user
I want to see a semi-transparent message "Refining content ..." with animation effect floating in front of pen_enhanced_text_text
So that I know what's going on while waiting for the AI response

Scenario: Display loading indicator when sending chat to AI
  Given Pen is running
  AND user is logged in
  AND app is in online-login mode
  AND Pen window is open
  AND text is ready to be enhanced
  WHEN the generate prompt event is triggered
  THEN it should display a semi-transparent message "Refining content ..." with animation effect
  AND the message should float in front of pen_enhanced_text_text
  AND the animation should continue until the AI response is received

Scenario: Hide loading indicator when receiving AI response
  Given Pen is running
  AND user is logged in
  AND app is in online-login mode
  AND Pen window is open
  AND the loading indicator is displayed
  WHEN the AI response is received
  THEN it should hide the loading indicator
  AND display the enhanced text in pen_enhanced_text_text