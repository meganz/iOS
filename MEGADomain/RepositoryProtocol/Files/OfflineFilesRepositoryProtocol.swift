import Foundation

protocol OfflineFilesRepositoryProtocol {
    var relativeOfflinePath: String { get }
    func offlineFiles() -> [OfflineFileEntity]
    func offlineFile(for base64Handle: String) -> OfflineFileEntity?
    func createOfflineFile(name: String, for handle: MEGAHandle)
}
