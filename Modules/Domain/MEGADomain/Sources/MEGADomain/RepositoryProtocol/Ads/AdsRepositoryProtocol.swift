public protocol AdsRepositoryProtocol: RepositoryProtocol, Sendable {
    func queryAds(adsFlag: AdsFlagEntity, publicHandle: HandleEntity) async throws -> Int
}
