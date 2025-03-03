public protocol AdsUseCaseProtocol: Sendable {
    func fetchAds(adsFlag: AdsFlagEntity,
                  adUnits: [AdsSlotEntity],
                  publicHandle: HandleEntity) async throws -> [String: String]
    func queryAds(adsFlag: AdsFlagEntity, publicHandle: HandleEntity) async throws -> Int
}

public struct AdsUseCase<T: AdsRepositoryProtocol>: AdsUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func fetchAds(adsFlag: AdsFlagEntity,
                         adUnits: [AdsSlotEntity],
                         publicHandle: HandleEntity = .invalid) async throws -> [String: String] {
        try await repository.fetchAds(adsFlag: adsFlag, adUnits: adUnits, publicHandle: publicHandle)
    }
    
    public func queryAds(adsFlag: AdsFlagEntity, publicHandle: HandleEntity = .invalid) async throws -> Int {
        try await repository.queryAds(adsFlag: adsFlag, publicHandle: publicHandle)
    }
}
