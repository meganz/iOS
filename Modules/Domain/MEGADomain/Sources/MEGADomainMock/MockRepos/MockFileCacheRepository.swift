import Foundation
import MEGADomain

public struct MockFileCacheRepository: FileCacheRepositoryProtocol {
    public static let newRepo = MockFileCacheRepository()
    
    private let base64Handle: Base64HandleEntity
    private let name: String
    public var tempFolder: URL
    
    public init(base64Handle: Base64HandleEntity = "",
                name: String = "",
                tempFolder: URL = URL(fileURLWithPath: "temp/") ) {
        self.base64Handle = base64Handle
        self.name = name
        self.tempFolder = tempFolder
    }

    public func tempFileURL(for node: NodeEntity) -> URL {
        tempFolder.appendingPathComponent(name)
    }
    
    public func existingTempFileURL(for node: NodeEntity) -> URL? {
        tempFolder.appendingPathComponent(name)
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
