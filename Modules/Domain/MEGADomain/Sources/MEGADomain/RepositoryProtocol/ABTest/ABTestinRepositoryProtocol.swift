public protocol ABTestRepositoryProtocol: RepositoryProtocol {
    func abTestValue(for: ABTestFlagName) async -> Int
}
