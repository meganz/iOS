
protocol FileVersionsRepositoryProtocol {
    func isFileVersionsEnabled(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void)
    func enableFileVersions(_ enable: Bool, completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void)
#if MAIN_APP_TARGET
    func rootNodeFileVersionCount() -> Int64
    func rootNodeFileVersionTotalSizeInBytes() -> Int64
#endif
    func deletePreviousFileVersions(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void)
}
