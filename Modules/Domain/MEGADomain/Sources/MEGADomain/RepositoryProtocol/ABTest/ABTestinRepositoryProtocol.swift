public protocol ABTestRepositoryProtocol: RepositoryProtocol, Sendable {
    func abTestValue(for: ABTestFlagName) async -> Int
}
