public protocol FileVersionsUseCaseProtocol: Sendable {
    func isFileVersionsEnabled() async throws -> Bool
    func enableFileVersions(_ enable: Bool) async throws -> Bool
    func rootNodeFileVersionCount() -> Int64
    func rootNodeFileVersionTotalSizeInBytes() -> Int64
    func deletePreviousFileVersions() async throws -> Bool
}

public struct FileVersionsUseCase<T: FileVersionsRepositoryProtocol>: FileVersionsUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func isFileVersionsEnabled() async throws -> Bool {
        try await repo.isFileVersionsEnabled()
    }
    
    public func enableFileVersions(_ enable: Bool) async throws -> Bool {
        try await repo.enableFileVersions(enable)
    }
    
    public func rootNodeFileVersionCount() -> Int64 {
        repo.rootNodeFileVersionCount()
    }
    
    public func rootNodeFileVersionTotalSizeInBytes() -> Int64 {
        repo.rootNodeFileVersionTotalSizeInBytes()
    }
    
    public func deletePreviousFileVersions() async throws -> Bool {
        try await repo.deletePreviousFileVersions()
    }
}
