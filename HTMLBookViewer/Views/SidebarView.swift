import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: BookViewModel

    var body: some View {
        Group {
            if viewModel.htmlFiles.isEmpty {
                SidebarEmptyView()
            } else {
                List(0..<viewModel.htmlFiles.count, id: \.self) { index in
                    SidebarRow(
                        file: viewModel.htmlFiles[index],
                        pageNumber: index + 1,
                        isSelected: index == viewModel.currentIndex
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.goToPage(index)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(index == viewModel.currentIndex
                                  ? Color.accentColor.opacity(0.12)
                                  : Color.clear)
                            .padding(.horizontal, 4)
                    )
                }
                .listStyle(.sidebar)
            }
        }
        .navigationTitle("Contents")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    viewModel.loadHTMLFiles()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh HTML files from Downloads")
            }
        }
    }
}

private struct SidebarRow: View {
    let file: HTMLFile
    let pageNumber: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                    .frame(width: 30, height: 30)
                Text("\(pageNumber)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .white : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(file.displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(file.filename)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }
}

private struct SidebarEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("No pages yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Add HTML files\nto your Downloads")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
