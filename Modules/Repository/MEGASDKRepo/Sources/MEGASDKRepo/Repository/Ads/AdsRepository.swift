import MEGADomain
import MEGASdk
import MEGASwift

public struct AdsRepository: AdsRepositoryProtocol {
    public static var newRepo: AdsRepository {
        AdsRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func fetchAds(adsFlag: AdsFlagEntity, adUnits: [AdsSlotEntity], publicHandle: HandleEntity) async throws -> [String: String] {
        return try await withAsyncThrowingValue(in: { completion in
            let flag = adsFlag.toAdsFlag()
            let adsSlots = sdk.megaStringList(for: adUnits.map { $0.rawValue })
            
            sdk.fetchAds(flag, adUnits: adsSlots, publicHandle: publicHandle, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.megaStringDictionary ?? [:]))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        })
    }
    
    public func queryAds(adsFlag: AdsFlagEntity, publicHandle: HandleEntity) async throws -> Int {
        try await withAsyncThrowingValue(in: { completion in
            let flag = adsFlag.toAdsFlag()
            sdk.queryAds(flag, publicHandle: publicHandle, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.numDetails))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        })
    }
}
