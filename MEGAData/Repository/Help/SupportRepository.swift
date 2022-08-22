import Combine
import MEGADomain

struct SupportRepository: SupportRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func createSupportTicket(withMessage message: String) -> Future<Void, CreateSupportTicketErrorEntity> {
        return Future() { promise in
            sdk.createSupportTicket(withMessage: message, type: 9, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    promise(Result.success(()))
                case .failure:
                    promise(Result.failure(.generic))
                }
            })
        }
    }
}
