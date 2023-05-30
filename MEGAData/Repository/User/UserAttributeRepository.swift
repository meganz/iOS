import MEGADomain
import MEGAData

struct UserAttributeRepository: UserAttributeRepositoryProtocol {
    static var newRepo: UserAttributeRepository {
        UserAttributeRepository(sdk: MEGASdk.shared)
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func updateUserAttribute(_ attribute: UserAttributeEntity, value: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            
            sdk.setUserAttributeType(attribute.toMEGAUserAttribute(), value: value, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                continuation.resume(with: result.map {_ in })
            })
        }
    }
}
