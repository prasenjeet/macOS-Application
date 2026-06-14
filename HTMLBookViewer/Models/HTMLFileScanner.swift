import Foundation

struct HTMLFileScanner {
    static func scanDesktop() -> [HTMLFile] {
        guard let desktopURL = FileManager.default
            .urls(for: .desktopDirectory, in: .userDomainMask)
            .first else {
            return []
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: desktopURL,
                includingPropertiesForKeys: [.isRegularFileKey, .nameKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )

            return contents
                .filter { url in
                    let ext = url.pathExtension.lowercased()
                    return ext == "html" || ext == "htm"
                }
                .sorted { $0.lastPathComponent.localizedCompare($1.lastPathComponent) == .orderedAscending }
                .map { HTMLFile(url: $0) }
        } catch {
            print("[HTMLFileScanner] Error scanning Desktop: \(error.localizedDescription)")
            return []
        }
    }
}
