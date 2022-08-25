import Foundation

public protocol OfflineFilesRepositoryProtocol: RepositoryProtocol {
    var offlineURL: URL? { get }
    func offlineFiles() -> [OfflineFileEntity]
    func offlineFile(for base64Handle: String) -> OfflineFileEntity?
    func createOfflineFile(name: String, for handle: HandleEntity)
}
