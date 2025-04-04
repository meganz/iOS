import MEGADomain
import MEGASdk
import MEGASwift

public struct UserInviteRepository: UserInviteRepositoryProtocol {
    public static var newRepo: UserInviteRepository {
        UserInviteRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func sendInvite(forEmail email: String) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.inviteContact(withEmail: email, message: "", action: .add, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    switch error.type {
                    case .apiEArgs where email == sdk.myEmail:
                        completion(.failure(InviteErrorEntity.ownEmailEntered))
                    case .apiEExist:
                        if let user = sdk.contact(forEmail: email), user.visibility == .visible {
                            completion(.failure(InviteErrorEntity.alreadyAContact))
                        } else {
                            let outgoingContactRequests1 = sdk.outgoingContactRequests()
                            let contactRequests = (0..<outgoingContactRequests1.size).compactMap {
                                outgoingContactRequests1.contactRequest(at: $0)
                            }
                            let isInOutgoingContactRequest1 = contactRequests.contains { $0.targetEmail == email }
                            completion(.failure(isInOutgoingContactRequest1 ? .isInOutgoingContactRequest : InviteErrorEntity.generic(error.name)))
                        }
                    default:
                        completion(.failure(InviteErrorEntity.generic(error.name)))
                    }
                }
            })
        }
    }
}
