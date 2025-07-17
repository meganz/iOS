import MEGADomain

final public class MockAdsUseCase: AdsUseCaseProtocol {
    private let queryAdsValue: Int
    
    public init(queryAdsValue: Int = 0) {
        self.queryAdsValue = queryAdsValue
    }
    
    public func queryAds(adsFlag: AdsFlagEntity, publicHandle: HandleEntity) async throws -> Int {
        queryAdsValue
    }
}
