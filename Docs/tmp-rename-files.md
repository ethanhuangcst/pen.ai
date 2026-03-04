# Document Renaming Proposal

## Naming Convention Rules

| Folder | Prefix | Example |
|--------|--------|---------|
| user-stories | `req-` | req-login.md |
| architecture | `tech-` | tech-database-structure.md |
| tech-design | `design-` | design-ai-manager.md |
| UI-related docs | `ui-` | ui-style-guide.md |

**Rules:**
- All lowercase
- Use hyphen `-` instead of underscore `_`
- Meaningful, readable names

---

## Root Level Files (`/Docs`)

| Current Name | Proposed Name | Notes |
|--------------|---------------|-------|
| readme.md | readme.md | Keep as is (main doc) |
| project_structure.md | tech-project-structure.md | Move to architecture folder |
| ai_diagnose.md | (delete) | Temporary diagnostic file |
| clean-log.md | (delete) | Temporary log file |
| diagnose.txt | (delete) | Temporary diagnostic file |

---

## Architecture Folder (`/Docs/architecture`)

| Current Name | Proposed Name |
|--------------|---------------|
| db_structure.md | tech-database-structure.md |
| global-objects.md | tech-global-objects.md |
| global-objects-refactoring.md | tech-global-objects-refactoring.md |
| recognize_CMD_A.md | tech-recognize-cmd-a.md |
| ref-clipboard.md | tech-clipboard-reference.md |
| Shortcut_key_design.md | tech-shortcut-key-design.md |
| System_Shortcut_Support.md | tech-system-shortcut-support.md |
| tech-challenges.md | tech-challenges.md |
| UI-Style-Guide.md | ui-style-guide.md |

---

## Tech-Design Folder (`/Docs/tech-design`)

| Current Name | Proposed Name |
|--------------|---------------|
| AI_MODEL_PROVIDER.md | design-ai-model-provider.md |
| AI_REFACTORING.md | design-ai-refactoring.md |
| aiManager.md | design-ai-manager.md |
| design-content-history.md | design-content-history.md |
| design_PenWindowService.md | design-pen-window-service.md |
| light-dark-mode.md | design-light-dark-mode.md |
| pen_window_ui.md | ui-pen-window.md |
| system-config-service.md | design-system-config-service.md |

---

## User-Stories Folder (`/Docs/user-stories`)

| Current Name | Proposed Name |
|--------------|---------------|
| AI_Model_Provider.md | req-ai-model-provider.md |
| AI_connection.md | req-ai-connection.md |
| accounts.md | req-accounts.md |
| back-end-services.md | req-backend-services.md |
| General.md | req-general-settings.md |
| login.md | req-login.md |
| mac-UI.md | req-mac-ui.md |
| menu-bar-icon-behaior.md | req-menu-bar-icon-behavior.md |
| Pen-Window.md | req-pen-window.md |
| PenAI-Initialization.md | req-pen-ai-initialization.md |
| PenAI-UI-behaviors.md | req-pen-ai-ui-behaviors.md |
| Pen_window_behavior.md | req-pen-window-behavior.md |
| Preferences.md | req-preferences.md |
| prompts.md | req-prompts.md |
| PromptsUI.md | req-prompts-ui.md |
| req-content-history.md | req-content-history.md |
| shortcut-key.md | req-shortcut-key.md |
| promtps | (delete) | Typo/empty folder |

---

## Summary

| Category | Count |
|----------|-------|
| Files to rename | 34 |
| Files to delete | 4 |
| Files to keep unchanged | 1 |

---

## Implementation Commands

```bash
# Create new architecture folder structure
mkdir -p /Users/ethanhuang/code/pen.ai/pen/Docs/architecture

# Move project_structure.md to architecture
mv /Users/ethanhuang/code/pen.ai/pen/Docs/project_structure.md /Users/ethanhuang/code/pen.ai/pen/Docs/architecture/tech-project-structure.md

# Delete temporary files
rm /Users/ethanhuang/code/pen.ai/pen/Docs/ai_diagnose.md
rm /Users/ethanhuang/code/pen.ai/pen/Docs/clean-log.md
rm /Users/ethanhuang/code/pen.ai/pen/Docs/diagnose.txt
rm -rf /Users/ethanhuang/code/pen.ai/pen/Docs/user-stories/promtps
```
