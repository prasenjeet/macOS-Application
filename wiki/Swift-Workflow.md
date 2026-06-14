# Swift Workflow

This page documents the key Swift patterns and idioms used throughout the app.

---

## 1. App Entry Point

```swift
// HTMLBookViewerApp.swift
@main
struct HTMLBookViewerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {}  // hide File > New
        }
    }
}
```

`@main` designates the struct as the program entry point. `WindowGroup` handles window lifecycle including state restoration. The `.commands` modifier replaces the default "New Window" menu item with nothing.

---

## 2. MVVM with @MainActor

```swift
// BookViewModel.swift
@MainActor
final class BookViewModel: ObservableObject {
    @Published private(set) var bookGroups: [BookGroup] = []
    @Published private(set) var selectedGroupName: String? = nil
    @Published private(set) var currentIndex: Int = 0
}
```

**Why `@MainActor`?**
- All `@Published` property changes trigger SwiftUI view updates, which must happen on the main thread
- `@MainActor` eliminates all manual `DispatchQueue.main.async` wrapping in the model layer
- `private(set)` keeps writes inside the class while reads are public — views can read, only the ViewModel can write

**Why `final class` not `struct`?**
- `ObservableObject` requires a reference type (`class`)
- `final` prevents subclassing and allows compiler optimisations

---

## 3. Value Types for Data Models

```swift
// HTMLFile.swift
struct HTMLFile: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let displayName: String
    let filename: String
    let bookGroup: String      // derived at init, never changes

    init(url: URL) {
        // All properties set once — fully immutable after init
    }
}

// BookGroup (inside BookViewModel.swift)
struct BookGroup: Identifiable {
    let name: String
    let files: [HTMLFile]
    var id: String { name }
    var pageCount: Int { files.count }
}
```

Using `struct` (value type) for data models gives:
- **Safety** — copies never share mutable state
- **SwiftUI compatibility** — `Equatable` lets SwiftUI diff and skip unnecessary re-renders
- **Identifiable** — required for `ForEach` with stable identity

---

## 4. Computed Properties as Derived State

```swift
// BookViewModel.swift
var selectedGroup: BookGroup? {
    bookGroups.first { $0.name == selectedGroupName }
}

var htmlFiles: [HTMLFile] { selectedGroup?.files ?? [] }
var totalPages: Int        { htmlFiles.count }
var isFirst: Bool          { currentIndex == 0 }
var isLast: Bool           { htmlFiles.isEmpty || currentIndex >= htmlFiles.count - 1 }
```

These computed properties have no stored backing — they derive from `@Published` sources. When any published source changes, SwiftUI re-evaluates any view body that reads these properties.

---

## 5. Navigation via Optional State

```swift
// ContentView.swift
var body: some View {
    if viewModel.selectedGroupName == nil {
        NavigationStack { BookshelfView(viewModel: viewModel) }
    } else {
        NavigationSplitView { SidebarView(...) } detail: { BookPageView(...) }
    }
}
```

A single `String?` drives the entire navigation stack:
- `nil` → bookshelf (no book open)
- non-nil → reader (a book is open)

This avoids an enum or router object. The transition between states is:

```swift
viewModel.selectGroup(name)   // opens a book   → non-nil
viewModel.closeBook()         // returns to shelf → nil
```

---

## 6. @State for Local Animation State

```swift
// BookPageView.swift
struct BookPageView: View {
    @ObservedObject var viewModel: BookViewModel  // shared model
    @State private var displayedIndex: Int = 0    // local to this view
    @State private var isAnimating: Bool = false  // local to this view
    @State private var goingForward: Bool = true  // local to this view
}
```

`displayedIndex` deliberately lags behind `viewModel.currentIndex` during the page-curl animation. This separation is essential: the model updates immediately (so dots/counters reflect the new page), but the visual card only switches at the animation midpoint.

---

## 7. NSViewRepresentable Bridge

```swift
// BookPageView.swift
private struct PageTurnContainer<Content: View>: NSViewRepresentable {
    let displayedIndex: Int
    let goingForward: Bool
    @ViewBuilder let content: () -> Content

    class Coordinator {
        var previousIndex: Int? = nil
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSHostingView<AnyView> {
        let view = NSHostingView(rootView: AnyView(content()))
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSHostingView<AnyView>, context: Context) {
        if let prev = context.coordinator.previousIndex, prev != displayedIndex {
            let transition = CATransition()
            transition.type = CATransitionType(rawValue: "pageCurl")
            transition.subtype = goingForward ? .fromRight : .fromLeft
            transition.duration = 0.6
            nsView.layer?.add(transition, forKey: kCATransition)
        }
        context.coordinator.previousIndex = displayedIndex
        nsView.rootView = AnyView(content())
    }
}
```

`NSViewRepresentable` bridges SwiftUI to AppKit. Key points:
- `makeNSView` — called once, creates the underlying `NSView`
- `updateNSView` — called on every SwiftUI re-render; this is where the transition is applied
- `Coordinator` — persistent object across renders; used to detect index changes
- `wantsLayer = true` — required for Core Animation to work

---

## 8. onChange Handlers for Cross-Cutting Concerns

```swift
// BookPageView.swift
.onChange(of: viewModel.selectedGroupName) { _ in
    // Group switch: reset animation state immediately, no page-curl
    isAnimating = false
    displayedIndex = viewModel.currentIndex
}
.onChange(of: viewModel.currentIndex) { newIndex in
    // External navigation (sidebar tap): play curl if not already animating
    guard !isAnimating, newIndex != displayedIndex else { return }
    goingForward = newIndex > displayedIndex
    isAnimating = true
    displayedIndex = newIndex
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
        isAnimating = false
    }
}
```

`onChange` decouples the animation trigger from the navigation call site. The sidebar, nav buttons, and dot indicators all call the same viewModel methods; `onChange` handles the resulting animation.

The `newIndex != displayedIndex` guard prevents a spurious curl when both `selectedGroupName` and `currentIndex` change together (group switch): the `selectedGroupName` onChange resets `displayedIndex` first, so by the time `currentIndex` onChange fires, the two are equal.

---

## 9. Hover Effects (onHover + NSCursor)

```swift
// ContentView.swift  (BookSpineView)
.onHover { hovering in
    isHovered = hovering
    hovering ? NSCursor.pointingHand.push() : NSCursor.pop()
}
```

SwiftUI's `.onHover` fires when the mouse enters/exits the view frame. `NSCursor.push()` / `pop()` are AppKit APIs that manage the cursor stack — push replaces the system cursor, pop restores the previous one.

---

## 10. @ViewBuilder Closures

```swift
private struct PageTurnContainer<Content: View>: NSViewRepresentable {
    @ViewBuilder let content: () -> Content
```

`@ViewBuilder` allows the caller to pass a multi-statement closure that builds a SwiftUI view, including `if/else` and `ForEach`, without explicit `return`. This is the same attribute used by SwiftUI's own `body` computed property.

---

## 11. AnyType Erasure

```swift
nsView.rootView = AnyView(content())
```

`NSHostingView` is generic (`NSHostingView<Content>`), but the content type changes between pages. `AnyView` erases the concrete type so `NSHostingView<AnyView>` can hold any SwiftUI view. The trade-off is a small runtime cost — acceptable here because this only wraps the active page card.

---

## 12. Static Factory Method for Grouping

```swift
// BookViewModel.swift
private static func makeGroups(from files: [HTMLFile]) -> [BookGroup] {
    var grouped: [String: [HTMLFile]] = [:]
    for file in files {
        grouped[file.bookGroup, default: []].append(file)
    }
    return grouped.keys.sorted().map { BookGroup(name: $0, files: grouped[$0]!) }
}
```

`static` means this function doesn't capture `self` — it's a pure transformation from input to output. `Dictionary(grouping:by:)` could also be used; the explicit loop is equivalent and marginally easier to read.
