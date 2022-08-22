@testable import MEGA
import MEGADomain

struct MockFileCacheRepository: FileCacheRepositoryProtocol {
    static let newRepo = MockFileCacheRepository()
    
    var base64Handle: Base64HandleEntity = ""
    var name: String = ""
    var tempFolder: URL = URL(fileURLWithPath: "temp/")

    func tempFileURL(for node: NodeEntity) -> URL {
        tempFolder.appendingPathComponent(name)
    }
    
    func existingTempFileURL(for node: NodeEntity) -> URL? {
        tempFolder.appendingPathComponent(name)
    }
    
    var cachedOriginalImageDirectoryURL: URL {
        URL(fileURLWithPath: "originalV3/")
    }
    
    func cachedOriginalImageURL(for node: NodeEntity) -> URL {
        URL(fileURLWithPath: "originalV3/" + base64Handle)
    }
    
    func existingOriginalImageURL(for node: NodeEntity) -> URL? {
        URL(fileURLWithPath: "originalV3/" + base64Handle)
    }
    
    func cachedOriginalURL(for base64Handle: Base64HandleEntity, name: String) -> URL {
        URL(fileURLWithPath: "originalV3/" + self.base64Handle)
    }
    
    func tempUploadURL(for name: String) -> URL {
        tempFolder.appendingPathComponent(self.name)
    }

    func base64HandleTempFolder(for base64Handle: Base64HandleEntity) -> URL {
        tempFolder.appendingPathComponent(self.base64Handle)
    }
    
    func offlineFileURL(name: String) -> URL {
        URL(fileURLWithPath: "thumbnailsV3/" + self.name)
    }
}
