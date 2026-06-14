import Foundation

struct BookGroup: Identifiable {
    let name: String
    let files: [HTMLFile]

    var id: String { name }
    var pageCount: Int { files.count }
}
