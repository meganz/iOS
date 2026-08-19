import Foundation
import MEGADomain

public struct MockFileCacheRepository: FileCacheRepositoryProtocol {
    public static let newRepo = MockFileCacheRepository()
    
    private let base64Handle: Base64HandleEntity
    private let name: String
    /// Whether a cached copy is already on disk. Defaults to `true` so that callers written before this knob
    /// existed keep seeing a cache hit; pass `false` to exercise what happens when nothing is cached yet.
    private let hasExistingTempFile: Bool
    /// The nodes that have a cached copy, by name, for when only some of them should. `nil` leaves
    /// `hasExistingTempFile` to speak for every node, which is what most callers want.
    private let cachedNodeNames: Set<String>?
    public var tempFolder: URL
    public var tempUploadURL: URL

    public init(
        base64Handle: Base64HandleEntity = "",
        name: String = "",
        hasExistingTempFile: Bool = true,
        cachedNodeNames: Set<String>? = nil,
        tempFolder: URL = URL(fileURLWithPath: "temp/"),
        tempUploadURL: URL = URL(fileURLWithPath: "temp/upload")
    ) {
        self.base64Handle = base64Handle
        self.name = name
        self.hasExistingTempFile = hasExistingTempFile
        self.cachedNodeNames = cachedNodeNames
        self.tempFolder = tempFolder
        self.tempUploadURL = tempUploadURL
    }

    public func tempFileURL(for node: NodeEntity) -> URL {
        tempFolder.appendingPathComponent(name)
    }

    /// Mirrors the real layout: the node keeps its name and only the folder holding it differs.
    public func stagingTempFileURL(for node: NodeEntity) -> URL {
        stagingTempFolder(for: node).appendingPathComponent(name)
    }

    public func stagingTempFolder(for node: NodeEntity) -> URL {
        tempFolder.appendingPathComponent(base64Handle + ".incomplete")
    }

    public func existingTempFileURL(for node: NodeEntity) -> URL? {
        let isCached = cachedNodeNames.map { $0.contains(node.name) } ?? hasExistingTempFile
        return isCached ? tempFolder.appendingPathComponent(name) : nil
    }
    
    public var cachedOriginalImageDirectoryURL: URL {
        URL(fileURLWithPath: "originalV3/")
    }
    
    public func cachedOriginalImageURL(for node: NodeEntity) -> URL {
        URL(fileURLWithPath: "originalV3/" + base64Handle)
    }
    
    public func existingOriginalImageURL(for node: NodeEntity) -> URL? {
        URL(fileURLWithPath: "originalV3/" + base64Handle)
    }
    
    public func cachedOriginalURL(for base64Handle: Base64HandleEntity, name: String) -> URL {
        URL(fileURLWithPath: "originalV3/" + self.base64Handle)
    }
    
    public func tempUploadURL(for name: String) -> URL {
        tempFolder.appendingPathComponent(self.name)
    }

    public func base64HandleTempFolder(for base64Handle: Base64HandleEntity) -> URL {
        tempFolder.appendingPathComponent(self.base64Handle)
    }
    
    public func offlineFileURL(name: String) -> URL {
        URL(fileURLWithPath: "thumbnailsV3/" + self.name)
    }
}
