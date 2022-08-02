import Foundation
import MEGADomain

protocol FileCacheRepositoryProtocol: RepositoryProtocol {
    func tempFileURL(for node: NodeEntity) -> URL
    func existingTempFileURL(for node: NodeEntity) -> URL?
    
    var cachedOriginalImageDirectoryURL: URL { get }
    func cachedOriginalImageURL(for node: NodeEntity) -> URL
    func existingOriginalImageURL(for node: NodeEntity) -> URL?
    func cachedOriginalURL(for base64Handle: Base64HandleEntity, name: String) -> URL
    func tempUploadURL(for name: String) -> URL
    func tempURL(for base64Handle: Base64HandleEntity) -> URL
    func cachedFileURL(for base64Handle: Base64HandleEntity, name: String) -> URL
    func offlineFileURL(name: String) -> URL
}
