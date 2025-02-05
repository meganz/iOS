import Foundation
import MEGADomain
import MEGASwift

public final class MockFileSystemRepository: FileSystemRepositoryProtocol, @unchecked Sendable {
    public static let newRepo = MockFileSystemRepository()
    
    private let fileExists: Bool
    private let copiedNode: Bool
    private let movedNode: Bool
    private let containsOriginalsDirectory: Bool
    private let fileSize: UInt64
    private let creationDate: Date
    private let relativePath: String
    private let _offlineDirectoryURL: URL?
    
    @Atomic public var removeFileURLs = [URL]()

    public init(fileExists: Bool = false,
                copiedNode: Bool = false,
                movedNode: Bool = false,
                containsOriginalsDirectory: Bool = false,
                fileSize: UInt64 = 0,
                creationDate: Date = Date(),
                relativePath: String = "relativePath",
                offlineDirectoryURL: URL? = nil) {
        self.fileExists = fileExists
        self.copiedNode = copiedNode
        self.movedNode = movedNode
        self.containsOriginalsDirectory = containsOriginalsDirectory
        self.fileSize = fileSize
        self.creationDate = creationDate
        self.relativePath = relativePath
        _offlineDirectoryURL = offlineDirectoryURL
    }
    
    public func documentsDirectory() -> URL {
        return URL(string: "/Documents") ?? URL(fileURLWithPath: "/Documents")
    }

    public func fileExists(at url: URL) -> Bool {
        fileExists
    }
    
    public func moveFile(at sourceURL: URL, to destinationURL: URL) -> Bool {
        movedNode
    }
    
    public func copyFile(at sourceURL: URL, to destinationURL: URL) -> Bool {
        copiedNode
    }
    
    public func removeItem(at url: URL) throws {
        $removeFileURLs.mutate { $0.append(url) }
    }
    
    public func fileSize(at url: URL) -> UInt64? {
        fileSize
    }
    
    public func fileCreationDate(at url: URL) -> Date? {
        creationDate
    }
    
    public func relativePathToDocumentsDirectory(for url: URL) -> String {
        relativePath
    }
    
    public func removeFolderContents(atURL url: URL) async throws {}
    
    public func offlineDirectoryURL() -> URL? {
        _offlineDirectoryURL
    }
}
