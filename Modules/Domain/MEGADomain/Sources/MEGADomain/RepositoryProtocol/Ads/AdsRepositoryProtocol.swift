public protocol AdsRepositoryProtocol: RepositoryProtocol {
    func fetchAds(adsFlag: AdsFlagEntity,
                  adUnits: [AdsSlotEntity],
                  publicHandle: HandleEntity) async throws -> [String: String]
    func queryAds(adsFlag: AdsFlagEntity, publicHandle: HandleEntity) async throws -> Int
}
