import Foundation
import MEGADomain

public struct MockFileSystemRepository: FileSystemRepositoryProtocol {
    public static let newRepo = MockFileSystemRepository()
    
    private let sizeAvailability: Int64
    private let fileExists: Bool
    private let copiedNode: Bool
    private let movedNode: Bool
    private let containsOriginalsDirectory: Bool
    private let fileSize: UInt64
    private let creationDate: Date

    public init(sizeAvailability: Int64 = 0,
                fileExists: Bool = false,
                copiedNode: Bool = false,
                movedNode: Bool = false,
                containsOriginalsDirectory: Bool = false,
                fileSize: UInt64 = 0,
                creationDate: Date = Date()) {
        self.sizeAvailability = sizeAvailability
        self.fileExists = fileExists
        self.copiedNode = copiedNode
        self.movedNode = movedNode
        self.containsOriginalsDirectory = containsOriginalsDirectory
        self.fileSize = fileSize
        self.creationDate = creationDate
    }
    
    public func documentsDirectory() -> URL {
        return URL(string: "/Documents") ?? URL(fileURLWithPath: "/Documents")
    }

    public func fileExists(at url: URL) -> Bool {
        fileExists
    }
    
    public func systemVolumeAvailability() -> Int64 {
        sizeAvailability
    }
    
    public func moveFile(at sourceURL: URL, to destinationURL: URL) -> Bool {
        movedNode
    }
    
    public func copyFile(at sourceURL: URL, to destinationURL: URL) -> Bool {
        copiedNode
    }
    
    public func removeFile(at url: URL) { }
    
    public func fileSize(at url: URL) -> UInt64? {
        fileSize
    }
    
    public func fileCreationDate(at url: URL) -> Date? {
        creationDate
    }
}
