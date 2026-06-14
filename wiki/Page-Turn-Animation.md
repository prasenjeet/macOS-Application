# Page Turn Animation

The page-curl effect is implemented using `CATransition` with the `"pageCurl"` type — a native Core Animation transition available on macOS that physically peels the page away to reveal the next one.

---

## Why Not Pure SwiftUI?

SwiftUI's built-in transitions (`.slide`, `.move`, `.opacity`, custom `ViewModifier`) all run in the compositor and are limited to opacity, position, scale, and blur. A realistic page curl requires Core Animation's layer-rendering pipeline, which can capture a bitmap snapshot of the current layer state and animate it peeling away.

The only way to access Core Animation layers in SwiftUI is via `NSViewRepresentable`.

---

## How CATransition Works

```
┌──────────────────────────────────────────────────────┐
│  Current visual state (old page)                     │
│  captured as CALayer snapshot                        │
└──────────────────────────────────────────────────────┘
                          │
           CATransition registered on layer
                          │
┌──────────────────────────────────────────────────────┐
│  New visual state (new page)                         │
│  rendered after rootView update                      │
└──────────────────────────────────────────────────────┘
                          │
           Core Animation interpolates
           between snapshots with a
           3D page-curl mesh
```

The transition must be registered **before** the content changes. Core Animation captures the current rendered state at the moment of registration, then animates from that snapshot to whatever the layer renders next.

---

## PageTurnContainer Implementation

```swift
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
        view.wantsLayer = true   // ← required for CATransition
        return view
    }

    func updateNSView(_ nsView: NSHostingView<AnyView>, context: Context) {
        if let prev = context.coordinator.previousIndex, prev != displayedIndex {
            let transition = CATransition()
            transition.duration = 0.6
            transition.type = CATransitionType(rawValue: "pageCurl")
            transition.subtype = goingForward ? .fromRight : .fromLeft
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            nsView.layer?.add(transition, forKey: kCATransition)   // register FIRST
        }
        context.coordinator.previousIndex = displayedIndex
        nsView.rootView = AnyView(content())   // then update content
    }
}
```

### Key details

**`wantsLayer = true`** — Opts the `NSView` into Core Animation layer-backing. Without this, `nsView.layer` is `nil` and no transition can be applied.

**`Coordinator.previousIndex`** — Persists across SwiftUI re-renders. By comparing the new `displayedIndex` against `previousIndex`, the transition fires only when the page actually changes — not on every unrelated state update (e.g. hover, focus).

**`previousIndex` starts as `nil`** — The first call to `updateNSView` (initial render) skips the transition because `nil != displayedIndex` is always false in the `if let prev` guard.

**`kCATransition` as the key** — Using the standard `kCATransition` key means only one page transition runs at a time. If another transition is added before the first completes, it replaces it cleanly.

---

## Direction Logic

| User action | `goingForward` | `transition.subtype` | Visual |
|---|---|---|---|
| Next / dot forward / sidebar forward | `true` | `.fromRight` | Right edge of page lifts and curls to the left |
| Previous / dot backward / sidebar backward | `false` | `.fromLeft` | Left edge lifts and curls to the right |

`.fromRight` means the transition originates from the right side of the view — the right edge of the current page peels away, matching the physical motion of turning forward in a book.

---

## displayedIndex vs currentIndex

```
User clicks Next
        │
        ▼
turnPage(to: newIndex, forward: true)
        │
        ├── viewModel.goToPage(newIndex)    ← model updates immediately
        │   (dots, counter show new page)
        │
        ├── goingForward = true
        ├── isAnimating = true
        ├── displayedIndex = newIndex       ← triggers updateNSView
        │   (CATransition fires, content swaps inside the curl)
        │
        └── after 0.65 s:  isAnimating = false
```

`viewModel.currentIndex` (the model) and `displayedIndex` (the view's local state) are intentionally separate:

- The model updates **immediately** so nav dots and the sidebar highlight jump to the new page at once
- The visual card updates **inside the curl** so the user sees the old page curling away before the new one is revealed

---

## Group Switch (No Curl)

When the user opens a different book, we want an **instant** switch, not a curl:

```swift
.onChange(of: viewModel.selectedGroupName) { _ in
    isAnimating = false
    displayedIndex = viewModel.currentIndex
    // no CATransition is registered → no curl
}
```

Because `displayedIndex` is updated before `updateNSView` runs for the `currentIndex` change, the `coordinator.previousIndex == displayedIndex` guard prevents the curl from firing.

---

## Bounds Safety

`content()` is called inside `updateNSView`, which runs outside SwiftUI's render cycle. Between body evaluation and the `updateNSView` call, `viewModel.htmlFiles` may have changed (e.g. a group switch shortened the list). The content closure therefore re-checks bounds:

```swift
PageTurnContainer(displayedIndex: displayedIndex, goingForward: goingForward) {
    if viewModel.htmlFiles.indices.contains(displayedIndex) {   // outer guard (render time)
        PageCard(...)
    }
} // content closure also checks:
// if viewModel.htmlFiles.indices.contains(displayedIndex) { PageCard(...) }
```

Without the inner check, subscripting `viewModel.htmlFiles[displayedIndex]` after a group switch would crash with "Fatal error: Index out of range".
