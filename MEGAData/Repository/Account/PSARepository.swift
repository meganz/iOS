import MEGADomain

struct PSARepository: PSARepositoryProtocol {
    static var newRepo: PSARepository {
        PSARepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void) {
        sdk.getURLPublicServiceAnnouncement(with: MEGAGenericRequestDelegate {  request, error in
            switch error.type {
            case .apiOk:
                completion(.success(request.toPSAEntity()))
            case .apiENoent:
                completion(.failure(PSAErrorEntity.noDataAvailable))
            default:
                completion(.failure(PSAErrorEntity.generic))
            }
        })
    }
    
    func markAsSeenForPSA(withIdentifier identifier: PSAIdentifier) {
        sdk.setPSAWithIdentifier(identifier)
    }
}
