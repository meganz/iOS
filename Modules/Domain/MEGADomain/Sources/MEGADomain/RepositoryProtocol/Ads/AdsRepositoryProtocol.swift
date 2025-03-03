public protocol AdsRepositoryProtocol: RepositoryProtocol, Sendable {
    func fetchAds(adsFlag: AdsFlagEntity,
                  adUnits: [AdsSlotEntity],
                  publicHandle: HandleEntity) async throws -> [String: String]
    func queryAds(adsFlag: AdsFlagEntity, publicHandle: HandleEntity) async throws -> Int
}
