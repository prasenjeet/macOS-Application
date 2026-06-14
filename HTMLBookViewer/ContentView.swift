import SwiftUI

// MARK: - Root Navigation

struct ContentView: View {
    @StateObject private var viewModel = BookViewModel()

    var body: some View {
        if viewModel.selectedGroupName == nil {
            NavigationStack {
                BookshelfView(viewModel: viewModel)
            }
        } else {
            NavigationSplitView {
                SidebarView(viewModel: viewModel)
                    .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
            } detail: {
                BookPageView(viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        viewModel.closeBook()
                    } label: {
                        Label("Library", systemImage: "books.vertical")
                    }
                    .help("Back to Library")
                }
            }
        }
    }
}

// MARK: - Bookshelf View

struct BookshelfView: View {
    @ObservedObject var viewModel: BookViewModel

    private static let spineColors: [Color] = [
        Color(red: 0.72, green: 0.20, blue: 0.20),
        Color(red: 0.18, green: 0.38, blue: 0.68),
        Color(red: 0.22, green: 0.55, blue: 0.28),
        Color(red: 0.78, green: 0.45, blue: 0.08),
        Color(red: 0.48, green: 0.18, blue: 0.60),
        Color(red: 0.15, green: 0.48, blue: 0.58),
        Color(red: 0.65, green: 0.22, blue: 0.22),
        Color(red: 0.35, green: 0.22, blue: 0.60),
        Color(red: 0.56, green: 0.34, blue: 0.08),
        Color(red: 0.22, green: 0.50, blue: 0.45),
    ]
    private static let spineWidths:  [CGFloat] = [54, 62, 50, 72, 58, 66, 52, 70, 56, 64]
    private static let spineHeights: [CGFloat] = [205, 225, 190, 215, 235, 198, 220, 208, 185, 230]

    private let booksPerShelf = 6

    private var shelves: [[BookGroup]] {
        stride(from: 0, to: viewModel.bookGroups.count, by: booksPerShelf).map {
            Array(viewModel.bookGroups[$0 ..< min($0 + booksPerShelf, viewModel.bookGroups.count)])
        }
    }

    private func color(at i: Int)  -> Color   { Self.spineColors[i  % Self.spineColors.count]  }
    private func width(at i: Int)  -> CGFloat { Self.spineWidths[i  % Self.spineWidths.count]  }
    private func height(at i: Int) -> CGFloat { Self.spineHeights[i % Self.spineHeights.count] }

    var body: some View {
        ZStack {
            LibraryBackground()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 6) {
                        Text("My Library")
                            .font(.system(size: 38, weight: .bold, design: .serif))
                            .foregroundColor(Color(red: 0.95, green: 0.88, blue: 0.72))
                        Text(viewModel.bookGroups.isEmpty
                             ? "No books found"
                             : "\(viewModel.bookGroups.count) book\(viewModel.bookGroups.count == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.72, green: 0.65, blue: 0.52))
                    }
                    .padding(.top, 44)
                    .padding(.bottom, 40)

                    if viewModel.bookGroups.isEmpty {
                        EmptyShelfView()
                    } else {
                        VStack(spacing: 48) {
                            ForEach(shelves.indices, id: \.self) { shelfIdx in
                                ShelfRow(
                                    groups: shelves[shelfIdx],
                                    startIndex: shelfIdx * booksPerShelf,
                                    colorFn: color(at:),
                                    widthFn:  width(at:),
                                    heightFn: height(at:)
                                ) { group in
                                    viewModel.selectGroup(group.name)
                                }
                            }
                        }
                        .padding(.horizontal, 48)
                        .padding(.bottom, 60)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { viewModel.loadHTMLFiles() } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Color(red: 0.85, green: 0.78, blue: 0.62))
                }
                .help("Refresh library")
            }
        }
        .onAppear {
            if viewModel.bookGroups.isEmpty {
                viewModel.loadHTMLFiles()
            }
        }
    }
}

// MARK: - Library Background

private struct LibraryBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.15, green: 0.10, blue: 0.06)
            // Subtle vertical wood-panel lines
            Canvas { context, size in
                var x: CGFloat = 0
                while x <= size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(.white.opacity(0.03)), lineWidth: 1)
                    x += 80
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Shelf Row (books + wooden plank)

private struct ShelfRow: View {
    let groups: [BookGroup]
    let startIndex: Int
    let colorFn:  (Int) -> Color
    let widthFn:  (Int) -> CGFloat
    let heightFn: (Int) -> CGFloat
    let onSelect: (BookGroup) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(groups.enumerated()), id: \.element.id) { offset, group in
                    let i = startIndex + offset
                    BookSpineView(
                        group: group,
                        color:  colorFn(i),
                        width:  widthFn(i),
                        height: heightFn(i),
                        onTap:  { onSelect(group) }
                    )
                }
                Spacer()
            }
            ShelfPlank()
        }
    }
}

// MARK: - Book Spine

private struct BookSpineView: View {
    let group: BookGroup
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        ZStack {
            // Body with left-to-right gradient for depth
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.75), color, color.opacity(0.88)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Spine binding highlight on the left edge
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 6)
                Spacer()
            }

            // Title — rotated vertically
            Text(group.name)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: height - 30)
                .rotationEffect(.degrees(-90))

            // Page count badge at bottom
            VStack {
                Spacer()
                Text("\(group.pageCount)p")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.bottom, 6)
            }
        }
        .frame(width: width, height: height)
        .shadow(
            color: .black.opacity(isHovered ? 0.55 : 0.40),
            radius: isHovered ? 10 : 6,
            x: 3,
            y: isHovered ? 6 : 4
        )
        .offset(y: isHovered ? -16 : 0)
        .animation(.spring(response: 0.28, dampingFraction: 0.62), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
            hovering ? NSCursor.pointingHand.push() : NSCursor.pop()
        }
        .onTapGesture { onTap() }
    }
}

// MARK: - Wooden Shelf Plank

private struct ShelfPlank: View {
    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.58, green: 0.40, blue: 0.18),
                            Color(red: 0.46, green: 0.30, blue: 0.11),
                            Color(red: 0.50, green: 0.34, blue: 0.14),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            // Top-edge highlight
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 2)
        }
        .frame(height: 18)
        .shadow(color: .black.opacity(0.55), radius: 6, x: 0, y: 5)
    }
}

// MARK: - Empty Shelf

private struct EmptyShelfView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 52))
                .foregroundColor(Color(red: 0.65, green: 0.58, blue: 0.42))
            Text("No books found")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundColor(Color(red: 0.85, green: 0.78, blue: 0.62))
            Text("Place HTML files in your Downloads folder.\nFiles are grouped into books by their first two words.")
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.62, green: 0.56, blue: 0.42))
                .multilineTextAlignment(.center)
            Text("~/Downloads/*.html")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color(red: 0.55, green: 0.50, blue: 0.38))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}
