# Models

The model layer lives in `HTMLBookViewer/Models/` and contains three files.

---

## HTMLFile

**File:** `Models/HTMLFile.swift`  
**Type:** `struct` (value type)  
**Protocols:** `Identifiable`, `Equatable`

### Properties

| Property | Type | Description |
|---|---|---|
| `id` | `UUID` | Stable identity for SwiftUI `ForEach` |
| `url` | `URL` | Absolute file URL on disk |
| `filename` | `String` | e.g. `swift-tutorial-01.html` |
| `displayName` | `String` | Human-readable title, e.g. `Swift Tutorial 01` |
| `bookGroup` | `String` | First two words of base name, e.g. `Swift Tutorial` |

### Derivation Logic

```swift
init(url: URL) {
    let baseName = url.deletingPathExtension().lastPathComponent
        .replacingOccurrences(of: "-", with: " ")
        .replacingOccurrences(of: "_", with: " ")

    self.displayName = baseName.capitalized

    let words = baseName.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    self.bookGroup = words.prefix(2).joined(separator: " ").capitalized
}
```

**Examples:**

| Filename | `displayName` | `bookGroup` |
|---|---|---|
| `swift-tutorial-01.html` | `Swift Tutorial 01` | `Swift Tutorial` |
| `python_basics_variables.html` | `Python Basics Variables` | `Python Basics` |
| `readme.html` | `Readme` | `Readme` |
| `a b c.html` | `A B C` | `A B` |

---

## BookGroup

**File:** `Models/BookViewModel.swift` (defined at top of file)  
**Type:** `struct` (value type)  
**Protocols:** `Identifiable`

### Properties

| Property | Type | Description |
|---|---|---|
| `name` | `String` | Shared `bookGroup` value, e.g. `Swift Tutorial` |
| `files` | `[HTMLFile]` | Pages belonging to this book, sorted alphabetically |
| `id` | `String` | Computed from `name` — unique per group |
| `pageCount` | `Int` | Computed from `files.count` |

### Notes

- `id` uses the group name string rather than a `UUID`. This means a `BookGroup` with the same name is considered the same group across reloads, which gives the sidebar stable scroll position when refreshing.

---

## BookViewModel

**File:** `Models/BookViewModel.swift`  
**Type:** `final class` (reference type)  
**Attributes:** `@MainActor`, `ObservableObject`

### Published State

| Property | Type | Meaning |
|---|---|---|
| `bookGroups` | `[BookGroup]` | All books discovered from disk |
| `selectedGroupName` | `String?` | `nil` = bookshelf visible; non-nil = reader open |
| `currentIndex` | `Int` | Active page index within `htmlFiles` |

All three are `@Published private(set)` — observable by views, writable only by the ViewModel.

### Computed Properties

```swift
var selectedGroup: BookGroup?   // bookGroups.first { $0.name == selectedGroupName }
var htmlFiles:     [HTMLFile]   // selectedGroup?.files ?? []
var totalPages:    Int          // htmlFiles.count
var isFirst:       Bool         // currentIndex == 0
var isLast:        Bool         // currentIndex >= htmlFiles.count - 1
var currentFile:   HTMLFile?    // htmlFiles[currentIndex] if in bounds
```

### Mutation Methods

| Method | Effect |
|---|---|
| `loadHTMLFiles()` | Scans disk, rebuilds `bookGroups`, resets to bookshelf (`selectedGroupName = nil`) |
| `selectGroup(_:page:)` | Opens a book at the given page (defaults to page 0) |
| `closeBook()` | Returns to bookshelf (`selectedGroupName = nil`, `currentIndex = 0`) |
| `goToPage(_:)` | Navigates to a page within the current book (bounds-checked) |
| `nextPage()` | Increments `currentIndex` if not on last page |
| `previousPage()` | Decrements `currentIndex` if not on first page |

### Private Methods

```swift
private static func makeGroups(from files: [HTMLFile]) -> [BookGroup]
```

Groups `[HTMLFile]` by `bookGroup` key using a `Dictionary`, then sorts keys alphabetically to produce `[BookGroup]`. Static because it's a pure transformation with no `self` dependency.

---

## HTMLFileScanner

**File:** `Models/HTMLFileScanner.swift`  
**Type:** `struct` with a single static method

### Method

```swift
static func scanDownloads() -> [HTMLFile]
```

**Steps:**
1. Resolves `~/Downloads` via `FileManager.urls(for: .downloadsDirectory, in: .userDomainMask)`
2. Appends `Claude` path component → `~/Downloads/Claude/`
3. Calls `FileManager.contentsOfDirectory(at:includingPropertiesForKeys:options:)`
4. Filters for `.html` and `.htm` extensions (case-insensitive)
5. Sorts results with `localizedCompare` for natural alphabetical order
6. Maps each URL to an `HTMLFile`

**Error handling:** Any `FileManager` error (e.g. folder doesn't exist) is caught, logged to console, and an empty array is returned. The app shows the empty-shelf state in this case.

**Sandbox:** The app's entitlements allow access to `~/Downloads` via `NSDownloadsFolderUsageDescription` in `Info.plist`. The `Claude` subdirectory is accessible because it's inside the granted scope.
