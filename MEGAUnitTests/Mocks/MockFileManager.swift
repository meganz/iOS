@testable import MEGA

final class MockFileManager: FileManager, @unchecked Sendable {
    static let anyURL = URL(string: "any/url")!
    
    private let freeSize: UInt64
    private let tempURL: URL
    private let containerURL: URL
    
    var errorToThrow: (any Error)?
    var lastRemovedPath: String?

    var removeFolderContents_calledTimes = 0
    
    var contentsOfDirectory: [String]?
    
    init(
        freeSize: UInt64 = 100,
        tempURL: URL = MockFileManager.anyURL,
        containerURL: URL = MockFileManager.anyURL,
        contentsOfDirectory: [String]? = nil,
        errorToThrow: (any Error)? = nil
    ) {
        self.tempURL = tempURL
        self.freeSize = freeSize
        self.containerURL = containerURL
        self.errorToThrow = errorToThrow
        self.contentsOfDirectory = contentsOfDirectory
        super.init()
    }
    
    override var mnz_fileSystemFreeSize: UInt64 {
        freeSize
    }
    
    override var temporaryDirectory: URL {
        tempURL
    }
    
    override func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL? {
        containerURL
    }
    
    override func removeItem(atPath path: String) throws {
        removeFolderContents_calledTimes += 1
        
        lastRemovedPath = path
        if let error = errorToThrow {
            throw error
        }
    }
    
    override func contentsOfDirectory(atPath path: String) throws -> [String] {
        guard let contentsOfDirectory else {
            return try super.contentsOfDirectory(atPath: path)
        }
        return contentsOfDirectory
    }
}
