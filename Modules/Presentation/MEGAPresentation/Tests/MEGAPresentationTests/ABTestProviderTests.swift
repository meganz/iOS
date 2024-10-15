import MEGADomainMock
import MEGAPresentation
import Testing

struct ABTestProviderTests {
    @Test("When AB flag provided it should return correct variant")
    func returnCorrectVariant() async {
        let expectedVariant = randomVariant

        let sut = ABTestProvider(useCase: MockABTestUseCase(abTestValue: expectedVariant.rawValue))
        
        #expect(await sut.abTestVariant(for: .devTest) == expectedVariant)
    }
    
    @Test("When AB flag provided it should return false for baseLine and true for variantA",
          arguments: [(ABTestVariant.baseline, false),
                      (.variantA, true)])
    func isEnabled(variant: ABTestVariant, expectedEnabled: Bool) async {
        let sut = ABTestProvider(useCase: MockABTestUseCase(abTestValue: variant.rawValue))
        
        #expect(await sut.isEnabled(for: .devTest) == expectedEnabled)
    }
    
    // MARK: Helpers
    private var randomVariant: ABTestVariant {
        ABTestVariant.allCases.randomElement() ?? .baseline
    }
}
