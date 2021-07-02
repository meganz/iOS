import Foundation

protocol OfflineFilesRepositoryProtocol {
    func offlineFiles() -> [OfflineFileEntity]
    func offlineFile(for base64Handle: String) -> OfflineFileEntity?
}
