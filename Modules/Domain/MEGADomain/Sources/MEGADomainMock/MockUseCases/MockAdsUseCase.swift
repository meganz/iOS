import MEGADomain

final public class MockAdsUseCase: AdsUseCaseProtocol {
    private let adsList: [String: String]
    private let queryAdsValue: Int
    
    public init(adsList: [String: String] = [:], queryAdsValue: Int = 0) {
        self.adsList = adsList
        self.queryAdsValue = queryAdsValue
    }
    
    public func fetchAds(adsFlag: AdsFlagEntity, adUnits: [AdsSlotEntity], publicHandle: HandleEntity) async throws -> [String: String] {
        adsList
    }
    
    public func queryAds(adsFlag: AdsFlagEntity, publicHandle: HandleEntity) async throws -> Int {
        queryAdsValue
    }
}
