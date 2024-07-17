public protocol ABTestUseCaseProtocol: Sendable {
    func abTestValue(for: ABTestFlagName) async -> Int
}

public struct ABTestUseCase<T: ABTestRepositoryProtocol>: ABTestUseCaseProtocol {

    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func abTestValue(for flag: ABTestFlagName) async -> Int {
        await repository.abTestValue(for: flag)
    }
}
