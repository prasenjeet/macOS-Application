import Foundation

struct HTMLFile: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let displayName: String
    let filename: String

    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.filename = url.lastPathComponent
        self.displayName = url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}
