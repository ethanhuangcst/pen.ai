# Pen Project Structure

This document outlines the folder structure for Pen, including ATDD workflow alignment and internationalization (i18n) support.

## Root-Level Structure

```
/pen
├── /mac-app              # Swift/SwiftUI Mac application
├── /web-app              # React/TypeScript web application
├── /backend              # NestJS/TypeScript backend API
├── /docs                 # Project documentation
│   ├── readme.md         # Main project docs
│   ├── project_structure.md # This file
│   ├── /user-stories     # ATDD user stories (Markdown)
│   └── /api              # API documentation
├── /scripts              # CI/CD and deployment scripts
└── /infrastructure       # Cloud infrastructure as code
```

## 1. Mac App (`/mac-app`)

```
/mac-app
├── /Pen
│   ├── /Sources          # Swift source code
│   │   ├── /App          # App entry point
│   │   ├── /Models       # Data models
│   │   ├── /Services     # Network/API services
│   │   ├── /Views        # SwiftUI views
│   │   └── /WebView      # WKWebView integration
│   ├── /Resources        # App resources
│   │   ├── /Strings      # i18n text resources
│   │   │   ├── String Catalog.xcstrings  # Main string catalog
│   │   │   ├── en.lproj/ # English strings
│   │   │   └── zh.lproj/ # Chinese strings
│   │   └── /Assets       # Images, icons, etc.
│   ├── /Tests            # Xcode tests
│   │   ├── /Unit         # Unit tests
│   │   └── /UI           # UI tests
│   ├── Info.plist        # App configuration
│   └── Pen.xcodeproj     # Xcode project file
├── Package.swift         # Swift Package Manager config
└── README.md             # Mac app-specific docs
```

## 2. Web App (`/web-app`)

```
/web-app
├── /public               # Static assets
├── /src                  # React source code
│   ├── /components       # Reusable UI components
│   ├── /pages            # Page-level components
│   ├── /hooks            # Custom React hooks
│   ├── /services         # API client services
│   ├── /locales          # i18n text resources
│   │   ├── en.json       # English translations
│   │   ├── zh.json       # Chinese translations
│   │   └── index.ts      # i18n initialization
│   ├── /context          # React context
│   ├── App.tsx           # App root component
│   └── main.tsx          # App entry point
├── /features             # ATDD feature files (Gherkin)
│   ├── user-registration.feature
│   └── ai-assist.feature
├── /tests                # Test files
│   ├── /unit             # Unit tests
│   ├── /integration      # Integration tests
│   └── /acceptance       # ATDD acceptance tests
├── index.html            # HTML template
├── tsconfig.json         # TypeScript config
├── package.json          # npm dependencies
└── README.md             # Web app-specific docs
```

## 3. Backend (`/backend`)

```
/backend
├── /src                  # NestJS source code
│   ├── /modules          # Feature modules
│   │   ├── /users        # User management
│   │   ├── /ai           # AI integration
│   │   ├── /settings     # User settings/prompts
│   │   └── /auth         # Authentication
│   ├── /config           # Configuration
│   ├── /locales          # i18n text resources
│   │   ├── en/
│   │   │   └── translation.json  # English backend strings
│   │   └── zh/
│   │       └── translation.json  # Chinese backend strings
│   ├── app.module.ts      # Root module
│   └── main.ts            # App entry point
├── /features             # ATDD feature files (Gherkin)
│   ├── user-management.feature
│   └── ai-integration.feature
├── /tests                # Test files
│   ├── /unit             # Unit tests
│   ├── /integration      # Integration tests
│   └── /acceptance       # ATDD acceptance tests
├── /migrations           # Database migrations
├── /seeds                # Database seed data
├── .env.example          # Environment variable template
├── package.json          # npm dependencies
└── README.md             # Backend-specific docs
```

## ATDD Workflow Alignment

| ATDD Step | Location | Purpose |
|-----------|----------|--------|
| **1. Define User Stories** | `/docs/user-stories/` | High-level user requirements in Markdown |
| **2. Write Feature Files** | `/web-app/features/` and `/backend/features/` | Gherkin-style feature files |
| **3. Implement Acceptance Tests** | `/web-app/tests/acceptance/` and `/backend/tests/acceptance/` | Tests based on Gherkin scenarios |
| **4. Develop Feature Code** | `/mac-app/Sources/`, `/web-app/src/`, `/backend/src/` | Implement code to pass tests |
| **5. Run Tests** | CI/CD pipelines | Execute all test types |

## Internationalization (i18n) Resource Locations

### Mac App
- **Location**: `/mac-app/Pen/Resources/Strings/`
- **Format**: Swift String Catalogs (`.xcstrings`)
- **Usage**: `Text("key")` in SwiftUI automatically uses localized strings

### Web App
- **Location**: `/web-app/src/locales/`
- **Format**: JSON files
- **Library**: i18next or react-i18next
- **Usage**: `t("key")` in React components

### Backend
- **Location**: `/backend/src/locales/`
- **Format**: JSON files
- **Library**: nestjs-i18n
- **Usage**: For API error messages and backend-generated text

## Key Considerations

1. **ATDD Integration**: Feature files and acceptance tests are colocated with their respective codebases for better maintainability.

2. **i18n Consistency**: Use the same key naming conventions across all components (e.g., `common.button.submit`).

3. **Scalability**: The structure supports adding new languages, AI models, and features without major refactoring.

4. **Security**: API keys and sensitive configs are stored in environment variables, not in code or i18n files.

5. **Performance**: Optional Redis caching in the backend reduces AI API latency.

6. **Deployment**: Dockerized components for consistent deployment to AliCloud.
