# Prompts UI Design Specification

## Overview
This document outlines the UI design specifications for the Prompts tab and related components in the Pen AI application. The design follows the same style and patterns as the AI Configuration tab to ensure consistency across the application.

## 1. PromptsTabView

### 1.1 Layout
- **Container**: NSView with white background
- **Size**: 680x520 (matches Preferences window size)
- **Padding**: 20px margins on all sides

### 1.2 UI Elements

#### User Label
- **Position**: (20, windowHeight - 92)
- **Size**: (windowWidth - 40, 24)
- **Text**: "Predefined prompts for [User Name]"
- **Font**: Bold system font, 16pt
- **Alignment**: Left

#### Default Label
- **Position**: (20, windowHeight - 108)
- **Size**: (windowWidth - 40, 16)
- **Text**: "First prompt will be the default prompt"
- **Font**: System font, 12pt
- **Color**: Secondary label color
- **Alignment**: Left

#### Table Container
- **Position**: (20, 50)
- **Size**: (windowWidth - 40, windowHeight - 166)
- **Border**: 1px light gray (0.5 alpha)
- **Corner Radius**: 8px
- **Background**: White

#### Table View
- **Size**: Fills table container
- **Border**: 1px light gray (0.3 alpha)
- **Rows**: 70px height each
- **Columns**:
  | Column | Width | Min/Max Width | Description |
  |--------|-------|---------------|-------------|
  | Name | 88px | 88px | Read-only, trimmed to 1 line |
  | Prompt | 288px | 288px | Read-only, trimmed to 3 lines with "..." |
  | Edit | 38px | 38px | Edit button |
  | Delete | 38px | 38px | Delete button |

#### Edit Button
- **Size**: 20x20px
- **Position**: Centered in edit column
- **Icon**: edit.svg (18x18px)
- **Color**: System blue
- **Behavior**: Opens NewOrEditPrompt window with existing prompt data

#### Delete Button
- **Size**: 20x20px
- **Position**: Centered in delete column
- **Icon**: delete.svg (18x18px)
- **Color**: System red
- **Behavior**: Shows delete confirmation dialog

#### New Button
- **Position**: (20, 10)
- **Size**: 88x32px
- **Text**: "New"
- **Style**: Rounded bezel, 1px green border, 6px corner radius
- **Behavior**: Opens NewOrEditPrompt window with empty fields

### 1.3 Delete Confirmation Dialog
- **Size**: 238x100px
- **Style**: Borderless window, white background, 12px corner radius
- **Shadow**: Black with 0.3 alpha, 3px offset, 8px blur
- **Position**: Bottom-right corner at mouse cursor + 6px
- **Title**: "Are you sure?"
- **Buttons**:
  - **Cancel**: (41, 20), 68x32px, gray border
  - **Delete**: (129, 20), 68x32px, red border, red text
- **Behavior**: Closes dialog and deletes prompt when Delete is clicked

## 2. NewOrEditPrompt Window

### 2.1 Layout
- **Window**: BaseWindow subclass
- **Size**: 600x518 (matches Preferences window size)
- **Position**: 28px right and 28px down from originating window
- **Level**: Modal panel (stays above all other windows)

### 2.2 UI Elements

#### Title Label
- **Position**: (70, windowHeight - 55)
- **Size**: (windowWidth - 90, 30)
- **Text**: "New Prompt" or "Edit Prompt"
- **Font**: Bold system font, 18pt
- **Alignment**: Left

#### Prompt Name Label
- **Position**: (40, windowHeight - 120)
- **Size**: (120, 24)
- **Text**: "Prompt Name"
- **Font**: System font, 14pt
- **Alignment**: Right

#### Prompt Name Field
- **Position**: (160, windowHeight - 120)
- **Size**: (windowWidth - 200, 24)
- **Placeholder**: "Enter Prompt Name"
- **Background**: Light gray (0.1 alpha)
- **Border**: 1px separator color (0.5 alpha), 4px corner radius
- **Tooltip**: "Enter Prompt Name"

#### Prompt Label
- **Position**: (40, windowHeight - 180)
- **Size**: (120, 24)
- **Text**: "Prompt"
- **Font**: System font, 14pt
- **Alignment**: Right

#### Prompt Text Field
- **Position**: (160, 120)
- **Size**: (windowWidth - 200, 240)
- **Background**: Light gray (0.1 alpha)
- **Border**: 1px separator color (0.5 alpha), 4px corner radius
- **Tooltip**: "Markdown format recommended for your prompt"
- **Font**: System font, 14pt
- **Behavior**: Multi-line with scroll view

#### Save Button
- **Position**: (windowWidth - 120, 40)
- **Size**: 100x32px
- **Text**: "Save"
- **Style**: Rounded bezel
- **Behavior**: Validates fields, saves prompt, shows success message, closes window

#### Cancel Button
- **Position**: (windowWidth - 240, 40)
- **Size**: 100x32px
- **Text**: "Cancel"
- **Style**: Rounded bezel
- **Behavior**: Shows cancel message, closes window

#### Close Button
- **Position**: (windowWidth - 30, windowHeight - 30)
- **Size**: 20x20px
- **Icon**: System "xmark"
- **Behavior**: Shows cancel message, closes window

### 2.3 Popup Messages
- **Create New Prompt Canceled**: "Create new prompt canceled, all changes discarded"
- **Edit Prompt Canceled**: "Edit prompt canceled, all changes discarded"
- **Prompt Created Successfully**: "Prompt created successfully"
- **Prompt Updated Successfully**: "Prompt updated successfully"

## 3. Styling Guidelines

### 3.1 Colors
- **Background**: White (#FFFFFF)
- **Text**: System text color
- **Secondary Text**: Secondary label color
- **Borders**: Light gray (with alpha for subtlety)
- **Buttons**:
  - New: Green border
  - Delete: Red border and text
  - Cancel: Gray border
  - Save: Default system button style

### 3.2 Typography
- **Headings**: Bold system font, 16-18pt
- **Labels**: System font, 14pt
- **Small Text**: System font, 12pt
- **Input Fields**: System font, 14pt

### 3.3 Icons
- **Edit**: edit.svg (18x18px)
- **Delete**: delete.svg (18x18px)
- **No background** on buttons, just the icon

## 4. Internationalization
- All text elements use LocalizationService for i18n support
- English and Chinese (Simplified) localizations provided
- Key localization strings include:
  - "first_prompt_default"
  - "prompt_name_column"
  - "prompt_text_column"
  - "edit_button"
  - "delete_button"
  - "new_prompt_title"
  - "edit_prompt_title"
  - "prompt_name_label"
  - "enter_prompt_name_placeholder"
  - "prompt_label"
  - "save_button"
  - "cancel_button"
  - "create_new_prompt_canceled"
  - "edit_prompt_canceled"
  - "prompt_created_successfully"
  - "prompt_updated_successfully"

## 5. Behavior
- **Modal Window**: NewOrEditPrompt opens as a modal window, blocking interaction with other windows
- **Window Positioning**: NewOrEditPrompt positions itself relative to the originating window
- **Text Truncation**: Prompt text is trimmed to 3 lines with "..." for readability
- **Tooltips**: Full text is shown on hover for truncated fields
- **Popup Messages**: Used for user feedback on actions
- **Delete Confirmation**: Required for deleting prompts to prevent accidental actions

## 6. Consistency
- Follows the same design patterns as AIConfigurationTabView
- Uses the same button styles, sizes, and positioning
- Maintains consistent spacing and alignment across components
- Shares the same modal window behavior and popup message system
