
protocol FileVersionsUseCaseProtocol {
    func isFileVersionsEnabled(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void)
    func enableFileVersions(_ enable: Bool, completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void)
    func rootNodeFileVersionCount() -> Int64
    func rootNodeFileVersionTotalSizeInBytes() -> Int64
    func deletePreviousFileVersions(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void)
}

struct FileVersionsUseCase<T: FileVersionsRepositoryProtocol>: FileVersionsUseCaseProtocol {
    private let repo: T
    
    init(repo: T) {
        self.repo = repo
    }
    
    func isFileVersionsEnabled(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        repo.isFileVersionsEnabled(completion: completion)
    }
    
    func enableFileVersions(_ enable: Bool, completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        repo.enableFileVersions(enable, completion: completion)
    }
    
    func rootNodeFileVersionCount() -> Int64 {
        repo.rootNodeFileVersionCount()
    }
    
    func rootNodeFileVersionTotalSizeInBytes() -> Int64 {
        repo.rootNodeFileVersionTotalSizeInBytes()
    }
    
    func deletePreviousFileVersions(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        repo.deletePreviousFileVersions(completion: completion)
    }
}
