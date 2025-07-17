public protocol AdsUseCaseProtocol: Sendable {
    func queryAds(adsFlag: AdsFlagEntity, publicHandle: HandleEntity) async throws -> Int
}

public struct AdsUseCase<T: AdsRepositoryProtocol>: AdsUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func queryAds(adsFlag: AdsFlagEntity, publicHandle: HandleEntity = .invalid) async throws -> Int {
        try await repository.queryAds(adsFlag: adsFlag, publicHandle: publicHandle)
    }
}
