import Foundation

protocol OfflineFilesRepositoryProtocol {
    var offlinePath: String { get }
    func offlineFiles() -> [OfflineFileEntity]
    func offlineFile(for base64Handle: String) -> OfflineFileEntity?
}
