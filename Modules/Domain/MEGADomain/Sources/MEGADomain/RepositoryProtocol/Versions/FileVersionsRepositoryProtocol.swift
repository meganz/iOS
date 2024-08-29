public protocol FileVersionsRepositoryProtocol: RepositoryProtocol, Sendable {
    func isFileVersionsEnabled() async throws -> Bool
    func enableFileVersions(_ enable: Bool) async throws -> Bool
    func rootNodeFileVersionCount() -> Int64
    func rootNodeFileVersionTotalSizeInBytes() -> Int64
    func deletePreviousFileVersions() async throws -> Bool
}
