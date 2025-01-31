public protocol CacheRepositoryProtocol: RepositoryProtocol, Sendable {
    func cacheSize() throws -> UInt64
    func cleanCache() async throws
}
