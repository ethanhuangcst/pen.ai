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
- **Color**: Label color
- **Alignment**: Left
- **Size**: 338px (width) × 198px (height)
- **Position**: (0, 0) relative to container
- **Properties**: Read-only, selectable, not resizeable
- **Identifier**: `enhanced_text`

### Footer Container
- **Size**: 378px (width) × 30px (height)
- **Position**: (0, 6) from the bottom-left corner of the window
- **Background**: Transparent
- **Identifier**: `pen_footer`

### Footer Text
- **Content**: " Pen " (with spaces around "Pen")
- **Font**: System font, 14pt
- **Color**: Secondary label color
- **Alignment**: Right
- **Position**: (80, 3) absolute (relative to window bottom-left)
- **Localization**: Uses `pen_footer_shortcut` key in Localizable.strings

### Logo
- **Size**: 26px × 26px
- **Image**: `logo.png` from Resources/Assets
- **Position**: (336, 12) absolute (relative to window bottom-left)

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