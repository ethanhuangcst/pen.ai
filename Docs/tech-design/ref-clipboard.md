Below is practical guidance for reading clipboard content in a SwiftUI macOS app.

This is plain Markdown and safe to copy.

---

# macOS SwiftUI App – Read System Clipboard

On macOS, you use NSPasteboard.

Import AppKit:

import AppKit

---

## 1. Read Plain Text from Clipboard

Create a helper function:

```swift
import AppKit

func readClipboardText() -> String? {
    let pasteboard = NSPasteboard.general
    
    if let items = pasteboard.pasteboardItems {
        for item in items {
            if let text = item.string(forType: .string) {
                return text
            }
        }
    }
    
    return nil
}
```

Simpler version:

```swift
func readClipboardText() -> String? {
    NSPasteboard.general.string(forType: .string)
}
```

---

## 2. Use It in SwiftUI View

Example:

```swift
import SwiftUI
import AppKit

struct ContentView: View {
    @State private var clipboardText: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Clipboard Content:")
            
            TextEditor(text: $clipboardText)
                .frame(height: 200)
            
            Button("Read Clipboard") {
                if let text = readClipboardText() {
                    clipboardText = text
                }
            }
        }
        .padding()
    }
}
```

---

## 3. Auto-Detect Clipboard Changes (Optional)

If you want to monitor clipboard changes continuously:

```swift
class ClipboardMonitor: ObservableObject {
    private var changeCount = NSPasteboard.general.changeCount
    private var timer: Timer?
    
    @Published var clipboardText: String = ""
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let pasteboard = NSPasteboard.general
            
            if pasteboard.changeCount != self.changeCount {
                self.changeCount = pasteboard.changeCount
                self.clipboardText = pasteboard.string(forType: .string) ?? ""
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
}
```

Use in SwiftUI:

```swift
struct ContentView: View {
    @StateObject private var monitor = ClipboardMonitor()
    
    var body: some View {
        TextEditor(text: $monitor.clipboardText)
            .onAppear {
                monitor.startMonitoring()
            }
            .onDisappear {
                monitor.stopMonitoring()
            }
            .padding()
    }
}
```

---

## 4. Read Other Clipboard Types

Read image:

```swift
if let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
    // use image
}
```

Read URL:

```swift
if let url = NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: nil)?.first as? URL {
    // use url
}
```

---

## 5. Permissions

For macOS:
No special entitlement is required to read clipboard in normal desktop apps.

For sandboxed apps:
Make sure App Sandbox is enabled properly in Signing and Capabilities.

---

## 6. If You Are Building iOS Instead

Use UIPasteboard instead:

```swift
import UIKit

let text = UIPasteboard.general.string
```

---

If you tell me:

* macOS or iOS
* sandboxed or not
* need auto monitoring or manual read

I can tailor a cleaner production version for your architecture.
