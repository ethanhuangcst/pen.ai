# Pen App UI Style Guide

## Overview

This style guide defines the visual design and implementation guidelines for the Pen app's user interface, covering both light and dark modes. The design focuses on creating a clean, modern, and user-friendly experience that aligns with macOS design principles.

## Color Palette

### Light Mode

| Color | Hex Code | Usage |
|-------|----------|-------|
| Primary | #007AFF | Buttons, links, primary actions |
| Secondary | #5AC8FA | Secondary buttons, accents |
| Background | #F2F2F7 | Window backgrounds |
| Surface | #FFFFFF | Cards, panels, input fields |
| Text | #000000 | Primary text |
| Text Secondary | #8E8E93 | Secondary text, placeholders |
| Border | #C6C6C8 | Dividers, borders |
| Success | #34C759 | Success messages, indicators |
| Warning | #FF9500 | Warnings, alerts |
| Error | #FF3B30 | Errors, destructive actions |

### Dark Mode

| Color | Hex Code | Usage |
|-------|----------|-------|
| Primary | #0A84FF | Buttons, links, primary actions |
| Secondary | #30B0C7 | Secondary buttons, accents |
| Background | #1C1C1E | Window backgrounds |
| Surface | #2C2C2E | Cards, panels, input fields |
| Text | #FFFFFF | Primary text |
| Text Secondary | #8E8E93 | Secondary text, placeholders |
| Border | #3A3A3C | Dividers, borders |
| Success | #30D158 | Success messages, indicators |
| Warning | #FF9F0A | Warnings, alerts |
| Error | #FF453A | Errors, destructive actions |

## Typography

### Font Family
- Primary: San Francisco (system font)
- Fallback: Helvetica Neue

### Font Sizes

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Large Title | 34pt | Semibold | Window titles, main headers |
| Title 1 | 28pt | Semibold | Section headers |
| Title 2 | 22pt | Semibold | Subsection headers |
| Title 3 | 20pt | Semibold | Smaller headers |
| Headline | 17pt | Semibold | Headings, labels |
| Body | 17pt | Regular | Main body text |
| Callout | 16pt | Regular | Callout text |
| Subhead | 15pt | Regular | Subheadings |
| Footnote | 13pt | Regular | Footnotes, small text |
| Caption 1 | 12pt | Regular | Captions |
| Caption 2 | 11pt | Regular | Smallest text |

## Components

### Buttons

#### Primary Button
- **Light Mode:**
  - Background: #007AFF
  - Text: #FFFFFF
  - Hover: #0066CC
  - Pressed: #0052A3

- **Dark Mode:**
  - Background: #0A84FF
  - Text: #FFFFFF
  - Hover: #007AFF
  - Pressed: #0066CC

#### Secondary Button
- **Light Mode:**
  - Background: #F2F2F7
  - Text: #007AFF
  - Hover: #E5E5EA
  - Pressed: #D1D1D6

- **Dark Mode:**
  - Background: #3A3A3C
  - Text: #0A84FF
  - Hover: #48484A
  - Pressed: #58585A

#### Text Field
- **Light Mode:**
  - Background: #FFFFFF
  - Border: #C6C6C8
  - Focused Border: #007AFF
  - Text: #000000
  - Placeholder: #8E8E93

- **Dark Mode:**
  - Background: #2C2C2E
  - Border: #3A3A3C
  - Focused Border: #0A84FF
  - Text: #FFFFFF
  - Placeholder: #8E8E93

### Labels
- **Light Mode:**
  - Primary: #000000
  - Secondary: #8E8E93

- **Dark Mode:**
  - Primary: #FFFFFF
  - Secondary: #8E8E93

### Panels & Cards
- **Light Mode:**
  - Background: #FFFFFF
  - Border: #C6C6C8
  - Shadow: 0 1px 3px rgba(0, 0, 0, 0.1)

- **Dark Mode:**
  - Background: #2C2C2E
  - Border: #3A3A3C
  - Shadow: 0 1px 3px rgba(0, 0, 0, 0.3)

## Layout

### Spacing

| Size | Value | Usage |
|------|-------|-------|
| XS | 4px | Small gaps, inner padding |
| S | 8px | Regular gaps, padding |
| M | 16px | Section spacing, component padding |
| L | 24px | Major section spacing |
| XL | 32px | Window margins, large containers |

### Corner Radius

| Size | Value | Usage |
|------|-------|-------|
| Small | 4px | Buttons, small components |
| Medium | 8px | Panels, cards, text fields |
| Large | 12px | Windows, large containers |

## Animation

### Transitions
- **Mode Switch:** 0.3s ease-in-out
- **Hover Effects:** 0.2s ease-in-out
- **Focus States:** 0.15s ease-in
- **Modal Transitions:** 0.3s ease-in-out

### Effects
- **Light Mode:** Subtle shadows, minimal animations
- **Dark Mode:** More pronounced shadows, smoother transitions

## Implementation Guidelines

### SwiftUI Code Example

```swift
import SwiftUI

struct CustomButton: View {
    let title: String
    let action: () -> Void
    let primary: Bool
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .foregroundColor(primary ? .white : .accentColor)
                .background(primary ? Color.accentColor : Color(.systemGray6))
                .cornerRadius(8)
                .shadow(radius: 2, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .hoverEffect(.lift)
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .focusedBorder(Color.accentColor, width: 2)
    }
}

struct ContentView: View {
    @State private var text: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to Pen")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            CustomTextField(text: $text, placeholder: "Enter your text here")
            
            HStack(spacing: 12) {
                CustomButton(title: "Cancel", action: { }, primary: false)
                CustomButton(title: "Submit", action: { }, primary: true)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
```

### Dark Mode Support

All views automatically support dark mode by using system colors:

- `Color(.systemBackground)` for backgrounds
- `Color(.label)` for primary text
- `Color(.secondaryLabel)` for secondary text
- `Color(.systemGray6)` for surface elements
- `Color.accentColor` for primary actions

### Accessibility

- Use dynamic type for all text elements
- Ensure sufficient contrast between text and background in both modes
- Support voiceover and other accessibility features
- Test with reduced motion settings

## Conclusion

This style guide provides a comprehensive framework for designing and implementing the Pen app's UI in both light and dark modes. By following these guidelines, we ensure a consistent, modern, and user-friendly experience across all macOS devices and appearance settings.
