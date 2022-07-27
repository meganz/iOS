@testable import MEGA

struct MockFileSystemRepository: FileSystemRepositoryProtocol {
    static let newRepo = MockFileSystemRepository()
    
    var sizeAvailability: Int64 = 0
    var fileExists: Bool = false
    var copiedNode: Bool = false
    var movedNode: Bool = false
    var containsOriginalsDirectory: Bool = false
    var fileSize: UInt64 = 0
    var creationDate: Date = Date()

    func documentsDirectory() -> URL {
        return URL(fileURLWithPath: "Documents")
    }

    func fileExists(at url: URL) -> Bool {
        fileExists
    }
    
    func systemVolumeAvailability() -> Int64 {
        sizeAvailability
    }
    
    func moveFile(at sourceURL: URL, to destinationURL: URL, name: String) -> Bool {
        movedNode
    }
    
    func copyFile(at sourceURL: URL, to destinationURL: URL, name: String) -> Bool {
        copiedNode
    }
    
    func removeFile(at url: URL) { }
    
    func fileSize(at url: URL) -> UInt64? {
        fileSize
    }
    
    func fileCreationDate(at url: URL) -> Date? {
        creationDate
    }
}
