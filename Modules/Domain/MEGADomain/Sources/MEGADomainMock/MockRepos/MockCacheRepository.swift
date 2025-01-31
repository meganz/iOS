import MEGADomain

public final class MockCacheRepository: CacheRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockCacheRepository {
        MockCacheRepository()
    }
    
    private let folderSizes: [String: UInt64]
    
    public private(set) var cacheSize_calledTimes = 0
    public private(set) var cleanCache_calledTimes = 0
    public private(set) var didCleanCache = false

    public init(folderSizes: [String: UInt64] = [:]) {
        self.folderSizes = folderSizes
    }
    
    public func cacheSize() throws -> UInt64 {
        cacheSize_calledTimes += 1
        return folderSizes.values.reduce(0, +)
    }

    public func cleanCache() async throws {
        cleanCache_calledTimes += 1
        if try cacheSize() > 0 {
            didCleanCache = true
        }
    }
}
