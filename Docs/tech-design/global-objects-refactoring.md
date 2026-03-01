# Global Objects Refactoring Analysis

## 1. Global Objects Analysis

### Singleton Objects

| Object Name | Can Be Removed | Reason |
|------------|----------------|--------|
| `PenWindowService.shared` | ✅ | Tied to a single window instance, can be managed by PenDelegate |
| `AIManager.shared` | ✅ | Can be instantiated per user session |
| `UserService.shared` | ❌ | Core user state management needed across app |
| `PromptsService.shared` | ✅ | Can be instantiated when needed for specific user |
| `LocalizationService.shared` | ❌ | Global resource needed throughout UI |
| `ShortcutService.shared` | ✅ | Can be instantiated once in app delegate |
| `DatabaseConnectivityPool.shared` | ❌ | Central database connection management |
| `DatabaseConfig.shared` | ❌ | Single source of database configuration |
| `AuthenticationService.shared` | ❌ | Core authentication functionality |
| `InternetConnectivityServiceTest.shared` | ✅ | Test service, can be instantiated when needed |
| `KeychainService.shared` | ❌ | Secure credential storage needed globally |

### Static Properties

| Property Name | Can Be Removed | Reason |
|--------------|----------------|--------|
| `NewOrEditPrompt.isWindowOpen` | ✅ | Can be managed by window instance |
| `NewOrEditPrompt.currentInstance` | ✅ | Can be managed by window management system |
| `BaseWindow.messageQueue` | ❌ | Global message queue needed for popup system |
| `BaseWindow.isDisplayingMessage` | ❌ | Global state for message display coordination |

## 2. Action Items

### PenWindowService
- **New Implementation**: Instantiate as a regular class in PenDelegate, store as a property
- **Impact**: Need to pass reference to other components that need window access
- **Risk**: Low, just changing instantiation method

### AIManager
- **New Implementation**: Instantiate per user session, store in UserService
- **Impact**: Need to update all places that access AIManager.shared to use user-specific instance
- **Risk**: Medium, affects multiple parts of the app

### PromptsService
- **New Implementation**: Instantiate when needed, pass user ID parameter
- **Impact**: Need to update all places that load prompts
- **Risk**: Low, straightforward change

### ShortcutService
- **New Implementation**: Instantiate once in PenDelegate, store as a property
- **Impact**: Minimal, only initialization needs to change
- **Risk**: Low, single responsibility service

### InternetConnectivityServiceTest
- **New Implementation**: Instantiate when needed for connectivity tests
- **Impact**: Minimal, only used in specific test scenarios
- **Risk**: Low, limited usage

### NewOrEditPrompt Static Properties
- **New Implementation**: Move to instance properties, use WindowManager to track instances
- **Impact**: Need to update window management logic
- **Risk**: Low, localized to window management

## 3. Step-by-Step Refactoring Plan

### Phase 1: Prepare Infrastructure
1. **Create WindowManager class** to manage window instances and states
2. **Update dependency injection pattern** for services that will be instantiated per use

### Phase 2: Remove Low-Risk Globals
1. **Refactor InternetConnectivityServiceTest**
   - Remove singleton pattern
   - Instantiate when needed in InitializationService

2. **Refactor ShortcutService**
   - Remove singleton pattern
   - Instantiate in PenDelegate.applicationDidFinishLaunching
   - Store as a property in PenDelegate

### Phase 3: Refactor Medium-Risk Globals
1. **Refactor PenWindowService**
   - Remove singleton pattern
   - Instantiate in PenDelegate.createMainWindow
   - Store as a property in PenDelegate
   - Update all references to use the PenDelegate instance

2. **Refactor PromptsService**
   - Remove singleton pattern
   - Instantiate when needed with user ID parameter
   - Update loadPrompts() calls to pass user ID

### Phase 4: Refactor High-Risk Globals
1. **Refactor AIManager**
   - Remove singleton pattern
   - Add AIManager property to UserService
   - Instantiate when user logs in
   - Update all references to use userService.aiManager

2. **Refactor NewOrEditPrompt static properties**
   - Remove static properties
   - Add instance properties for window state
   - Use WindowManager to track open windows

### Phase 5: Testing and Verification
1. **Run comprehensive tests** for each refactored component
2. **Verify all functionality** remains intact
3. **Check for memory leaks** and performance issues
4. **Update documentation** to reflect new architecture

## 4. Expected Benefits

- **Reduced Global State**: Fewer singletons mean less global state to manage
- **Better Testability**: Easier to mock services in unit tests
- **Clearer Dependency Management**: Explicit dependencies instead of implicit global access
- **Improved Memory Usage**: Services can be deallocated when no longer needed
- **More Flexible Architecture**: Easier to extend and modify services

## 5. Risk Mitigation

- **Incremental Changes**: Refactor one service at a time
- **Comprehensive Testing**: Test each change thoroughly
- **Backup Branches**: Maintain backup branches for each refactoring phase
- **Code Reviews**: Review each refactoring change carefully
- **Rollback Plan**: Prepare rollback steps for each phase

## 6. Conclusion

By refactoring these global objects, we can reduce the complexity of the codebase while maintaining all current functionality. The refactoring plan is designed to minimize risk by taking an incremental approach, starting with low-risk changes and moving to more complex ones. This will result in a more maintainable, testable, and flexible architecture.