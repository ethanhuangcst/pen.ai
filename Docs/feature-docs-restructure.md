# Feature-Based Documentation Restructure Proposal

## Proposed New Structure

```
Docs/
├── Architecture/                    # Cross-cutting technical docs
│   ├── tech-project-structure.md
│   ├── tech-database-structure.md
│   ├── tech-global-objects-architecture.md
│   ├── tech-challenges.md
│   ├── app-distribution-plan.md
│   └── coding-best-practice.md
│
├── Authentication/                  # Login, Registration, Account
│   ├── req-login.md
│   ├── req-accounts.md
│   ├── design-login.md              # NEEDS CREATION
│   ├── design-new-user.md           # NEEDS CREATION
│   ├── ui-login.md                  # NEEDS CREATION
│   └── ui-new-user.md               # NEEDS CREATION
│
├── AI-Integration/                  # AI Manager, Connections, Providers
│   ├── req-ai-connection.md
│   ├── req-ai-model-provider.md
│   ├── design-ai-manager.md
│   └── ui-ai-configuration.md       # NEEDS CREATION
│
├── Pen-Window/                      # Main Pen window functionality
│   ├── req-pen-window.md
│   ├── req-pen-window-behavior.md
│   ├── req-pen-ai-initialization.md
│   ├── req-pen-ai-ui-behaviors.md
│   ├── design-pen-window-service.md
│   ├── ui-pen-window.md
│   ├── tech-text-field-shortcuts.md
│   └── tech-custom-hotkey-design.md
│
├── Menu-Bar/                        # Menu bar icon and behaviors
│   ├── req-menu-bar-icon-behavior.md
│   └── design-menu-bar.md           # NEEDS CREATION
│
├── Preferences/                     # Preferences window and tabs
│   ├── req-preferences.md
│   ├── req-general-settings.md
│   ├── req-shortcut-key.md
│   ├── design-preferences.md        # NEEDS CREATION
│   └── ui-preferences.md            # NEEDS CREATION
│
├── Prompts/                         # Prompt management
│   ├── req-prompts.md
│   ├── req-prompts-ui.md
│   └── design-prompts.md            # NEEDS CREATION
│
├── Content-History/                 # Content enhancement history
│   ├── req-content-history.md
│   └── design-content-history.md
│
├── Settings/                        # System config, light/dark mode
│   ├── req-general-settings.md      # (shared with Preferences)
│   ├── design-system-config-service.md
│   └── design-light-dark-mode.md
│
└── UI-Components/                   # Shared UI components
    ├── ui-style-guide.md
    ├── req-mac-ui.md
    └── tech-clipboard-reference.md
```

---

## Files to Migrate (No Refactoring Needed)

### Architecture Folder
| Current Location | New Location |
|-----------------|--------------|
| `architecture/tech-project-structure.md` | `Architecture/tech-project-structure.md` |
| `architecture/tech-database-structure.md` | `Architecture/tech-database-structure.md` |
| `architecture/tech-global-objects-architecture.md` | `Architecture/tech-global-objects-architecture.md` |
| `architecture/tech-challenges.md` | `Architecture/tech-challenges.md` |
| `architecture/app-distribution-plan.md` | `Architecture/app-distribution-plan.md` |
| `architecture/coding-best-practice.md` | `Architecture/coding-best-practice.md` |

### Authentication Folder
| Current Location | New Location |
|-----------------|--------------|
| `user-stories/req-login.md` | `Authentication/req-login.md` |
| `user-stories/req-accounts.md` | `Authentication/req-accounts.md` |

### AI-Integration Folder
| Current Location | New Location |
|-----------------|--------------|
| `user-stories/req-ai-connection.md` | `AI-Integration/req-ai-connection.md` |
| `user-stories/req-ai-model-provider.md` | `AI-Integration/req-ai-model-provider.md` |
| `tech-design/design-ai-manager.md` | `AI-Integration/design-ai-manager.md` |

### Pen-Window Folder
| Current Location | New Location |
|-----------------|--------------|
| `user-stories/req-pen-window.md` | `Pen-Window/req-pen-window.md` |
| `user-stories/req-pen-window-behavior.md` | `Pen-Window/req-pen-window-behavior.md` |
| `user-stories/req-pen-ai-initialization.md` | `Pen-Window/req-pen-ai-initialization.md` |
| `user-stories/req-pen-ai-ui-behaviors.md` | `Pen-Window/req-pen-ai-ui-behaviors.md` |
| `tech-design/design-pen-window-service.md` | `Pen-Window/design-pen-window-service.md` |
| `tech-design/ui-pen-window.md` | `Pen-Window/ui-pen-window.md` |
| `architecture/tech-text-field-shortcuts.md` | `Pen-Window/tech-text-field-shortcuts.md` |
| `architecture/tech-custom-hotkey-design.md` | `Pen-Window/tech-custom-hotkey-design.md` |

### Menu-Bar Folder
| Current Location | New Location |
|-----------------|--------------|
| `user-stories/req-menu-bar-icon-behavior.md` | `Menu-Bar/req-menu-bar-icon-behavior.md` |

### Preferences Folder
| Current Location | New Location |
|-----------------|--------------|
| `user-stories/req-preferences.md` | `Preferences/req-preferences.md` |
| `user-stories/req-general-settings.md` | `Preferences/req-general-settings.md` |
| `user-stories/req-shortcut-key.md` | `Preferences/req-shortcut-key.md` |

### Prompts Folder
| Current Location | New Location |
|-----------------|--------------|
| `user-stories/req-prompts.md` | `Prompts/req-prompts.md` |
| `user-stories/req-prompts-ui.md` | `Prompts/req-prompts-ui.md` |

### Content-History Folder
| Current Location | New Location |
|-----------------|--------------|
| `user-stories/req-content-history.md` | `Content-History/req-content-history.md` |
| `tech-design/design-content-history.md` | `Content-History/design-content-history.md` |

### Settings Folder
| Current Location | New Location |
|-----------------|--------------|
| `tech-design/design-system-config-service.md` | `Settings/design-system-config-service.md` |
| `tech-design/design-light-dark-mode.md` | `Settings/design-light-dark-mode.md` |

### UI-Components Folder
| Current Location | New Location |
|-----------------|--------------|
| `architecture/ui-style-guide.md` | `UI-Components/ui-style-guide.md` |
| `user-stories/req-mac-ui.md` | `UI-Components/req-mac-ui.md` |
| `architecture/tech-clipboard-reference.md` | `UI-Components/tech-clipboard-reference.md` |

---

## Files Needing Refactoring

### 1. Files to Split

| File | Issue | Action |
|------|-------|--------|
| `req-backend-services.md` | Generic backend doc, unclear feature | create a temporary folder `Backend-Services` |

### 2. Files to Create

| Feature Folder | Missing File | Purpose |
|----------------|--------------|---------|
| Authentication | `design-login.md` | Technical design for login flow |
| Authentication | `design-new-user.md` | Technical design for registration |
| Authentication | `ui-login.md` | UI design for login window |
| Authentication | `ui-new-user.md` | UI design for registration window |
| AI-Integration | `ui-ai-configuration.md` | UI design for AI config tab |
| Menu-Bar | `design-menu-bar.md` | Technical design for menu bar icon |
| Preferences | `design-preferences.md` | Technical design for preferences window |
| Preferences | `ui-preferences.md` | UI design for preferences window |
| Prompts | `design-prompts.md` | Technical design for prompts service |

### 3. Duplicate/Overlapping Content

| Files | Issue | Action |
|-------|-------|--------|
| `req-general-settings.md` | Used in both Preferences and Settings | move content from Preferences to Settings, merge duplicate information |
| `req-pen-window.md` + `req-pen-window-behavior.md` | Overlapping content | Merge into 1 file |

---

## Summary

| Category | Count |
|----------|-------|
| Files to migrate (no changes) | 26 |
| Files to delete | 1 |
| Files to create | 9 |
| Files needing content review | 2 |

---

## Implementation Commands

```bash
# Create new folder structure
mkdir -p /Users/ethanhuang/code/pen.ai/pen/Docs/{Architecture,Authentication,AI-Integration,Pen-Window,Menu-Bar,Preferences,Prompts,Content-History,Settings,UI-Components}

# Move Architecture files
mv /Users/ethanhuang/code/pen.ai/pen/Docs/architecture/tech-project-structure.md /Users/ethanhuang/code/pen.ai/pen/Docs/Architecture/
mv /Users/ethanhuang/code/pen.ai/pen/Docs/architecture/tech-database-structure.md /Users/ethanhuang/code/pen.ai/pen/Docs/Architecture/
# ... (continue for all files)

# Remove old empty folders
rmdir /Users/ethanhuang/code/pen.ai/pen/Docs/architecture
rmdir /Users/ethanhuang/code/pen.ai/pen/Docs/tech-design
rmdir /Users/ethanhuang/code/pen.ai/pen/Docs/user-stories
```

---

## Benefits of New Structure

1. **Feature-Centric**: All docs for a feature in one place
2. **Easier Navigation**: Clear folder names match feature names
3. **Better Organization**: Related docs grouped together
4. **Scalability**: Easy to add new features
5. **Consistency**: Same doc types per feature (req-, design-, ui-)
