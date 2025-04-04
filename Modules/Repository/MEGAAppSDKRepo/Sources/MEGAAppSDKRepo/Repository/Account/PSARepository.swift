import MEGADomain
import MEGASdk
import MEGASwift

public struct PSARepository: PSARepositoryProtocol {
    public static var newRepo: PSARepository {
        PSARepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func getPSA() async throws -> PSAEntity {
        try await withAsyncThrowingValue { continuation in
            sdk.getURLPublicServiceAnnouncement(with: RequestDelegate { result in
                switch result {
                case .success(let request):
                    continuation(.success(request.toPSAEntity()))
                case .failure(let error):
                    let psaError = switch error.type {
                    case .apiENoent: PSAErrorEntity.noDataAvailable
                    default: PSAErrorEntity.generic
                    }
                    continuation(.failure(psaError))
                }
            })
        }
    }
    
    public func markAsSeenForPSA(withIdentifier identifier: PSAIdentifier) {
        sdk.setPSAWithIdentifier(Int(identifier))
    }
}
