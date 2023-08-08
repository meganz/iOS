import MEGADomain

public final class MockABTestRepository: ABTestRepositoryProtocol {
    public static var newRepo: MockABTestRepository = MockABTestRepository()
    private let abTestValues: [ABTestFlagName: Int]
    
    public init(abTestValues: [ABTestFlagName: Int] = [:]) {
        self.abTestValues = abTestValues
    }
    
    public func abTestValue(for flag: ABTestFlagName) async -> Int {
        abTestValues[flag] ?? 0
    }
}
