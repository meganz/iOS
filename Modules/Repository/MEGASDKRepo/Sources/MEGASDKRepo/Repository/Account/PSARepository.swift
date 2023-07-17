import MEGADomain
import MEGASdk

public struct PSARepository: PSARepositoryProtocol {
    public static var newRepo: PSARepository {
        PSARepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void) {
        sdk.getURLPublicServiceAnnouncement(with: RequestDelegate { result in
            switch result {
            case .success(let request):
                completion(.success(request.toPSAEntity()))
            case .failure(let error):
                switch error.type {
                case .apiENoent:
                    completion(.failure(PSAErrorEntity.noDataAvailable))
                default:
                    completion(.failure(PSAErrorEntity.generic))
                }
            }
        })
    }
    
    public func markAsSeenForPSA(withIdentifier identifier: PSAIdentifier) {
        sdk.setPSAWithIdentifier(identifier)
    }
}
