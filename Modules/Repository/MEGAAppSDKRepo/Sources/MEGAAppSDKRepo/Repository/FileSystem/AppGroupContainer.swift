import Foundation

public struct AppGroupContainer: Sendable {
    public enum Directory: String, CaseIterable, Sendable {
        case cache = "Library/Caches"
        case shareExtension = "Share Extension Storage"
        case fileExtension = "File Provider Storage"
        case logs = "logs"
        case groupSupport = "GroupSupport"
    }

    private let fileManager: FileManager
    
    static let identifier = "group.mega.ios"
    
    public let url: URL
    
    public init(fileManager: FileManager) {
        self.fileManager = fileManager
        url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Self.identifier)!
    }
    
    public func url(for directory: Directory) -> URL {
        url.appendingPathComponent(directory.rawValue, isDirectory: true)
    }
}
