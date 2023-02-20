import MEGADomain
import Combine

struct ContactLinkRepository: ContactLinkRepositoryProtocol {
    public static var newRepo: ContactLinkRepository {
        ContactLinkRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func contactLinkQuery(handle: HandleEntity) async throws -> ContactLinkEntity? {
        try await withCheckedThrowingContinuation({ continuation in
            sdk.contactLinkQuery(withHandle: handle, delegate: MEGAGenericRequestDelegate(completion: { (request, error) in
                guard error.type == .apiOk else {
                    continuation.resume(throwing: GenericErrorEntity())
                    return
                }
                continuation.resume(with: .success(ContactLinkEntity(email: request.email, name: request.name)))
            }))
        })
    }
}
