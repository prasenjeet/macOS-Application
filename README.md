# HTMLBookViewer

A macOS app that reads all HTML files from your Desktop and displays them as pages in a book-style reader.

## Features

- **Auto-discovery** — scans `~/Desktop` for `.html` and `.htm` files on launch
- **Book page UI** — each HTML file renders in a card with shadows and page-edge decoration
- **Animated page turns** — smooth slide transitions when navigating between pages
- **Table of contents sidebar** — lists all pages with page numbers; click any row to jump directly
- **Navigation bar** — Previous / Next buttons with dot indicators (up to 20 pages) or a progress bar
- **Keyboard shortcuts** — `⌘ ←` previous page, `⌘ →` next page
- **Refresh button** — reload the Desktop file list at any time from the toolbar
- **WebKit rendering** — full HTML5, CSS3, and JavaScript support in every page

## Requirements

| Requirement | Version |
|---|---|
| macOS | 13.0 Ventura or later |
| Xcode | 15.0 or later |
| Swift | 5.9 or later |

## Setup

1. Clone or download this repository
2. Open `HTMLBookViewer.xcodeproj` in Xcode
3. Select the `HTMLBookViewer` scheme
4. Press `⌘R` to build and run
5. Copy some HTML files to your Mac's Desktop — they appear instantly as book pages

## Quick Test with Sample Files

Three sample HTML files are provided in `SampleHTMLFiles/`. Copy them to your Desktop before running the app:

```bash
cp SampleHTMLFiles/*.html ~/Desktop/
```

## Project Structure

```
HTMLBookViewer.xcodeproj/        Xcode project
HTMLBookViewer/
├── HTMLBookViewerApp.swift      App entry point (@main)
├── ContentView.swift            Root NavigationSplitView
├── Views/
│   ├── SidebarView.swift        Table of contents panel
│   ├── BookPageView.swift       Book display + page animation + nav bar
│   └── WebView.swift            WKWebView (NSViewRepresentable) wrapper
├── Models/
│   ├── HTMLFile.swift           Value type for a discovered HTML file
│   ├── HTMLFileScanner.swift    Scans ~/Desktop for HTML/HTM files
│   └── BookViewModel.swift      @MainActor ObservableObject; state + navigation
├── Assets.xcassets/             App icon + accent colour
├── Info.plist                   NSDesktopFolderUsageDescription key
└── HTMLBookViewer.entitlements  App Sandbox disabled (for Desktop access)
SampleHTMLFiles/                 Demo HTML pages to copy to Desktop
```

## How It Works

`HTMLFileScanner.scanDesktop()` calls `FileManager.contentsOfDirectory` on `~/Desktop`, filters for `.html`/`.htm` extensions, and sorts them alphabetically. The resulting `[HTMLFile]` array is published by `BookViewModel`.

`BookPageView` uses a `ZStack` with `.id(viewModel.currentIndex)` to trigger SwiftUI's transition system. When the page index changes the old view slides out left/right and the new view slides in from the opposite edge, creating the page-turn effect.

`WebView` wraps `WKWebView` via `NSViewRepresentable` and calls `loadFileURL(_:allowingReadAccessTo:)` so the WebView can also load relative assets (images, CSS) that live next to the HTML file.

## Customisation

| What | Where |
|---|---|
| Change deployment target | `project.pbxproj` → `MACOSX_DEPLOYMENT_TARGET` |
| Change bundle ID | `project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER` |
| Scan a different folder | `HTMLFileScanner.swift` → replace `.desktopDirectory` |
| Adjust page-turn speed | `BookPageView.swift` → `.easeInOut(duration: 0.38)` |
| Show both `.html` and `.htm` | Already handled in `HTMLFileScanner.swift` |

## License

MIT — free to use, modify, and distribute.
