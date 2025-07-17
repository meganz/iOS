import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import XCTest

final class AdsRepositoryTests: XCTestCase {
    func testQueryAds_successRequest_shouldReturnCorrectValue() async throws {
        let expectedValue = Int.random(in: 0...1)
        let mockRequest = MockRequest(handle: 1, numDetails: expectedValue)
        let sut = AdsRepository(
            sdk: MockSdk(requestResult: .success(mockRequest))
        )
        
        let queryAdsValue = try await sut.queryAds(adsFlag: .defaultAds, publicHandle: .invalid)
        
        XCTAssertEqual(queryAdsValue, expectedValue)
    }
    
    func testQueryAds_failedRequest_shouldReturnError() async throws {
        let expectedError = MockError.failingError
        let sut = AdsRepository(
            sdk: MockSdk(requestResult: .failure(expectedError))
        )
        
        await XCTAsyncAssertThrowsError(try await sut.queryAds(adsFlag: .defaultAds,
                                                               publicHandle: .invalid)
        ) { error in
            XCTAssertEqual(error as? MockError, expectedError)
        }
    }
}
