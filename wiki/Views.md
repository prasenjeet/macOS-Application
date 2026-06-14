# Views

All views live in `HTMLBookViewer/` (top-level for `ContentView`) or `HTMLBookViewer/Views/`.

---

## ContentView

**File:** `ContentView.swift`  
**Role:** Root navigation controller + bookshelf UI

### Navigation Switch

```swift
if viewModel.selectedGroupName == nil {
    NavigationStack { BookshelfView(viewModel: viewModel) }
} else {
    NavigationSplitView {
        SidebarView(viewModel: viewModel)
    } detail: {
        BookPageView(viewModel: viewModel)
    }
    .toolbar {
        ToolbarItem(placement: .navigation) {
            Button { viewModel.closeBook() } label: {
                Label("Library", systemImage: "books.vertical")
            }
        }
    }
}
```

### BookshelfView

Also defined in `ContentView.swift`. Renders a dark wood-panelled library wall with coloured book spines.

**Sub-components defined in the same file:**

| Component | Purpose |
|---|---|
| `LibraryBackground` | Dark colour + subtle vertical panel lines via `Canvas` |
| `ShelfRow` | One row of books + the wooden shelf plank beneath |
| `BookSpineView` | Single book spine — gradient rectangle, rotated title, hover lift |
| `ShelfPlank` | Wood-grain gradient rectangle with drop shadow |
| `EmptyShelfView` | Shown when `bookGroups` is empty |

**Book spine layout:**

```
BookSpineView (width × height, varies per book)
├── RoundedRectangle  LinearGradient (left-dark → right-light)
├── Left edge highlight  (white 20% opacity, 6pt wide)
├── Text  rotated -90°  (title, bold, white)
└── Text  page count badge  (bottom, small, monospaced)
```

**Hover animation:**
```swift
.offset(y: isHovered ? -16 : 0)
.shadow(radius: isHovered ? 10 : 6)
.animation(.spring(response: 0.28, dampingFraction: 0.62), value: isHovered)
```

**Books per shelf:** 6 (configurable via `booksPerShelf`). Shelves wrap automatically.

**Colour + size palettes** (10 entries each, index-wrapped):

```
Colours:  deep red, navy, forest green, amber, purple, teal, coral, indigo, brown, sage
Widths:   54, 62, 50, 72, 58, 66, 52, 70, 56, 64  pt
Heights:  205, 225, 190, 215, 235, 198, 220, 208, 185, 230  pt
```

---

## BookPageView

**File:** `Views/BookPageView.swift`  
**Role:** Page reader, animation host, navigation bar

### State

| Property | Default | Purpose |
|---|---|---|
| `displayedIndex` | `0` | Which page `PageTurnContainer` is showing (lags during animation) |
| `isAnimating` | `false` | Locks input during the 0.6 s curl |
| `goingForward` | `true` | Sets `CATransition` subtype direction |

### Sub-components

| Component | Purpose |
|---|---|
| `BookBackground` | Warm linen gradient + stipple dot `Canvas` texture |
| `PageCard` | White card with header strip, `WebView`, footer strip, edge decoration |
| `PageEdgeDecoration` | Three stacked offset rectangles simulating page thickness |
| `PageTurnContainer` | `NSViewRepresentable` — applies `CATransition pageCurl` |
| `BookNavigationBar` | Previous / Next buttons, dot indicators or progress bar |
| `EmptyBookView` | Shown when selected group has no HTML files |

### PageCard Layout

```
PageCard
├── Header  HStack
│   ├── doc.richtext.fill icon
│   ├── displayName  (semibold, 14pt)
│   └── filename  (monospaced, 11pt, secondary)
├── Divider
├── WebView  maxWidth: .infinity  maxHeight: .infinity
├── Divider
└── Footer  HStack
    └── "Page N of M"  (11pt, tertiaryLabel)
```

Styled with: `background(.white)`, `clipShape(RoundedRectangle(cornerRadius: 10))`, two shadow layers, right-edge page decoration overlay.

### Navigation Bar

```
BookNavigationBar
├── Button "Previous"  ⌘←  (disabled when isFirst)
├── Spacer
├── totalPages ≤ 20: HStack of dot Buttons  (filled = current)
│   totalPages > 20: VStack of "Page N of M" + ProgressView
├── Spacer
└── Button "Next"  ⌘→  (disabled when isLast)
```

All three tap targets (Previous, Next, dot) call `turnPage(to:forward:)` which sets direction and delegates to `viewModel.goToPage`.

---

## SidebarView

**File:** `Views/SidebarView.swift`  
**Role:** Per-group table of contents, grouped List

### Structure

```
SidebarView
└── List (.sidebar style)
    └── ForEach bookGroups → Section
        ├── header: BookGroupHeader
        │     book.closed.fill icon · group name · page-count Capsule badge
        │     onTapGesture → viewModel.selectGroup(group.name)
        └── ForEach group.files → SidebarRow
              page number badge · displayName · filename
              onTapGesture:
                  same group → viewModel.goToPage(index)    [triggers flip]
                  diff group → viewModel.selectGroup(name, page: index)  [instant]
```

**Selection highlight:** `listRowBackground` uses `accentColor.opacity(0.12)` for the active row, `Color.clear` otherwise.

**Toolbar:**
- Refresh button (`arrow.clockwise`) → `viewModel.loadHTMLFiles()`

### SidebarRow

```
HStack
├── ZStack  30×30  RoundedRectangle
│   └── page number  (monospaced, 11pt, bold)  white on accentColor / secondary on gray
└── VStack
    ├── displayName  (13pt, semibold if selected)
    └── filename  (11pt, secondary)
```

---

## WebView

**File:** `Views/WebView.swift`  
**Role:** Thin `NSViewRepresentable` wrapper around `WKWebView`

```swift
struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context:) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsMagnification = true
        webView.allowsLinkPreview = false
        return webView
    }

    func updateNSView(_ webView: WKWebView, context:) {
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}
```

**`allowingReadAccessTo`** grants the WebKit sandbox access to the file's parent directory so relative `<img src="...">`, `<link href="...">`, and `<script src="...">` references resolve correctly.

**JavaScript** is enabled so pages with interactive content work out of the box.

**Magnification** is enabled so users can pinch-zoom on a trackpad.
