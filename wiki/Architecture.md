# Architecture

## Layer Overview

```
┌─────────────────────────────────────────────────────────┐
│                   App Entry Point                        │
│            HTMLBookViewerApp  (@main)                    │
│         WindowGroup  min 960×640  titleBar toolbar       │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                    ContentView                           │
│   Owns @StateObject BookViewModel                        │
│                                                          │
│   selectedGroupName == nil ──► NavigationStack           │
│                                    └─► BookshelfView     │
│                                                          │
│   selectedGroupName != nil ──► NavigationSplitView       │
│                                    ├─► SidebarView       │
│                                    └─► BookPageView      │
└───────────────────────┬─────────────────────────────────┘
                        │ @ObservedObject
                        ▼
┌─────────────────────────────────────────────────────────┐
│                   BookViewModel                          │
│   @MainActor  ObservableObject                           │
│                                                          │
│   @Published bookGroups:       [BookGroup]               │
│   @Published selectedGroupName: String?                  │
│   @Published currentIndex:      Int                      │
│                                                          │
│   Computed:  htmlFiles, totalPages, isFirst, isLast      │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                      Models                             │
│                                                          │
│   HTMLFileScanner  ──► [HTMLFile]  ──► [BookGroup]       │
│   (file system)        (value type)    (value type)      │
└─────────────────────────────────────────────────────────┘
```

---

## Navigation State Machine

```
          ┌─────────────────────┐
          │      Bookshelf      │◄──── app launch
          │  (selectedGroup nil)│◄──── "Library" button
          └──────────┬──────────┘
                     │
          viewModel.selectGroup(name)
          (tap book spine)
                     │
                     ▼
          ┌─────────────────────┐
          │      Reader         │
          │ NavigationSplitView │
          │  Sidebar │ PageView │
          └──────────┬──────────┘
                     │
          viewModel.closeBook()
          (tap "Library" in toolbar)
                     │
                     └──────────► Bookshelf
```

---

## Data Flow

```
~/Downloads/Claude/
        │
        │  FileManager.contentsOfDirectory
        ▼
HTMLFileScanner.scanDownloads()
        │
        │  filter .html / .htm
        │  sort alphabetically
        ▼
[HTMLFile]          id · url · filename · displayName · bookGroup
        │
        │  BookViewModel.makeGroups(from:)
        │  Dictionary keyed by bookGroup, then sorted
        ▼
[BookGroup]         name · files: [HTMLFile] · pageCount
        │
        │  @Published  →  view re-renders
        ▼
BookViewModel       source of truth for all UI state
        │
        │  @ObservedObject (ContentView, SidebarView, BookPageView, BookshelfView)
        ▼
Views               read state, call mutation methods
```

---

## View Hierarchy

```
ContentView
├── BookshelfView  (when selectedGroupName == nil)
│   ├── LibraryBackground
│   ├── ScrollView
│   │   ├── Header  (title + book count)
│   │   └── ForEach shelves
│   │       └── ShelfRow
│   │           ├── HStack(alignment: .bottom)
│   │           │   └── BookSpineView  ×N
│   │           │       ├── gradient RoundedRectangle
│   │           │       ├── binding highlight
│   │           │       ├── rotated title Text
│   │           │       └── page count badge
│   │           └── ShelfPlank
│   └── EmptyShelfView  (when bookGroups is empty)
│
└── NavigationSplitView  (when selectedGroupName != nil)
    ├── SidebarView  (sidebar column)
    │   └── List
    │       └── ForEach bookGroups → Section
    │           ├── BookGroupHeader
    │           └── SidebarRow  ×N
    │
    └── BookPageView  (detail column)
        ├── BookBackground
        ├── PageTurnContainer  (NSViewRepresentable)
        │   └── NSHostingView → PageCard
        │       ├── header strip
        │       ├── WebView  (WKWebView)
        │       └── footer strip
        ├── BookNavigationBar
        │   ├── Previous button  (⌘←)
        │   ├── Dot indicators / ProgressView
        │   └── Next button  (⌘→)
        └── EmptyBookView  (when htmlFiles is empty)
```

---

## Concurrency Model

All model mutations happen on `@MainActor`. The `BookViewModel` class is annotated `@MainActor` which guarantees:

- All `@Published` property changes fire on the main thread
- All view updates are automatically on the main thread
- No manual `DispatchQueue.main.async` is needed except for animation timing delays

The only non-actor boundary is `DispatchQueue.main.asyncAfter` used in `BookPageView` to reset `isAnimating` after the 0.6 s `CATransition` completes. This is safe because `asyncAfter` on `.main` inherits `@MainActor` isolation at the call site.

---

## Dependency Graph

```
HTMLBookViewerApp
    └── ContentView
            ├── BookViewModel  ◄── owns
            ├── BookshelfView  ◄── observes BookViewModel
            ├── SidebarView    ◄── observes BookViewModel
            └── BookPageView   ◄── observes BookViewModel
                    └── PageTurnContainer
                            └── NSHostingView
                                    └── PageCard
                                            └── WebView
                                                    └── WKWebView
```

No external dependencies. The app uses only Apple frameworks: SwiftUI, WebKit, QuartzCore, Foundation.
