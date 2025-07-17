import MEGADomain

public final class MockAdsRepository: AdsRepositoryProtocol {
    private let queryAdsValue: Int
    
    public static var newRepo: MockAdsRepository {
        MockAdsRepository()
    }
    
    public init(queryAdsValue: Int = 0) {
        self.queryAdsValue = queryAdsValue
    }
    
    public func queryAds(adsFlag: AdsFlagEntity, publicHandle: HandleEntity) async throws -> Int {
        queryAdsValue
    }
}
