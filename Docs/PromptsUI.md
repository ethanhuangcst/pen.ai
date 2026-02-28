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
- **Style**: Rounded be