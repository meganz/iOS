import Foundation

public protocol FileCacheRepositoryProtocol: RepositoryProtocol, Sendable {
    var tempFolder: URL { get }
    func tempFileURL(for node: NodeEntity) -> URL
    func existingTempFileURL(for node: NodeEntity) -> URL?
    var cachedOriginalImageDirectoryURL: URL { get }
    func cachedOriginalImageURL(for node: NodeEntity) -> URL
    func existingOriginalImageURL(for node: NodeEntity) -> URL?
    func cachedOriginalURL(for base64Handle: Base64HandleEntity, name: String) -> URL
    func tempUploadURL(for name: String) -> URL
    func base64HandleTempFolder(for base64Handle: Base64HandleEntity) -> URL
    func offlineFileURL(name: String) -> URL
}
