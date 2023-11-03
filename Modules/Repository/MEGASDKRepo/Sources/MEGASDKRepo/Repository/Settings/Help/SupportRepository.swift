import MEGADomain
import MEGASdk
import MEGASwift

public struct SupportRepository: SupportRepositoryProtocol {
    public static var newRepo: SupportRepository {
        SupportRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func createSupportTicket(withMessage message: String) async throws {
        try await withAsyncThrowingValue(in: { completion in
            sdk.createSupportTicket(withMessage: message, type: 9, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    if error.type == .apiETooMany {
                        completion(.failure(ReportErrorEntity.tooManyRequest))
                    } else {
                        completion(.failure(ReportErrorEntity.generic))
                    }
                }
            })
        })
    }
}
