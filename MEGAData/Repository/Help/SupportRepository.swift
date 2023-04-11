import MEGADomain
import MEGASwift

struct SupportRepository: SupportRepositoryProtocol {
    static var newRepo: SupportRepository {
        SupportRepository(sdk: MEGASdk.shared)
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func createSupportTicket(withMessage message: String) async throws {
        try await withAsyncThrowingValue(in: { completion in
            sdk.createSupportTicket(withMessage: message, type: 9, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success)
                case .failure:
                    completion(.failure(GenericErrorEntity()))
                }
            })
        })
    }
}
