import MEGADomain
import MEGADomainMock
import XCTest

final class AdsUseCaseTests: XCTestCase {
    func testQueryAds_shouldReturnCorrectValue() async throws {
        let expectedValue = Int.random(in: 0...1)
        let sut = AdsUseCase(repository: MockAdsRepository(queryAdsValue: expectedValue))
        
        let queryAdsValue = try await sut.queryAds(adsFlag: .defaultAds)
        
        XCTAssertEqual(queryAdsValue, expectedValue)
    }
}
