# Pen Project Structure

This document outlines the folder structure for Pen, including ATDD workflow alignment and internationalization (i18n) support.

## Root-Level Structure

```
/pen
├── /mac-app              # Swift/AppKit Mac application
├── /backend              # NestJS/TypeScript backend API (minimal use)
├── /Docs                 # Project documentation
│   ├── readme.md         # Main project docs
│   ├── project_structure.md # This file
│   ├── /tech-design      # Technical design documents
│   └── /user-stories     # ATDD user stories (Markdown)
└── /web-app              # (Legacy/Unused) React web app skeleton
```

## 1. Mac App (`/mac-app`)

```
/mac-app
├── /Pen
│   ├── /Sources          # Swift source code
│   │   ├── /App          # App entry point (main.swift, Pen.swift, MainMenu.swift)
│   │   ├── /Models       # Data models (User, Prompt, ContentHistoryModel)
│   │   ├── /Services     # Business logic services
│   │   │   ├── AIManager.swift           # AI provider integration
│   │   │   ├── AuthenticationService.swift # User authentication
│   │   │   ├── BCrypt.swift              # Password hashing
│   │   │   ├── ColorService.swift        # UI color management
│   │   │   ├── ContentHistoryService.swift # Content history management
│   │   │   ├── DatabaseConfig.swift      # Database configuration
│   │   │   ├── DatabaseConnectivityPool.swift # MySQL connection pool
│   │   │   ├── EmailService.swift        # Email sending (password reset)
│   │   │   ├── InitializationService.swift # App initialization
│   │   │   ├── KeychainService.swift     # Secure key storage
│   │   │   ├── LocalizationService.swift # i18n support
│   │   │   ├── PenWindowService.swift    # Pen window management
│   │   │   ├── PromptsService.swift      # Prompts CRUD
│   │   │   ├── ShortcutService.swift     # Keyboard shortcuts
│   │   │   ├── SystemConfigService.swift # System configuration
│   │   │   └── UserService.swift         # User data management
│   │   └── /Views        # AppKit views
│   │       ├── AIConfigurationTabView.swift  # AI connections tab
│   │       ├── AccountTabView.swift          # Account settings tab
│   │       ├── BaseWindow.swift              # Base window class
│   │       ├── ForgotPasswordWindow.swift    # Password reset window
│   │       ├── GeneralTabView.swift          # General settings tab
│   │       ├── HistoryTabView.swift          # Content history tab
│   │       ├── LoginWindow.swift             # Login window
│   │       ├── PreferencesWindow.swift       # Main preferences window
│   │       ├── PromptsTabView.swift          # Prompts management tab
│   │       ├── RegistrationWindow.swift      # New user registration
│   │       └── WindowManager.swift           # Window state management
│   ├── /Resources        # App resources
│   │   ├── /Assets       # Images, icons (icon.png, logo.png, etc.)
│   │   ├── /config       # Configuration files (database.json, email.json)
│   │   ├── en.lproj/     # English localization
│   │   │   └── Localizable.strings
│   │   └── zh-Hans.lproj/ # Chinese (Simplified) localization
│   │       └── Localizable.strings
│   ├── /Tests            # Xcode tests
│   │   ├── DatabaseConnectivityPoolTests.swift
│   │   ├── LoginTests.swift
│   │   ├── ShortcutKeyTests.swift
│   │   └── ... (other test files)
│   ├── Info.plist        # App configuration
│   ├── Package.swift     # Swift Package Manager config
│   └── build-app.sh      # Build script
├── icon.png              # App icon
├── logo.png              # App logo (light mode)
└── logo_dark.png         # App logo (dark mode)
```

## 2. Backend (`/backend`)

```
/backend
├── /src                  # NestJS source code
│   ├── /modules          # Feature modules
│   │   ├── /ai           # AI provider management
│   │   ├── /auth         # Authentication
│   │   ├── /settings     # User settings/prompts
│   │   └── /users        # User management
│   ├── /config           # Configuration
│   ├── app.module.ts     # Root module
│   └── main.ts           # App entry point
├── package.json          # npm dependencies
└── tsconfig.json         # TypeScript config
```

**Note**: The backend is minimal. Most operations are performed by the Mac app connecting directly to MySQL.

## 3. Web App (`/web-app`) - UNUSED

```
/web-app
├── /public               # Static assets
├── /src                  # React source code (skeleton only)
│   ├── /locales          # i18n text resources
│   │   ├── en.json
│   │   └── zh.json
│   ├── App.tsx
│   └── main.tsx
├── index.html
├── package.json
└── tsconfig.json
```

**Note**: The web app is not used in the current architecture. All UI is native AppKit in the Mac app.

## 4. Documentation (`/Docs`)

```
/Docs
├── readme.md             # Main project documentation
├── project_structure.md  # This file
├── /tech-design          # Technical design documents
│   ├── AI_MODEL_PROVIDER.md
│   ├── AI_REFACTORING.md
│   ├── Shortcut_key_design.md
│   ├── UI-Style-Guide.md
│   ├── db_structure.md
│   ├── light-dark-mode.md
│   └── ... (other design docs)
└── /user-stories         # ATDD user stories
    ├── accounts.md
    ├── AI_connection.md
    ├── General.md
    ├── login.md
    ├── Pen-Window.md
    ├── Preferences.md
    ├── prompts.md
    └── ... (other user stories)
```

## ATDD Workflow Alignment

| ATDD Step | Location | Purpose |
|-----------|----------|--------|
| **1. Define User Stories** | `/Docs/user-stories/` | High-level user requirements in Markdown |
| **2. Technical Design** | `/Docs/tech-design/` | Technical specifications and design decisions |
| **3. Implement Code** | `/mac-app/Pen/Sources/` | Swift implementation |
| **4. Write Tests** | `/mac-app/Pen/Tests/` | Xcode unit and UI tests |
| **5. Run Tests** | Xcode / `swift test` | Execute all tests |

## Internationalization (i18n) Resource Locations

### Mac App
- **Location**: `/mac-app/Pen/Resources/en.lproj/` and `/mac-app/Pen/Resources/zh-Hans.lproj/`
- **Format**: `.strings` files (key-value pairs)
- **Usage**: `LocalizationService.shared.localizedString(for: "key")`
- **Runtime Switching**: Supported via `LocalizationService.setLanguage()`

### Example `.strings` file:
```
/* Greeting message */
"hello_user" = "Hello, %@, I'm Pen, your AI writing assistant.";
"save_button" = "Save";
"cancel_button" = "Cancel";
```

## Key Considerations

1. **Direct Database Connection**: Mac app connects directly to MySQL, reducing infrastructure complexity.

2. **i18n Consistency**: Use consistent key naming conventions (e.g., `section_label`, `action_button`).

3. **Scalability**: The architecture supports adding new AI models and features without major refactoring.

4. **Security**: API keys and sensitive configs are stored in database; passwords hashed with BCrypt.

5. **Performance**: Direct database connection reduces latency; no intermediate API layer.

6. **Deployment**: Mac app distributed as .dmg; database hosted on AliCloud RDS.
