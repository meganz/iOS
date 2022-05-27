import Foundation

protocol FileCacheRepositoryProtocol {
    func tempFileURL(for node: NodeEntity) -> URL
    func existingTempFileURL(for node: NodeEntity) -> URL?
    
    var cachedOriginalImageDirectoryURL: URL { get }
    func cachedOriginalImageURL(for node: NodeEntity) -> URL
    func existingOriginalImageURL(for node: NodeEntity) -> URL?
}
