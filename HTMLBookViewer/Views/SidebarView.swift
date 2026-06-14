import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: BookViewModel

    var body: some View {
        Group {
            if viewModel.bookGroups.isEmpty {
                SidebarEmptyView()
            } else {
                List {
                    ForEach(viewModel.bookGroups) { group in
                        Section {
                            ForEach(Array(group.files.enumerated()), id: \.element.id) { index, file in
                                let isSelected = viewModel.selectedGroupName == group.name
                                    && viewModel.currentIndex == index
                                SidebarRow(
                                    file: file,
                                    pageNumber: index + 1,
                                    isSelected: isSelected
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if viewModel.selectedGroupName == group.name {
                                        viewModel.goToPage(index)
                                    } else {
                                        viewModel.selectGroup(group.name, page: index)
                                    }
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isSelected
                                              ? Color.accentColor.opacity(0.12)
                                              : Color.clear)
                                        .padding(.horizontal, 4)
                                )
                            }
                        } header: {
                            BookGroupHeader(
                                group: group,
                                isSelected: viewModel.selectedGroupName == group.name
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectGroup(group.name)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .navigationTitle("Library")
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

private struct BookGroupHeader: View {
    let group: BookGroup
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 11))
                .foregroundColor(isSelected ? .accentColor : .secondary)
            Text(group.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .accentColor : .secondary)
            Spacer()
            Text("\(group.pageCount)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
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
            Image(systemName: "books.vertical")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("No books yet")
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
