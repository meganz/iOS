
public protocol FileVersionsUseCaseProtocol {
    func isFileVersionsEnabled(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void)
    func enableFileVersions(_ enable: Bool, completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void)
    func rootNodeFileVersionCount() -> Int64
    func rootNodeFileVersionTotalSizeInBytes() -> Int64
    func deletePreviousFileVersions(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void)
}

public struct FileVersionsUseCase<T: FileVersionsRepositoryProtocol>: FileVersionsUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func isFileVersionsEnabled(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        repo.isFileVersionsEnabled(completion: completion)
    }
    
    public func enableFileVersions(_ enable: Bool, completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        repo.enableFileVersions(enable, completion: completion)
    }
    
    public func rootNodeFileVersionCount() -> Int64 {
        repo.rootNodeFileVersionCount()
    }
    
    public func rootNodeFileVersionTotalSizeInBytes() -> Int64 {
        repo.rootNodeFileVersionTotalSizeInBytes()
    }

    public func deletePreviousFileVersions(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        repo.deletePreviousFileVersions(completion: completion)
    }
}
