import MEGADomain
import MEGAData
import MEGASwift

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
    
    func updateUserAttribute(_ attribute: UserAttributeEntity, key: String, value: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            
            sdk.setUserAttributeType(attribute.toMEGAUserAttribute(), key: key, value: value, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                continuation.resume(with: result.map { _ in })
            })
        }
    }
    
    func userAttribute(for attribute: UserAttributeEntity) async throws -> [String: String]? {
        try await withAsyncThrowingValue(in: { completion in
            sdk.getUserAttributeType(attribute.toMEGAUserAttribute(), delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.megaStringDictionary))
                case .failure:
                    completion(.failure(GenericErrorEntity()))
                }
            })
        })
    }
}
