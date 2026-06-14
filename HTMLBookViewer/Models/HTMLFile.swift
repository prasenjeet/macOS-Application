import Foundation

struct HTMLFile: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let displayName: String
    let filename: String
    let bookGroup: String

    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.filename = url.lastPathComponent
        let baseName = url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
        self.displayName = baseName.capitalized
        let words = baseName.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        self.bookGroup = words.prefix(2).joined(separator: " ").capitalized
    }
}
