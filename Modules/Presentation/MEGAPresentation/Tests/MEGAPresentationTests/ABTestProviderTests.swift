import MEGADomainMock
import MEGAPresentation
import XCTest

final class ABTestProviderTests: XCTestCase {

    func testABTestVariant_returnCorrectVariant() async {
        let expectedVariant = randomVariant

        let sut = ABTestProvider(useCase: MockABTestUseCase(abTestValue: expectedVariant.rawValue))
        let abTestVariant = await sut.abTestVariant(for: .devTest)
        
        XCTAssertEqual(abTestVariant, expectedVariant)
    }
    
    // MARK: Helpers
    private var randomVariant: ABTestVariant {
        ABTestVariant.allCases.randomElement() ?? .baseline
    }
}
