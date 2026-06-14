import Foundation
import Combine

@MainActor
final class BookViewModel: ObservableObject {
    @Published private(set) var htmlFiles: [HTMLFile] = []
    @Published private(set) var currentIndex: Int = 0

    var currentFile: HTMLFile? {
        guard !htmlFiles.isEmpty, htmlFiles.indices.contains(currentIndex) else { return nil }
        return htmlFiles[currentIndex]
    }

    var totalPages: Int { htmlFiles.count }
    var isFirst: Bool { currentIndex == 0 }
    var isLast: Bool { htmlFiles.isEmpty || currentIndex >= htmlFiles.count - 1 }

    func loadHTMLFiles() {
        htmlFiles = HTMLFileScanner.scanDesktop()
        currentIndex = 0
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
}
