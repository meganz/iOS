import Combine
import MEGADomain
import MEGASdk
import MEGASwift

public struct ContactLinkRepository: ContactLinkRepositoryProtocol {
    public static var newRepo: ContactLinkRepository {
        ContactLinkRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func contactLinkQuery(handle: HandleEntity) async throws -> ContactLinkEntity? {
        try await withAsyncThrowingValue { completion in
            sdk.contactLinkQuery(withHandle: handle, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(ContactLinkEntity(email: request.email, name: request.name, userHandle: request.parentHandle)))
                case .failure:
                    completion(.failure(GenericErrorEntity()))
                }
            })
        }
    }
}
