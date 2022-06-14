@testable import MEGA

struct MockFileSystemRepository: FileSystemRepositoryProtocol {
    var sizeAvailability: Int64 = 0
    var fileExists: Bool = false
    var copiedNode: Bool = false
    var movedNode: Bool = false
    var containsOriginalsDirectory: Bool = false

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
}
