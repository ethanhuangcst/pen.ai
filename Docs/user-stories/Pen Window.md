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