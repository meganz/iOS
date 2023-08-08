import MEGADomain

public final class MockABTestUseCase: ABTestUseCaseProtocol {
    private let abTestValue: Int
    
    public init(abTestValue: Int) {
        self.abTestValue = abTestValue
    }
    
    public func abTestValue(for: ABTestFlagName) async -> Int {
        abTestValue
    }
}
