# Pen.ai Coding Best Practices

> A comprehensive guide for developers working on the Pen.ai project, documenting best practices, anti-patterns, and lessons learned from real project experience.

---

## Purpose

This document serves as:
1. **A coding standard** for the Pen.ai development team
2. **A knowledge base** of lessons learned from real debugging sessions
3. **A reference** for onboarding new developers
4. **A skill file** that can be used directly as SKILL.md for AI assistants

---

## File Naming Conventions

### Temporary Files

| Pattern | Example | Purpose |
|---------|---------|---------|
| `tmp-*` | `tmp-test-connection.swift` | Temporary test files, should be deleted |
| `test-*.swift` | `test-history-load.swift` | Standalone test scripts |
| `check-*.swift` | `check-users-table.swift` | Database inspection scripts |
| `Test*.swift` | `TestHistoryLoad.swift` | Unit test files (in Tests directory) |

### Source Files

| Category | Naming Pattern | Example |
|----------|---------------|---------|
| Models | `*Model.swift` | `ContentHistoryModel.swift` |
| Services | `*Service.swift` | `UserService.swift` |
| Views | `*View.swift` or `*Window.swift` | `LoginWindow.swift` |
| Controllers | `*Controller.swift` | (Avoid if possible, use MVVM) |

### Documentation Files

| Pattern | Purpose |
|---------|---------|
| `req-*.md` | Requirements documents |
| `design-*.md` | Design documents |
| `tech-*.md` | Technical documentation |
| `ui-*.md` | UI/UX documentation |

---

## Logging Standards

### Log Format

```swift
// ✅ Good: Structured log with context
print("[ContentHistoryService] Loading history for user: \(userID)")
print("[MySQLConnection] Query returned \(rows.count) rows")
print("[PenWindowService] Clipboard content unchanged, skipping enhancement")

// ❌ Bad: Unstructured logs
print("loading...")
print("error")
print("here")
```

### Log Prefixes

| Prefix | Usage |
|--------|-------|
| `[ClassName]` | Standard class method logs |
| `[MethodName]` | Critical method entry/exit |
| `ERROR:` | Error conditions |
| `WARNING:` | Warning conditions |
| `DEBUG:` | Debug-only information |

### Log Levels

```swift
// Development: Verbose logging for debugging
print("[ContentHistoryService] DEBUG: Row keys: \(row.keys)")

// Production: Essential logs only
print("[ContentHistoryService] Loaded \(count) history items")
```

### Critical Debug Points

Always add logs at:
1. **Database queries** - Print query and parameters
2. **Async operations** - Print start/end
3. **Error handling** - Print error details
4. **State changes** - Print before/after values

```swift
// ✅ Good: Comprehensive logging for debugging
func loadHistoryByUserID(userID: Int, count: Int) async -> Result<[ContentHistoryModel], Error> {
    print("========== ContentHistoryService.loadHistoryByUserID START ==========")
    print("[ContentHistoryService] userID: \(userID), count: \(count)")
    
    do {
        let query = "SELECT * FROM content_history WHERE user_id = ?"
        print("[ContentHistoryService] Executing query: \(query)")
        
        let result = try await connection.execute(query: query, parameters: parameters)
        print("[ContentHistoryService] Query returned \(result.count) rows")
        
        return .success(historyItems)
    } catch {
        print("[ContentHistoryService] ERROR: \(error)")
        return .failure(error)
    }
    
    print("========== ContentHistoryService.loadHistoryByUserID END ==========")
}
```

---

## Database Column Naming

### Critical Rule: Match Model Properties to Database Columns

```swift
// ✅ Good: Property names match database columns exactly
class ContentHistoryModel {
    let enhanceDateTime: Date      // DB: enhance_datetime
    let originalContent: String    // DB: original_content
    let enhancedContent: String    // DB: enhanced_content
    let aiProvider: String         // DB: ai_provider
}

// ❌ Bad: Different names cause confusion and bugs
class ContentHistoryModel {
    let enhancementTime: Date      // DB: enhance_datetime - MISMATCH!
    let inputText: String          // DB: original_content - MISMATCH!
    let outputText: String         // DB: enhanced_content - MISMATCH!
}
```

### Naming Convention

| Database Column | Swift Property | Reason |
|-----------------|----------------|--------|
| `enhance_datetime` | `enhanceDateTime` | snake_case → camelCase |
| `user_id` | `userID` | Consistent transformation |
| `created_at` | `createdAt` | Standard timestamp naming |
| `updated_at` | `updatedAt` | Standard timestamp naming |

### When Extracting from Database

```swift
// ✅ Good: Use exact column names
if let enhanceDatetimeData = row.column("enhance_datetime") {
    rowData["enhance_datetime"] = enhanceDatetimeData
}

// ❌ Bad: Using wrong column name
if let enhanceDatetimeData = row.column("enhancement_time") {  // Column doesn't exist!
    rowData["enhance_datetime"] = enhanceDatetimeData
}
```

### Debug Technique: Print Available Columns

```swift
// Always verify available columns when debugging
if let firstRow = result.first {
    print("[DEBUG] Available columns: \(firstRow.keys)")
}
```

---

## Reducing Complexity

### Function Size

```swift
// ✅ Good: Small, focused functions
func initiatePen() async {
    await loadUserInformation()
    await initializeUIComponents()
    await loadAIConfigurations()
    await loadClipboardAndEnhance()
}

// ❌ Bad: One giant function doing everything
func initiatePen() async {
    // 100+ lines of code doing multiple things
}
```

### Guard Clauses

```swift
// ✅ Good: Early returns reduce nesting
func enhanceText() async {
    guard let window = window else { return }
    guard let selectedPrompt = await getSelectedPrompt() else { return }
    guard let selectedProvider = await getSelectedProvider() else { return }
    guard let originalText = getOriginalText() else { return }
    
    // Main logic here
}

// ❌ Bad: Deep nesting
func enhanceText() async {
    if let window = window {
        if let selectedPrompt = await getSelectedPrompt() {
            if let selectedProvider = await getSelectedProvider() {
                if let originalText = getOriginalText() {
                    // Main logic buried in nesting
                }
            }
        }
    }
}
```

### Single Responsibility

```swift
// ✅ Good: Each function does one thing
func loadUserInformation() async { ... }
func initializeUIComponents() { ... }
func loadAIConfigurations() async { ... }

// ❌ Bad: Function does multiple unrelated things
func loadDataAndSetupUI() async {
    // Loads user data
    // Sets up UI
    // Configures AI
    // Monitors clipboard
}
```

---

## Async/Concurrency Patterns

### Preventing Concurrent Execution

```swift
// ✅ Good: Use flags to prevent concurrent execution
class PenWindowService {
    private var isEnhancing: Bool = false
    
    func enhanceText() async {
        guard !isEnhancing else {
            print("[PenWindowService] Already enhancing, skipping duplicate request")
            return
        }
        
        isEnhancing = true
        defer { isEnhancing = false }
        
        // Enhancement logic
    }
}
```

### Initialization State Management

```swift
// ✅ Good: Track initialization state
class PenWindowService {
    private var isInitializing: Bool = false
    
    func initiatePen() async {
        isInitializing = true
        defer { isInitializing = false }
        
        // Initialization logic
    }
    
    @objc func handleSelectionChanged() {
        guard !isInitializing else {
            print("Skipping during initialization")
            return
        }
        // Handle selection change
    }
}
```

### Avoid Fire-and-Forget Tasks

```swift
// ❌ Bad: Multiple Tasks can run concurrently
func initiatePen() async {
    Task { await enhanceText() }  // Task A
    Task { await enhanceText() }  // Task B - runs concurrently!
}

// ✅ Good: Sequential execution or proper state management
func initiatePen() async {
    await enhanceText()  // Sequential
}
```

---

## Error Handling

### Comprehensive Error Messages

```swift
// ✅ Good: Detailed error context
catch {
    print("[ContentHistoryService] Error loading history: \(error)")
    print("[ContentHistoryService] Query: \(query)")
    print("[ContentHistoryService] Parameters: \(parameters)")
    fflush(stdout)
    return .failure(error)
}

// ❌ Bad: Silent failure
catch {
    return .failure(error)
}
```

### Result Type Usage

```swift
// ✅ Good: Use Result type for async operations
func loadHistoryByUserID(userID: Int) async -> Result<[ContentHistoryModel], Error> {
    do {
        let items = try await fetchItems()
        return .success(items)
    } catch {
        return .failure(error)
    }
}

// Usage:
let result = await service.loadHistoryByUserID(userID: 4)
switch result {
case .success(let items):
    // Handle success
case .failure(let error):
    // Handle error
}
```

---

## Anti-Patterns

### Mistakes Made in This Project

#### 1. Database Column Name Mismatches

**Problem**: Model properties used different names than database columns.

```swift
// ❌ What we did wrong
// Model used: enhancementTime, inputText, outputText
// Database had: enhance_datetime, original_content, enhanced_content
// Result: 8+ hours debugging why data wasn't loading
```

**Solution**: Always match model properties to database columns exactly.

---

#### 2. Concurrent Enhancement Calls

**Problem**: Multiple `Task { await enhanceText() }` blocks created duplicate records.

```swift
// ❌ What caused the bug
func initiatePen() async {
    // Dropdown selection triggers this during initialization
    // Task { await enhanceText() }  // Called 3 times!
}
```

**Solution**: Added `isInitializing` and `isEnhancing` flags.

---

#### 3. Missing Main Menu for Shortcuts

**Problem**: System shortcuts (Cmd+C, Cmd+V) didn't work in text fields.

**Root Cause**: Menu bar apps have no main menu by default, so AppKit has nowhere to route shortcuts.

**Solution**: Install a minimal main menu with Edit menu at app launch.

---

#### 4. Date Format Parsing Failures

**Problem**: MySQL datetime format `2026-03-03 14:50:15 +0000` had a space before timezone.

```swift
// ❌ Failed to parse
formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
// Input: "2026-03-03 14:50:15 +0000"  // Space before +0000
```

**Solution**: Remove space before timezone offset before parsing.

---

#### 5. Unstructured Debug Logs

**Problem**: Logs like `print("here")`, `print("error")` made debugging impossible.

**Solution**: Use structured logging with class/method prefixes.

---

### Other Anti-Patterns to Avoid

#### Magic Numbers

```swift
// ❌ Bad
let frame = NSRect(x: 20, y: 228, width: 338, height: 30)

// ✅ Good
let spacing: CGFloat = 20
let controllerHeight: CGFloat = 30
let frame = NSRect(x: spacing, y: 228, width: 338, height: controllerHeight)
```

#### Hardcoded Strings

```swift
// ❌ Bad
let query = "SELECT * FROM content_history WHERE user_id = ?"

// ✅ Good
let tableName = "content_history"
let query = "SELECT * FROM \(tableName) WHERE user_id = ?"
```

#### Ignoring Optional Safety

```swift
// ❌ Bad
let value = dictionary["key"]!  // Force unwrap

// ✅ Good
if let value = dictionary["key"] {
    // Safe usage
} else {
    print("WARNING: Key not found in dictionary")
}
```

#### Not Cleaning Up Resources

```swift
// ❌ Bad
var monitor: Any?
func startMonitoring() {
    monitor = NSEvent.addLocalMonitorForEvents(...)
}
// No cleanup in deinit

// ✅ Good
deinit {
    if let monitor = monitor {
        NSEvent.removeMonitor(monitor)
    }
}
```

---

## Industry Best Practices

### Code Organization

```
Sources/
├── App/           # App lifecycle, delegates
├── Models/        # Data models
├── Services/      # Business logic, API calls
├── Views/         # UI components
└── Utils/         # Helpers, extensions
```

### Dependency Injection

```swift
// ✅ Good: Dependencies injected
class PenWindowService {
    private let userService: UserService
    private let promptsService: PromptsService
    
    init(userService: UserService, promptsService: PromptsService) {
        self.userService = userService
        self.promptsService = promptsService
    }
}
```

### Protocol-Oriented Design

```swift
// ✅ Good: Protocol for database connections
protocol DatabaseConnection {
    func execute(query: String, parameters: [MySQLData]) async throws -> [[String: Any]]
    func beginTransaction() async throws
    func commitTransaction() async throws
}

class MySQLConnection: DatabaseConnection { ... }
```

### Testing Practices

```swift
// Test file naming: <Class>Tests.swift
class ContentHistoryServiceTests: XCTestCase {
    var sut: ContentHistoryService!
    
    override func setUp() {
        sut = ContentHistoryService()
    }
    
    func testLoadHistoryReturnsCorrectCount() async {
        let result = await sut.loadHistoryByUserID(userID: 1, count: 10)
        // Assert...
    }
}
```

---

## Code Review Checklist

Before submitting code, verify:

- [ ] **Naming**: Do model properties match database columns?
- [ ] **Logging**: Are logs structured with prefixes?
- [ ] **Concurrency**: Are there guards against concurrent execution?
- [ ] **Error Handling**: Are errors logged with context?
- [ ] **Resources**: Are event monitors and timers cleaned up?
- [ ] **Memory**: Are weak self references used in closures?
- [ ] **Optionals**: Are optionals safely unwrapped?
- [ ] **Constants**: Are magic numbers extracted to constants?
- [ ] **i18n**: Are user-facing strings localized?

---

## Quick Reference Card

### Do's

| Practice | Example |
|----------|---------|
| Match DB columns | `enhance_datetime` → `enhanceDateTime` |
| Structured logs | `print("[ClassName] Message")` |
| Guard clauses | `guard let x = x else { return }` |
| State flags | `isEnhancing = true; defer { isEnhancing = false }` |
| Early returns | Return early to reduce nesting |
| Error context | Log query, parameters, and error |

### Don'ts

| Anti-Pattern | Why It's Bad |
|--------------|--------------|
| Different DB/model names | 8+ hours debugging |
| Unstructured logs | Impossible to trace issues |
| Fire-and-forget Tasks | Race conditions, duplicates |
| Force unwrapping | Crashes |
| Magic numbers | Unmaintainable |
| Missing cleanup | Memory leaks |

---

## Document History

| Date | Author | Changes |
|------|--------|---------|
| March 2024 | Dev Team | Initial creation |

---

*This document is a living resource. Update it as new patterns and anti-patterns are discovered.*
