# Pen Window UI Design

## Overview
The Pen window is a compact, focused UI for the Pen AI application, featuring a minimalist design with a footer containing the Pen brand and logo.

## Window Dimensions
- **Width**: 378px
- **Height**: 388px

## UI Components

define container view in Pen window:
### identifier = pen_userlabel
### size = 120x30
### background = transparent
### coordinate = 232, 359
### user profile image thumbnail 
#### identifier = pen_userlabel_img
#### image = user profile image
#### size = 20x20
#### coordinate = 0, 0, relative position
### user name text label
#### identifier = pen_userlable_text
#### font = Pen global font, size = 12, bold
#### size = 90x30
#### coordinate = 26, -13, relative position
#### text = user name, trimed to fit width
#### support i18n


### Enhanced Text Container
- **Size**: 338px (width) × 198px (height)
- **Position**: (20, 30) from the bottom-left corner of the window
- **Background**: Transparent
- **Identifier**: `pen_enhanced_text`

### Enhanced Text Field
- **Content**: "Enhanced text will appear here" (placeholder)
- **Font**: System font, 14pt
- **Color**: 6899D2
- **Alignment**: Left
- **Size**: 338px (width) × 198px (height)
- **Position**: (0, 0) relative to container
- **Properties**: Read-only, selectable, not resizeable, clickable
- **Background**: Transparent
- **Border**: Visible, color = C0C0C0, rounded corner, 4.0
- **Identifier**: `pen_enhanced_text_text`
- **Click Behavior**: Copies enhanced text to clipboard and displays popup message "Text has been copied to clipboard" (does not close window)

### Footer Container
- **Size**: 378px (width) × 30px (height)
- **Position**: (0, 0) from the bottom-left corner of the window
- **Background**: Transparent
- **Identifier**: `pen_footer`

### Footer Instruction
- **Content**: "Hot key: [shortcut]" (localized)
- **Font**: System font, 12pt
- **Color**: Secondary label color
- **Alignment**: Left
- **Position**: (44, 23) absolute (relative to window bottom-left)
- **Identifier**: `pen_footer_instruction`
- **Localization**: Uses `pen_footer_instruction` key in Localizable.strings

### Footer Text
- **Content**: " Pen " (with spaces around "Pen")
- **Font**: System font, 14pt
- **Color**: Secondary label color
- **Alignment**: Right
- **Position**: (330, 9) absolute (relative to window bottom-left)
- **Identifier**: `pen_footer_lable`
- **Localization**: Uses `pen_footer_label` key in Localizable.strings

### Logo
- **Size**: 26px × 26px
- **Image**: `logo.png` from Resources/Assets
- **Position**: (17, 2) absolute (relative to window bottom-left)

### Auto Switch Container
- **Size**: 80px (width) × 30px (height)
- **Position**: Right side of footer, 20px from right edge of window
- **Background**: Transparent
- **Identifier**: `pen_footer_auto_switch`

### Auto Label
- **Content**: "Auto:" (localized)
- **Font**: System font, 12pt
- **Color**: Secondary label color
- **Alignment**: Left
- **Position**: (288, 23) absolute (relative to window bottom-left)
- **Identifier**: `pen_footer_auto_label`
- **Localization**: Uses `pen_footer_auto` key in Localizable.strings

### Auto Switch Button
- **Size**: 32px (width) × 18px (height)
- **Position**: (326, 6) absolute (relative to window bottom-left)
- **Style**: CustomSwitch (custom NSControl subclass)
- **Identifier**: `pen_footer_auto_switch_button`
- **Default State**: On (true)
- **Implementation**: `Sources/Views/CustomSwitch.swift`
- **Mode Mapping**:
  - On = Auto mode (`pen_original_text_text` visible)
  - Off = Manual mode (`pen_original_text_input` visible)
- **Persistence**:
  - Selected mode is persisted across logout/login and app restart
  - Invalid stored mode falls back to Auto mode

### Controller Container
- **Size**: 338px (width) × 30px (height)
- **Position**: (20, 228) from the bottom-left corner of the window
- **Background**: Transparent
- **Identifier**: `pen_controller`

### Pen Controller Prompts Drop-down Box
- **Size**: 222px (width) × 20px (height)
- **Position**: (20, 233) absolute (relative to window bottom-left)
- **Background**: Transparent
- **Border**: Visible, color = C0C0C0, rounded corner, 4.0
- **Identifier**: `pen_controller_prompts`
- **Default Item**: "Select Prompt"

### Pen Controller Provider Drop-down Box
- **Size**: 110px (width) × 20px (height)
- **Position**: (250, 233) absolute (relative to window bottom-left)
- **Background**: Transparent
- **Border**: Visible, color = C0C0C0, rounded corner, 4.0
- **Identifier**: `pen_controller_provider`
- **Default Item**: "Select Provider"

### Original Text Container
- **Size**: 338px (width) × 88px (height)
- **Position**: (20, 258) from the bottom-left corner of the window
- **Background**: Transparent
- **Identifier**: `pen_original_text`

### Original Text Field
- **Content**: "Original text will appear here" (placeholder)
- **Font**: System font, 14pt
- **Color**: Label color
- **Alignment**: Left
- **Size**: 338px (width) × 88px (height)
- **Position**: (0, 0) relative to container
- **Properties**: Read-only, selectable, not resizeable
- **Background**: Transparent
- **Border**: Visible, color = C0C0C0, rounded corner, 4.0
- **Identifier**: `pen_original_text_text`
- **Mode Behavior**: Visible in Auto mode, hidden in Manual mode

### Manual Input Container
- **Size**: 338px (width) × 88px (height)
- **Position**: (20, 258) from the bottom-left corner of the window (same frame as original text container)
- **Background**: Transparent
- **Identifier**: `pen_original_text_input`
- **Visibility**: Hidden in Auto mode, visible in Manual mode
- **Draft Preservation**: Keeps previously typed manual text when hidden and restored

### Manual Input Text Area
- **Type**: Editable multi-line text area (`NSTextView` inside `NSScrollView`)
- **Size**: 326px (width) × 58px (height)
- **Position**: (6, 24) relative to manual input container
- **Font**: System font, 12pt
- **Color**: Label color
- **Background**: Transparent
- **Border**: Uses outer container border, color = C0C0C0, rounded corner, 4.0
- **Scroll Behavior**: Vertical scroller auto-shown for overflow text

### Manual Input Footer Row
- **Size**: 338px (width) × 24px (height)
- **Position**: Bottom of `pen_original_text_input`
- **Background**: Transparent
- **Function**: Provides inline send hint + send button

### Manual Input Hint Text
- **Content**: "Command + enter to enhance..."
- **Font**: System font, 10pt
- **Color**: Secondary label color
- **Alignment**: Left
- **Position**: (8, -1) relative to manual input footer row

### Manual Input Send Button
- **Size**: 18px × 18px
- **Position**: (312, 2) relative to manual input footer row
- **Style**: Icon-only, no text label
- **Image**: `send.svg` from Resources/Assets
- **Background**: Transparent

### Manual Paste Container
- **Size**: 300px (width) × 30px (height)
- **Position**: (20, 353) from the bottom-left corner of the window
- **Background**: Transparent
- **Identifier**: `pen_manual_paste`

### Paste Button
- **Size**: 20px (width) × 20px (height)
- **Position**: (0, 5) relative to container
- **Background**: Transparent
- **Border**: None
- **Image**: `paste.svg` from Resources/Assets
- **Identifier**: `pen_manual_paste_button`
- **Selected**: False
- **Focused**: False

### Paste Label
- **Content**: "Paste from clipboard" (localized)
- **Font**: System font, 12pt
- **Color**: Label color
- **Alignment**: Left
- **Size**: 270px (width) × 30px (height)
- **Position**: (26, -7) relative to container (absolute: 46, 339)
- **Properties**: Read-only, not selectable
- **Identifier**: `pen_manual_paste_text`
- **Localization**: Uses `paste_from_clipboard_simple` key in Localizable.strings

## Coordinate System
- **Origin**: Bottom-left corner of the window
- **Y-axis**: Increases upward

## Code References
- **Footer Creation**: `addFooterContainer` method in `Pen.swift`
- **Localization String**: `pen_footer_shortcut` in `Localizable.strings`


### Loading Indicator Container
- **Size**: 338px (width) × 198px (height)
- **Position**: (20, 30) from the bottom-left corner of the window (same as enhanced text container)
- **Background**: Semi-transparent black (rgba(0, 0, 0, 0.5))
- **Border**: Rounded corner, 4.0
- **Identifier**: `pen_loading_indicator`
- **Z-Order**: Above pen_enhanced_text_text

### Loading Text
- **Content**: "Refining content ..." (localized)
- **Font**: System font, 14pt
- **Color**: White
- **Alignment**: Center
- **Position**: Center of the container
- **Identifier**: `pen_loading_text`
- **Localization**: Uses `refining_content` key in Localizable.strings

### Animation
- **Type**: Fade-in/out + pulse effect
- **Duration**: 1 second fade-in, continuous pulse
- **Implementation**: Use Core Animation for smooth transitions

## Styling
- **Footer Text**: Right-aligned, secondary label color, 14pt system font
- **Logo**: 26x26px, positioned to the right of the footer text
- **Background**: Transparent footer container
- **Loading Indicator**: Semi-transparent black background with white text and pulse animation

## Technical Implementation

### Loading Indicator Management
1. **Show Loading Indicator**:
   - Create the loading indicator view when the generate prompt event is triggered
   - Add it as a subview to the window's content view
   - Position it exactly over the pen_enhanced_text_text field
   - Start the fade-in animation
   - Start the pulse animation

2. **Hide Loading Indicator**:
   - When the AI response is received, start a fade-out animation
   - Remove the loading indicator from the view hierarchy after animation completes
   - Display the enhanced text in pen_enhanced_text_text

### Animation Implementation
```swift
// Fade-in animation
NSAnimationContext.runAnimationGroup { context in
    context.duration = 0.5
    loadingIndicator.animator().alphaValue = 1.0
} completionHandler: {}

// Pulse animation
let pulseAnimation = CABasicAnimation(keyPath: "opacity")
pulseAnimation.duration = 1.0
pulseAnimation.fromValue = 0.7
pulseAnimation.toValue = 1.0
pulseAnimation.autoreverses = true
pulseAnimation.repeatCount = .infinity
loadingIndicator.layer?.add(pulseAnimation, forKey: "pulse")
```

### Integration Points
- **Show**: In the method that sends the prompt to the AI
- **Hide**: In the completion handler that receives the AI response
- **Localization**: Add "refining_content" key to Localizable.strings files

## Floating Message

### Overview
The floating message is a temporary notification that appears when the application starts, welcoming the user and providing a brief introduction to Pen AI.

### UI Components

### Floating Message Window
- **Size**: Dynamic, based on content (minimum 240x40)
- **Position**: Below the menu bar icon
- **Background**: Semi-transparent system blue (75% opacity)
- **Border**: Rounded corners, 12pt
- **Shadow**: Light shadow for depth
- **Level**: Floating (above other windows)

### Floating Message Text
- **Content**: "Hello, [user name], I'm Pen, your AI writing assistant."
- **Font**: System font, 14pt
- **Color**: White
- **Alignment**: Center
- **Position**: Center of the window

### Animation
- **Type**: Fade-in/out
- **Duration**: 0.3 seconds fade-in, 3 seconds display, 0.3 seconds fade-out
- **Implementation**: Use Core Animation for smooth transitions

### Technical Implementation
```swift
// Fade in animation
NSAnimationContext.runAnimationGroup { context in
    context.duration = 0.3
    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    popupWindow.animator().alphaValue = 1.0
}

// Fade out animation after 3 seconds
DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
    NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.3
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        popupWindow.animator().alphaValue = 0.0
    } completionHandler: {
        popupWindow.orderOut(nil)
    }
}
```

### Integration Points
- **Show**: In the initialization process after successful login
- **Content**: Uses localized string with user name format
- **Positioning**: Calculated relative to the menu bar icon
