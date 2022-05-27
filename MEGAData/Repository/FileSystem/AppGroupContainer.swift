import Foundation

struct AppGroupContainer {
    enum Directory: String, CaseIterable {
        case cache = "Library/Caches"
        case shareExtension = "Share Extension Storage"
        case fileExtension = "File Provider Storage"
        case logs = "logs"
        case groupSupport = "GroupSupport"
    }

    private let fileManager: FileManager
    
    static let identifier = "group.mega.ios"
    
    let url: URL
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
        url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Self.identifier)!
    }
    
    func url(for directory: Directory) -> URL {
        url.appendingPathComponent(directory.rawValue, isDirectory: true)
    }
}
