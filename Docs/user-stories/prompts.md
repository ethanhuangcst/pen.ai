# Feature: Default Prompt for All Users

## User Story 1: Default Prompt Definition
As a Pen user
I want a default prompt to be available for all users
So that I have a starting point for AI interactions without needing to create my own prompt

### Acceptance Criteria

Scenario: Default Prompt is loaded from default_prompt.md
  Given the application is running
  And default_prompt.md exists in the same folder as KeyChain
  When the application initializes
  Then it should load the default prompt from default_prompt.md
  And it should assign a special ID (e.g., DEFAULT) to the default prompt
  And the special ID should be defined as a constant, not hard-coded
  And the default prompt should be available for all users


## User Story 2: Default Prompt Cannot Be Deleted
As a Pen user
I want the default prompt to always be available and not deletable
So that I always have a fallback prompt option

### Acceptance Criteria

Scenario: Default Prompt is displayed at the top of the prompts list
  Given the user is logged in
  And the user navigates to Preferences - Prompts tab
  When the prompts list loads
  Then the default prompt should be displayed at the top of the list

Scenario: Delete button for Default Prompt is disabled
  Given the user is logged in
  And the user navigates to Preferences - Prompts tab
  When the prompts list loads
  Then the delete button for the default prompt should be disabled
  And mouse hover over the delete button should show a tooltip indicating "Default prompt cannot be deleted"
  And the edit button for the default prompt should be enabled

Scenario: Attempting to delete Default Prompt shows error
  Given the user is logged in
  And the user navigates to Preferences - Prompts tab
  When the user attempts to delete the default prompt
  Then it should display an error message: "Default prompt cannot be deleted"
  And the default prompt should remain in the list

Scenario: Default Prompt is created if missing for user
  Given the user is logged in
  And the user does not have a default prompt in their prompts list
  When the user navigates to Preferences - Prompts tab
  Then the system should automatically create the default prompt for the user
  And the default prompt should be loaded from default_prompt.md
  And the default prompt should be displayed at the top of the prompts list
  And the delete button for the default prompt should be disabled



## Technical Requirements

1. **Default Prompt ID**: Use a constant for the special ID (e.g., DEFAULT) instead of hard-coding
2. **File Location**: default_prompt.md should be placed in the same folder as KeyChain: pen/mac-app/Pen
3. **UI Behavior**: Default prompt should always appear at the top of the prompts list with disabled delete button
4. **Error Handling**: Attempts to delete the default prompt should be rejected with an appropriate error message
5. **New User Onboarding**: Default prompt should be automatically created for new users
6. **Fallback Mechanism**: If default_prompt.md is missing, a predefined default prompt should be created

## Default Prompt Structure

The default_prompt.md file should contain:
- Prompt name: A clear, descriptive name for the default prompt
- Prompt content: A well-crafted prompt that provides a good starting point for AI interactions

Example structure:
```
# Default Prompt Name

## Prompt Content
Your default prompt content goes here. This should be a versatile prompt that works well for general AI interactions.
```