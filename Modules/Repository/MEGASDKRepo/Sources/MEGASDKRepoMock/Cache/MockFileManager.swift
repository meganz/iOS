import Foundation

public final class MockFileManager: FileManager, @unchecked Sendable {
    private(set) var removeItem_calledTimes = 0
    private(set) var fileExists_calledTimes = 0
    private(set) var createDirectory_calledTimes = 0
    private(set) var removeFolderContents_calledTimes = 0
    private(set) var removeItemCalledWith = [URL]()
    
    private let containerURLs: [String: URL]
    private let directoryContentsStubs: [String: [URL]]
    private let fileSizes: [String: UInt64]
    
    public init(
        containerURLs: [String: URL],
        directoryContents: [String: [URL]] = [:],
        fileSizes: [String: UInt64] = [:]
    ) {
        self.containerURLs = containerURLs
        self.directoryContentsStubs = directoryContents
        self.fileSizes = fileSizes
        super.init()
    }
    
    public override func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL? {
        containerURLs[groupIdentifier]
    }
    
    public override func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options: FileManager.DirectoryEnumerationOptions = []
    ) throws -> [URL] {
        directoryContentsStubs[url.lastPathComponent] ?? []
    }
    
    public override func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        let fileURL = URL(fileURLWithPath: path)
        if directoryContentsStubs[fileURL.lastPathComponent] != nil {
            return [.type: FileAttributeType.typeDirectory, .size: 0]
        }
        let size = fileSizes[fileURL.lastPathComponent] ?? 0
        return [.type: FileAttributeType.typeRegular, .size: NSNumber(value: size)]
    }
    
    public override func removeItem(at url: URL) throws {
        removeItem_calledTimes += 1
        removeItemCalledWith.append(url)
    }
    
    public override func fileExists(atPath path: String) -> Bool {
        fileExists_calledTimes += 1
        return true
    }
    
    public override func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        createDirectory_calledTimes += 1
    }
}
