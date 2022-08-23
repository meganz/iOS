
public protocol FileVersionsRepositoryProtocol: RepositoryProtocol {
    func isFileVersionsEnabled(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void)
    func enableFileVersions(_ enable: Bool, completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void)
    func rootNodeFileVersionCount() -> Int64
    func rootNodeFileVersionTotalSizeInBytes() -> Int64
    func deletePreviousFileVersions(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void)
}
