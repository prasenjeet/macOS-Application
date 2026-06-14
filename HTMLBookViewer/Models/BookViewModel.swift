import Foundation
import Combine

struct BookGroup: Identifiable {
    let name: String
    let files: [HTMLFile]

    var id: String { name }
    var pageCount: Int { files.count }
}

@MainActor
final class BookViewModel: ObservableObject {
    @Published private(set) var bookGroups: [BookGroup] = []
    @Published private(set) var selectedGroupName: String? = nil
    @Published private(set) var currentIndex: Int = 0

    var selectedGroup: BookGroup? {
        bookGroups.first { $0.name == selectedGroupName }
    }

    var htmlFiles: [HTMLFile] { selectedGroup?.files ?? [] }
    var totalPages: Int { htmlFiles.count }
    var isFirst: Bool { currentIndex == 0 }
    var isLast: Bool { htmlFiles.isEmpty || currentIndex >= htmlFiles.count - 1 }

    var currentFile: HTMLFile? {
        guard htmlFiles.indices.contains(currentIndex) else { return nil }
        return htmlFiles[currentIndex]
    }

    func loadHTMLFiles() {
        let files = HTMLFileScanner.scanDownloads()
        bookGroups = Self.makeGroups(from: files)
        selectedGroupName = nil   // always start at bookshelf
        currentIndex = 0
    }

    func closeBook() {
        selectedGroupName = nil
        currentIndex = 0
    }

    func selectGroup(_ name: String, page: Int = 0) {
        selectedGroupName = name
        currentIndex = page
    }

    func nextPage() {
        guard !isLast else { return }
        currentIndex += 1
    }

    func previousPage() {
        guard !isFirst else { return }
        currentIndex -= 1
    }

    func goToPage(_ index: Int) {
        guard htmlFiles.indices.contains(index) else { return }
        currentIndex = index
    }

    private static func makeGroups(from files: [HTMLFile]) -> [BookGroup] {
        var grouped: [String: [HTMLFile]] = [:]
        for file in files {
            grouped[file.bookGroup, default: []].append(file)
        }
        return grouped.keys.sorted().map { BookGroup(name: $0, files: grouped[$0]!) }
    }
}
