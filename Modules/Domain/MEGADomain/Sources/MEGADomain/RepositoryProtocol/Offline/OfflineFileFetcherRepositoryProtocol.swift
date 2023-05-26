
public protocol OfflineFileFetcherRepositoryProtocol: RepositoryProtocol {
    func offlineFiles() -> [OfflineFileEntity]
    func offlineFile(for base64Handle: String) -> OfflineFileEntity?
}
