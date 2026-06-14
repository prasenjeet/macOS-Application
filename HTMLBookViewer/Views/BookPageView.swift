import SwiftUI
import QuartzCore

struct BookPageView: View {
    @ObservedObject var viewModel: BookViewModel
    @State private var displayedIndex: Int = 0
    @State private var isAnimating: Bool = false
    @State private var goingForward: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.htmlFiles.isEmpty {
                EmptyBookView()
            } else {
                ZStack {
                    BookBackground()
                    if viewModel.htmlFiles.indices.contains(displayedIndex) {
                        PageTurnContainer(
                            displayedIndex: displayedIndex,
                            goingForward: goingForward
                        ) {
                            PageCard(
                                file: viewModel.htmlFiles[displayedIndex],
                                pageNumber: displayedIndex + 1,
                                total: viewModel.totalPages
                            )
                        }
                    }
                }
                .clipped()

                BookNavigationBar(
                    viewModel: viewModel,
                    onPrevious: { turnPage(to: viewModel.currentIndex - 1, forward: false) },
                    onNext: { turnPage(to: viewModel.currentIndex + 1, forward: true) },
                    onGoTo: { index in turnPage(to: index, forward: index > viewModel.currentIndex) }
                )
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { displayedIndex = viewModel.currentIndex }
        .onChange(of: viewModel.selectedGroupName) { _ in
            isAnimating = false
            displayedIndex = viewModel.currentIndex
        }
        .onChange(of: viewModel.currentIndex) { newIndex in
            guard !isAnimating, newIndex != displayedIndex else { return }
            goingForward = newIndex > displayedIndex
            isAnimating = true
            displayedIndex = newIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                isAnimating = false
            }
        }
    }

    private func turnPage(to targetIndex: Int, forward: Bool) {
        guard !isAnimating, viewModel.htmlFiles.indices.contains(targetIndex) else { return }
        goingForward = forward
        isAnimating = true
        viewModel.goToPage(targetIndex)
        displayedIndex = targetIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            isAnimating = false
        }
    }
}

// MARK: - Page Turn Container
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
            transition.duration = 0.6
            transition.type = CATransitionType(rawValue: "pageCurl")
            transition.subtype = goingForward ? .fromRight : .fromLeft
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            nsView.layer?.add(transition, forKey: kCATransition)
        }
        context.coordinator.previousIndex = displayedIndex
        nsView.rootView = AnyView(content())
    }
}

// MARK: - Book Background
private struct BookBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.92, green: 0.88, blue: 0.82),
                Color(red: 0.85, green: 0.80, blue: 0.73)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Canvas { context, size in
                for x in stride(from: 0, through: size.width, by: 4) {
                    for y in stride(from: 0, through: size.height, by: 4) {
                        let dot = Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1))
                        context.fill(dot, with: .color(.black.opacity(0.03)))
                    }
                }
            }
        )
    }
}

// MARK: - Page Card
private struct PageCard: View {
    let file: HTMLFile
    let pageNumber: Int
    let total: Int

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "doc.richtext.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14))
                Text(file.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                Text(file.filename)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.95))

            Divider()

            WebView(url: file.url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack {
                Spacer()
                Text("Page \(pageNumber) of \(total)")
                    .font(.system(size: 11))
                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
                Spacer()
            }
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.9))
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 6)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .overlay(alignment: .trailing) {
            PageEdgeDecoration()
        }
        .padding(.horizontal, 36)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
}

// MARK: - Page Edge Decoration (stacked pages illusion)
private struct PageEdgeDecoration: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack(alignment: .trailing) {
                ForEach([3, 2, 1], id: \.self) { offset in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(white: Double(offset) * 0.05 + 0.88))
                        .frame(width: CGFloat(offset) * 2, height: 40)
                        .offset(x: CGFloat(offset) * 2)
                }
            }
            .padding(.trailing, -4)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Navigation Bar
struct BookNavigationBar: View {
    @ObservedObject var viewModel: BookViewModel
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onGoTo: (Int) -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button {
                onPrevious()
            } label: {
                Label("Previous", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(viewModel.isFirst)
            .keyboardShortcut(.leftArrow, modifiers: .command)

            Spacer()

            if viewModel.totalPages <= 20 {
                HStack(spacing: 7) {
                    ForEach(0..<viewModel.totalPages, id: \.self) { index in
                        Button {
                            onGoTo(index)
                        } label: {
                            Circle()
                                .fill(index == viewModel.currentIndex
                                      ? Color.accentColor
                                      : Color.secondary.opacity(0.28))
                                .frame(
                                    width: index == viewModel.currentIndex ? 10 : 7,
                                    height: index == viewModel.currentIndex ? 10 : 7
                                )
                                .animation(.spring(response: 0.3), value: viewModel.currentIndex)
                        }
                        .buttonStyle(.plain)
                        .help("Go to page \(index + 1)")
                    }
                }
            } else {
                VStack(spacing: 4) {
                    Text("Page \(viewModel.currentIndex + 1) of \(viewModel.totalPages)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    ProgressView(
                        value: Double(viewModel.currentIndex),
                        total: Double(max(viewModel.totalPages - 1, 1))
                    )
                    .frame(width: 140)
                    .tint(.accentColor)
                }
            }

            Spacer()

            Button {
                onNext()
            } label: {
                Label("Next", systemImage: "chevron.right")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(viewModel.isLast)
            .keyboardShortcut(.rightArrow, modifiers: .command)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Divider() }
    }
}

// MARK: - Empty State
private struct EmptyBookView: View {
    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                ForEach([2, 1, 0], id: \.self) { offset in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(white: 0.94 - Double(offset) * 0.03))
                        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                        .frame(width: 120, height: 160)
                        .offset(x: CGFloat(offset) * 4, y: CGFloat(offset) * (-2))
                }
                Image(systemName: "doc.richtext")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor.opacity(0.7))
            }

            VStack(spacing: 8) {
                Text("Library is Empty")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Place HTML files in your Downloads folder.\nFiles are grouped into books by their first two words.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 6) {
                Image(systemName: "folder.badge.questionmark")
                    .foregroundColor(.accentColor)
                Text("~/Downloads/*.html  or  ~/Downloads/*.htm")
                    .font(.system(.callout, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BookBackground())
    }
}
