import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import XCTest

final class ABTestRepositoryTests: XCTestCase {
    func testABTestValue_returnCorrectValue() async {
        let testFlagName = "abDevTest"
        let abTestExpectedValue = Int.random(in: 0...2)
        let abTests = [testFlagName: abTestExpectedValue]
        
        let sut = ABTestRepository(sdk: MockSdk(abTestValues: abTests))
        let abTestValue = await sut.abTestValue(for: testFlagName)

        XCTAssertEqual(abTestValue, abTestExpectedValue)
    }
}
