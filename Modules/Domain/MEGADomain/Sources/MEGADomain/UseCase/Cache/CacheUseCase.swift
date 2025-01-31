public protocol CacheUseCaseProtocol: Sendable {
    func cacheSize() throws -> UInt64
    func cleanCache() async throws
}

public struct CacheUseCase: CacheUseCaseProtocol {
    private let cacheRepository: any CacheRepositoryProtocol
    
    public init(cacheRepository: some CacheRepositoryProtocol) {
        self.cacheRepository = cacheRepository
    }
    
    public func cacheSize() throws -> UInt64 {
        try cacheRepository.cacheSize()
    }
    
    public func cleanCache() async throws {
        try await cacheRepository.cleanCache()
    }
}
