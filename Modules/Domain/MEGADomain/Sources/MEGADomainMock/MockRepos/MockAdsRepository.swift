import MEGADomain

public final class MockAdsRepository: AdsRepositoryProtocol {
    private let adsValue: [String: String]
    private let queryAdsValue: Int
    
    public static var newRepo: MockAdsRepository {
        MockAdsRepository()
    }
    
    public init(adsValue: [String: String] = [:], queryAdsValue: Int = 0) {
        self.adsValue = adsValue
        self.queryAdsValue = queryAdsValue
    }
    
    public func fetchAds(adsFlag: AdsFlagEntity, adUnits: [AdsSlotEntity], publicHandle: HandleEntity) async throws -> [String: String] {
        adsValue
    }
    
    public func queryAds(adsFlag: AdsFlagEntity, publicHandle: HandleEntity) async throws -> Int {
        queryAdsValue
    }
}
