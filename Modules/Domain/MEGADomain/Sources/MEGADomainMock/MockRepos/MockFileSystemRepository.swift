import Foundation
import MEGADomain
import MEGASwift

public final class MockFileSystemRepository: FileSystemRepositoryProtocol, @unchecked Sendable {
    public static let sharedRepo = MockFileSystemRepository()
    
    private let fileExists: Bool
    private let copiedNode: Bool
    private let movedNode: Bool
    private let containsOriginalsDirectory: Bool
    private let fileSize: UInt64
    private let fileCount: Int
    private let directoryContents: [URL]
    /// What `removeItem(at:)` throws instead of recording the removal. `nil` lets every removal succeed.
    private let removeItemError: (any Error)?
    private let creationDate: Date
    private let relativePath: String
    private let _offlineDirectoryURL: URL?
    
    public var removeFolderContents_calledTimes: Int = 0
    
    @Atomic public var removeFileURLs = [URL]()
    /// Every move that was asked for, in call order, so a test can assert what was moved where.
    @Atomic public var movedFiles = [(source: URL, destination: URL)]()

    public init(fileExists: Bool = false,
                copiedNode: Bool = false,
                movedNode: Bool = false,
                containsOriginalsDirectory: Bool = false,
                fileSize: UInt64 = 0,
                fileCount: Int = 0,
                directoryContents: [URL] = [],
                removeItemError: (any Error)? = nil,
                creationDate: Date = Date(),
                relativePath: String = "relativePath",
                offlineDirectoryURL: URL? = nil) {
        self.fileExists = fileExists
        self.copiedNode = copiedNode
        self.movedNode = movedNode
        self.containsOriginalsDirectory = containsOriginalsDirectory
        self.fileSize = fileSize
        self.fileCount = fileCount
        self.directoryContents = directoryContents
        self.removeItemError = removeItemError
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
        $movedFiles.mutate { $0.append((sourceURL, destinationURL)) }
        return movedNode
    }
    
    public func copyFile(at sourceURL: URL, to destinationURL: URL) -> Bool {
        copiedNode
    }
    
    public func removeItem(at url: URL) throws {
        // Recorded before the throw, so a test can tell a removal that was attempted and failed from one
        // that was never asked for.
        $removeFileURLs.mutate { $0.append(url) }
        if let removeItemError {
            throw removeItemError
        }
    }
    
    public func contentsOfDirectory(at url: URL) async -> [URL] {
        directoryContents
    }

    public func fileCount(at url: URL) -> Int {
        fileCount
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
    
    public func removeFolderContents(atURL url: URL) async throws {
        removeFolderContents_calledTimes += 1
    }
    
    public func offlineDirectoryURL() -> URL? {
        _offlineDirectoryURL
    }
}
