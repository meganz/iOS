public protocol OfflineFileFetcherRepositoryProtocol: RepositoryProtocol, Sendable {
    func offlineFiles() -> [OfflineFileEntity]
    func offlineFile(for base64Handle: String) -> OfflineFileEntity?
}
