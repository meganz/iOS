import MEGADomain
import MEGADomainMock
import XCTest

final class AdsUseCaseTests: XCTestCase {

    func testFetchAds_shouldReturnCorrectAds() async throws {
        let expectedAds = ["FILES": "https://testAd/link"]
        let sut = AdsUseCase(repository: MockAdsRepository(adsValue: expectedAds))
        
        let adsValue = try await sut.fetchAds(adsFlag: .defaultAds, adUnits: [.files])
        
        XCTAssertEqual(adsValue, expectedAds)
    }
    
    func testQueryAds_shouldReturnCorrectValue() async throws {
        let expectedValue = Int.random(in: 0...1)
        let sut = AdsUseCase(repository: MockAdsRepository(queryAdsValue: expectedValue))
        
        let queryAdsValue = try await sut.queryAds(adsFlag: .defaultAds)
        
        XCTAssertEqual(queryAdsValue, expectedValue)
    }
}
