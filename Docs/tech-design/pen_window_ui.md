# Pen Window UI Design

## Overview
The Pen window is a compact, focused UI for the Pen AI application, featuring a minimalist design with a footer containing the Pen brand and logo.

## Window Dimensions
- **Width**: 378px
- **Height**: 388px

## UI Components

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
- **Properties**: Read-only, selectable, not resizeable
- **Background**: Transparent
- **Border**: Visible, color = C0C0C0, rounded corner, 4.0
- **Identifier**: `pen_enhanced_text_text`

### Footer Container
- **Size**: 378px (width) × 30px (height)
- **Position**: (0, 0) from the bottom-left corner of the window
- **Background**: Transparent
- **Identifier**: `pen_footer`

### Footer Instruction
- **Content**: "Toggle window with [shortcut]" (localized)
- **Font**: System font, 12pt
- **Color**: Secondary label color
- **Alignment**: Left
- **Position**: (30, 9) absolute (relative to window bottom-left)
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
- **Position**: (336, 2) absolute (relative to window bottom-left)

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
- **Identifier**: `Pen_original_text_text`

### Manual Paste Container
- **Size**: 300px (width) × 30px (height)
- **Position**: (20, 346) from the bottom-left corner of the window
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

## Styling
- **Footer Text**: Right-aligned, secondary label color, 14pt system font
- **Logo**: 26x26px, positioned to the right of the footer text
- **Background**: Transparent footer container