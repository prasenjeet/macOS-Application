# HTMLBookViewer Wiki

Welcome to the HTMLBookViewer wiki. HTMLBookViewer is a native macOS app that reads HTML files from `~/Downloads/Claude/`, groups them into books automatically, and presents them in a visual bookshelf you can browse and read.

---

## Quick Navigation

| Page | What you'll find |
|---|---|
| [Architecture](Architecture) | System overview, layer diagram, navigation tree |
| [Swift Workflow](Swift-Workflow) | How the app is structured in Swift — state, data flow, concurrency |
| [Models](Models) | `HTMLFile`, `BookGroup`, `BookViewModel`, `HTMLFileScanner` |
| [Views](Views) | `BookshelfView`, `BookPageView`, `SidebarView`, `WebView` |
| [Page Turn Animation](Page-Turn-Animation) | How `CATransition pageCurl` is wired into SwiftUI |
| [Setup & Configuration](Setup-and-Configuration) | Clone, build, and run |
| [Customisation](Customisation) | Change folder, colours, grouping, animation speed |

---

## App at a Glance

```
 Launch
   │
   ▼
┌─────────────────────────────────────┐
│           My Library                │
│                                     │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐   │  ← BookshelfView
│  │  │ │  │ │  │ │  │ │  │ │  │   │     one spine per BookGroup
│  └──┘ └──┘ └──┘ └──┘ └──┘ └──┘   │
│  ══════════════════════════════     │
│  ┌──┐ ┌──┐                         │
│  │  │ │  │                         │
│  └──┘ └──┘                         │
│  ════════                           │
└──────────────┬──────────────────────┘
               │ tap a spine
               ▼
┌──────────────────────────────────────────────────────┐
│  Sidebar          │  Page reader                     │
│  ─────────────    │  ──────────────────────────────  │
│  ▸ Swift Tutorial │  ┌────────────────────────────┐  │
│    • Chapter 1    │  │  Swift Tutorial · Chapter 1 │  │  ← BookPageView
│    • Chapter 2    │  │  ────────────────────────── │  │     page-curl animation
│    • Chapter 3    │  │  <HTML content via WebKit>  │  │
│  ▸ Python Basics  │  │                             │  │
│    • Intro        │  │  Page 1 of 3                │  │
│    • Variables    │  └─────────────── ◀ ● ○ ○ ▶ ──┘  │
└──────────────────────────────────────────────────────┘
```

---

## Technology Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI Framework | SwiftUI (macOS 13+) |
| Web Rendering | WebKit / `WKWebView` |
| Page Animation | Core Animation (`CATransition`) |
| Architecture | MVVM (`@MainActor ObservableObject`) |
| Build | Xcode 15, no external dependencies |

---

## File Naming Convention → Grouping

Files in `~/Downloads/Claude/` are grouped into books by the first two words of their base filename:

```
swift-tutorial-01.html  →  group "Swift Tutorial"
swift-tutorial-02.html  →  group "Swift Tutorial"
python-basics-intro.html →  group "Python Basics"
readme.html              →  group "Readme"
```

Separators (`-`, `_`, spaces) are all treated as word boundaries.
