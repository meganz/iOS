import Foundation
import MEGADomain

public final class MockCacheUseCase: CacheUseCaseProtocol, @unchecked Sendable {
    private var _cacheSize: UInt64
    public var cleanCache_calledTimes = 0
    
    public init(cacheSize: UInt64) {
        _cacheSize = cacheSize
    }
    
    public func cacheSize() throws -> UInt64 {
        _cacheSize
    }
    
    public func cleanCache() async throws {
        _cacheSize = 0
        cleanCache_calledTimes += 1
    }
}
