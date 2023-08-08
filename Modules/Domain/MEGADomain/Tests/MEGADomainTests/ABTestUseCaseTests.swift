import MEGADomain
import MEGADomainMock
import XCTest

final class ABTestUseCaseTests: XCTestCase {

    private let abTestFlagName = "abDevTest"
    
    func testABTestValue_noExistingABTest_shouldReturnZero() async {
        let sut = ABTestUseCase(repository: MockABTestRepository())
        let abTestValue = await sut.abTestValue(for: abTestFlagName)
        
        XCTAssertEqual(abTestValue, 0)
    }
    
    func testABTestValue_withExistingABTest_shouldReturnCorrectValue() async {
        let expectedValue = Int.random(in: 0...2)
        let abTests = [abTestFlagName: expectedValue]
        let sut = ABTestUseCase(repository: MockABTestRepository(abTestValues: abTests))
        
        let abTestValue = await sut.abTestValue(for: abTestFlagName)
        
        XCTAssertEqual(abTestValue, expectedValue)
    }
}
