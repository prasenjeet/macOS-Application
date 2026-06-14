# Customisation

All common customisations require changing a single constant or a few lines.

---

## Change the Source Folder

**File:** `Models/HTMLFileScanner.swift`

```swift
// Current — reads from ~/Downloads/Claude/
let claudeURL = downloadsURL.appendingPathComponent("Claude", isDirectory: true)

// Change to ~/Downloads/MyBooks/
let claudeURL = downloadsURL.appendingPathComponent("MyBooks", isDirectory: true)

// Change to ~/Documents/
guard let claudeURL = FileManager.default
    .urls(for: .documentDirectory, in: .userDomainMask).first else { return [] }
```

Also update the usage description in `Info.plist` so the system permission dialog shows the correct folder name.

---

## Change the Grouping Logic

**File:** `Models/HTMLFile.swift`

```swift
// Current — first 2 words
self.bookGroup = words.prefix(2).joined(separator: " ").capitalized

// First word only (one book per prefix word)
self.bookGroup = words.first?.capitalized ?? "Ungrouped"

// First 3 words
self.bookGroup = words.prefix(3).joined(separator: " ").capitalized

// Use the entire filename as the group (no grouping)
self.bookGroup = self.displayName
```

---

## Change Books Per Shelf Row

**File:** `ContentView.swift`

```swift
// Current
private let booksPerShelf = 6

// Wider shelves
private let booksPerShelf = 8

// Single book per shelf
private let booksPerShelf = 1
```

---

## Change Spine Colours

**File:** `ContentView.swift`

```swift
private static let spineColors: [Color] = [
    Color(red: 0.72, green: 0.20, blue: 0.20),   // deep red
    Color(red: 0.18, green: 0.38, blue: 0.68),   // navy
    // add, remove, or replace any entry
    // colours are assigned by index, wrapping around if there are more books than colours
]
```

You can also use named colours from `Assets.xcassets` if you add them there:
```swift
Color("MyCustomRed")
```

---

## Change Spine Dimensions

**File:** `ContentView.swift`

```swift
private static let spineWidths:  [CGFloat] = [54, 62, 50, 72, 58, 66, 52, 70, 56, 64]
private static let spineHeights: [CGFloat] = [205, 225, 190, 215, 235, 198, 220, 208, 185, 230]
```

Values are in points. Widths control the spine thickness; heights control how tall books appear on the shelf.

---

## Change Page-Curl Speed

**File:** `Views/BookPageView.swift` — inside `PageTurnContainer.updateNSView`

```swift
transition.duration = 0.6   // seconds — decrease for snappier, increase for slower

// Also update the isAnimating lock timer to match:
DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {   // slightly longer than duration
    isAnimating = false
}
```

---

## Change Hover Lift Amount

**File:** `ContentView.swift` — inside `BookSpineView`

```swift
.offset(y: isHovered ? -16 : 0)   // increase for more dramatic lift, 0 to disable
```

---

## Change the Background Colour

**File:** `ContentView.swift` — inside `LibraryBackground`

```swift
// Current — dark walnut
Color(red: 0.15, green: 0.10, blue: 0.06)

// Light library
Color(red: 0.94, green: 0.90, blue: 0.82)

// Use a system colour
Color(NSColor.windowBackgroundColor)
```

---

## Change Minimum Window Size

**File:** `HTMLBookViewerApp.swift`

```swift
ContentView()
    .frame(minWidth: 960, minHeight: 640)   // change as needed
```

---

## Disable JavaScript in WebView

**File:** `Views/WebView.swift`

```swift
preferences.allowsContentJavaScript = false   // change true to false
```

---

## Enable Subdirectory Scanning

**File:** `Models/HTMLFileScanner.swift`

Replace `contentsOfDirectory` with a recursive `enumerator`:

```swift
let enumerator = FileManager.default.enumerator(
    at: claudeURL,
    includingPropertiesForKeys: [.isRegularFileKey],
    options: [.skipsHiddenFiles]
)
let urls = (enumerator?.allObjects as? [URL]) ?? []
return urls
    .filter { ["html", "htm"].contains($0.pathExtension.lowercased()) }
    .sorted { $0.lastPathComponent.localizedCompare($1.lastPathComponent) == .orderedAscending }
    .map { HTMLFile(url: $0) }
```
