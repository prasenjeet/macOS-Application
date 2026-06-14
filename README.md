# HTMLBookViewer

A macOS app that reads HTML files from `~/Downloads/Claude/` and presents them as a visual bookshelf. Files are automatically grouped into books by the first two words of their filename. Tap a book on the shelf to open it and read page-by-page with a native page-curl animation.

---

## Features

| Feature | Detail |
|---|---|
| **Bookshelf UI** | Dark wood-panelled opening screen; each book group is a coloured spine on a shelf |
| **Auto-grouping** | Files are bucketed into books by the first two words of their base filename |
| **Page-curl animation** | Native `CATransition pageCurl` — curls right for Next, left for Previous |
| **Table of contents** | Sidebar lists every book's pages; click any row to jump directly |
| **Navigation bar** | Previous / Next buttons, dot indicators (≤ 20 pages) or a progress bar |
| **Keyboard shortcuts** | `⌘ ←` previous page · `⌘ →` next page |
| **WebKit rendering** | Full HTML5, CSS3, and JavaScript support via `WKWebView` |
| **Refresh** | Toolbar button re-scans `~/Downloads/Claude/` at any time |

---

## Requirements

| Requirement | Version |
|---|---|
| macOS | 13.0 Ventura or later |
| Xcode | 15.0 or later |
| Swift | 5.9 or later |

---

## Setup

```bash
# 1. Clone the repository
git clone <repo-url>

# 2. Create the source folder and add some HTML files
mkdir -p ~/Downloads/Claude
cp SampleHTMLFiles/*.html ~/Downloads/Claude/

# 3. Open in Xcode and run
open HTMLBookViewer.xcodeproj
# Press ⌘R to build and run
```

---

## Project Structure

```
HTMLBookViewer.xcodeproj/
HTMLBookViewer/
├── HTMLBookViewerApp.swift       @main entry point — WindowGroup, min size 960×640
├── ContentView.swift             Root navigation: BookshelfView ↔ reader (NavigationSplitView)
│                                 Also hosts: BookshelfView, BookSpineView, ShelfPlank, EmptyShelfView
├── Views/
│   ├── BookPageView.swift        Page reader, PageTurnContainer (CATransition), BookNavigationBar
│   ├── SidebarView.swift         Per-book table of contents (grouped List sections)
│   └── WebView.swift             WKWebView wrapped as NSViewRepresentable
└── Models/
    ├── HTMLFile.swift            Value type — url, displayName, filename, bookGroup
    ├── HTMLFileScanner.swift     Scans ~/Downloads/Claude/ for .html / .htm files
    └── BookViewModel.swift       @MainActor ObservableObject — BookGroup struct, state, navigation
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      HTMLBookViewerApp (@main)                   │
│                      WindowGroup → ContentView                   │
└───────────────────────────────┬─────────────────────────────────┘
                                │
              selectedGroupName == nil?
                 ┌──────────────┴──────────────┐
                YES                            NO
                 │                              │
    ┌────────────▼────────────┐   ┌─────────────▼──────────────────┐
    │      BookshelfView      │   │      NavigationSplitView        │
    │  (ContentView.swift)    │   │                                 │
    │                         │   │  ┌──────────┐  ┌─────────────┐ │
    │  ┌───┐ ┌───┐ ┌───┐     │   │  │Sidebar   │  │BookPageView │ │
    │  │▓▓▓│ │▓▓▓│ │▓▓▓│     │   │  │View      │  │             │ │
    │  └───┘ └───┘ └───┘     │   │  │(grouped  │  │PageTurn     │ │
    │  ═══════════════════    │   │  │ List)    │  │Container    │ │
    │  ┌───┐ ┌───┐           │   │  └──────────┘  │(CATransition│ │
    │  │▓▓▓│ │▓▓▓│           │   │                │ pageCurl)   │ │
    │  └───┘ └───┘           │   │                └─────────────┘ │
    │  ═══════════════        │   └────────────────────────────────┘
    └────────────┬────────────┘
       tap book  │
                 ▼
        viewModel.selectGroup(name)
```

```
┌──────────────────────────────────────────────────────────────────┐
│                        Data Flow                                  │
│                                                                   │
│  ~/Downloads/Claude/*.html                                        │
│          │                                                        │
│          ▼                                                        │
│  HTMLFileScanner.scanDownloads()                                  │
│          │  FileManager.contentsOfDirectory                       │
│          │  filter .html / .htm                                   │
│          │  sort alphabetically                                   │
│          ▼                                                        │
│  [HTMLFile]  ──── HTMLFile.bookGroup (first 2 words) ────┐       │
│                                                          ▼       │
│  BookViewModel.makeGroups()  ──────────►  [BookGroup]            │
│          │                               name + [HTMLFile]       │
│          │  @Published                                            │
│          ▼                                                        │
│  BookViewModel                                                    │
│  ├── bookGroups:     [BookGroup]   (published)                   │
│  ├── selectedGroupName: String?    (published — nil = shelf)     │
│  └── currentIndex:  Int            (published — page within book)│
│          │                                                        │
│          │  @ObservedObject                                       │
│          ▼                                                        │
│  ContentView ──► BookshelfView  /  SidebarView + BookPageView    │
└──────────────────────────────────────────────────────────────────┘
```

---

## Swift Workflow

### 1 — App Entry (`HTMLBookViewerApp.swift`)

```swift
@main
struct HTMLBookViewerApp: App {
    var body: some Scene {
        WindowGroup { ContentView() .frame(minWidth: 960, minHeight: 640) }
    }
}
```

`@main` designates the app entry point. `WindowGroup` manages the window lifecycle. A minimum size of 960 × 640 pt is enforced so the bookshelf layout is never too cramped.

---

### 2 — Models

#### `HTMLFile` (value type)

```swift
struct HTMLFile: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let displayName: String   // "Swift Tutorial 01"
    let filename: String      // "swift-tutorial-01.html"
    let bookGroup: String     // "Swift Tutorial"  ← first 2 words
}
```

`bookGroup` is derived at init time by splitting the base filename on spaces, hyphens, and underscores, then taking the first two words.

#### `BookGroup` (value type, inside `BookViewModel.swift`)

```swift
struct BookGroup: Identifiable {
    let name: String          // "Swift Tutorial"
    let files: [HTMLFile]
    var id: String { name }
    var pageCount: Int { files.count }
}
```

#### `BookViewModel` (`@MainActor` class)

```
BookViewModel
├── bookGroups:        [BookGroup]    @Published — all books on the shelf
├── selectedGroupName: String?        @Published — nil → shelf, non-nil → reader
├── currentIndex:      Int            @Published — current page within selected book
│
├── htmlFiles          [HTMLFile]     computed — selected book's pages
├── totalPages         Int            computed
├── isFirst / isLast   Bool           computed
│
├── loadHTMLFiles()    scans Downloads/Claude, rebuilds bookGroups, resets to shelf
├── selectGroup(_:page:)              opens a book at a given page
├── closeBook()                       returns to the bookshelf (selectedGroupName = nil)
├── goToPage(_:)                      navigates within the current book
├── nextPage() / previousPage()
└── makeGroups(from:)  [private]      groups [HTMLFile] by bookGroup key
```

---

### 3 — Root Navigation (`ContentView.swift`)

```
selectedGroupName == nil
        │
        ├── YES → BookshelfView (NavigationStack)
        │            toolbar: refresh button
        │            onAppear: loadHTMLFiles() if empty
        │
        └── NO  → NavigationSplitView
                     toolbar: "Library" back button
                     sidebar: SidebarView
                     detail:  BookPageView
```

**Bookshelf rendering pipeline:**

```
bookGroups
    └── split into shelves (6 per row)
            └── ShelfRow
                    ├── HStack(alignment: .bottom)
                    │       └── BookSpineView  ×N
                    │             ├── RoundedRectangle (gradient fill)
                    │             ├── binding highlight (left edge)
                    │             ├── Text rotated -90°  (title)
                    │             ├── page count badge
                    │             └── onHover → lift animation + pointingHand cursor
                    └── ShelfPlank (wood-grain gradient + shadow)
```

---

### 4 — Page Reader (`BookPageView.swift`)

**State:**

| Property | Type | Purpose |
|---|---|---|
| `displayedIndex` | `@State Int` | Which page `PageTurnContainer` currently shows |
| `isAnimating` | `@State Bool` | Prevents double-tap stacking during curl |
| `goingForward` | `@State Bool` | Controls curl direction |

**Page-turn flow:**

```
User taps Next / Previous / dot
        │
        ▼
turnPage(to:forward:)
        ├── guard !isAnimating
        ├── set goingForward
        ├── viewModel.goToPage(targetIndex)   ← updates model immediately
        ├── displayedIndex = targetIndex      ← triggers updateNSView
        └── DispatchQueue.main.asyncAfter(0.65s) → isAnimating = false

onChange(selectedGroupName)
        └── instant reset: isAnimating=false, rotation=0, displayedIndex=currentIndex

onChange(currentIndex)     ← external navigation (sidebar tap)
        ├── guard !isAnimating, newIndex != displayedIndex
        └── performFlipAnimation(to:forward:)
```

**`PageTurnContainer` (NSViewRepresentable):**

```
makeNSView   → NSHostingView<AnyView>  wantsLayer = true
updateNSView → if index changed:
                   CATransition type="pageCurl"
                   subtype = goingForward ? .fromRight : .fromLeft
                   duration = 0.6s  easeInEaseOut
               nsView.layer?.add(transition, forKey: kCATransition)
               nsView.rootView = AnyView(content())   ← triggers visual update
```

---

### 5 — Sidebar (`SidebarView.swift`)

```
List
└── ForEach bookGroups
        └── Section
                ├── header: BookGroupHeader  (book icon · name · page-count badge)
                │             onTapGesture → viewModel.selectGroup(name)
                └── ForEach group.files
                        └── SidebarRow  (page number badge · display name · filename)
                              onTapGesture →
                                  same group → viewModel.goToPage(index)   [flip]
                                  diff group → viewModel.selectGroup(name, page:index) [instant]
```

---

### 6 — WebView (`WebView.swift`)

```swift
struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context:)  → WKWebView  (JS enabled, magnification allowed)
    func updateNSView(webView:) → webView.loadFileURL(url,
                                      allowingReadAccessTo: url.deletingLastPathComponent())
}
```

`allowingReadAccessTo` grants the WebView sandbox access to the file's parent directory, enabling relative `<img>`, `<link>`, and `<script>` references to resolve correctly.

---

## Key Design Decisions

| Decision | Reason |
|---|---|
| `NSViewRepresentable` for page curl | `CATransition "pageCurl"` is a Core Animation type not exposed in SwiftUI |
| `CATransition` on `NSHostingView` | Intercepts the layer's visual update and animates between old and new rendered states |
| `displayedIndex` separate from `currentIndex` | Allows `PageTurnContainer` to show the old page while the curl is in flight |
| `bookGroup` derived at `HTMLFile.init` | Keeps grouping logic close to the data; no extra pass needed |
| Bounds check inside `content()` closure | `updateNSView` fires after SwiftUI renders; `htmlFiles` may have already changed (group switch) |
| `selectedGroupName = nil` as the "shelf" state | A single optional drives the entire navigation stack with no extra enum needed |

---

## Customisation

| What to change | Where |
|---|---|
| Source folder | `HTMLFileScanner.swift` → `claudeURL` path component |
| Books per shelf row | `ContentView.swift` → `booksPerShelf` |
| Spine colours / sizes | `ContentView.swift` → `spineColors`, `spineWidths`, `spineHeights` |
| Page-curl duration | `BookPageView.swift` → `PageTurnContainer.updateNSView` `transition.duration` |
| Grouping logic (N words) | `HTMLFile.swift` → `words.prefix(2)` |
| Deployment target | `project.pbxproj` → `MACOSX_DEPLOYMENT_TARGET` |

---

## License

MIT — free to use, modify, and distribute.
