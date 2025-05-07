import MEGADomain
import MEGASdk
import MEGASwift

public struct ContactLinkVerificationRepository: ContactLinkVerificationRepositoryProtocol {
    public static var newRepo: ContactLinkVerificationRepository {
        ContactLinkVerificationRepository(sdk: MEGASdk.sharedSdk)
    }
    
    public var qrCodeContactAutoAdditionEvents: AnyAsyncSequence<Void> {
        MEGAUpdateHandlerManager.shared.userUpdates
            .filter { $0.contains(where: {
                $0.changes.contains(.contactLinkVerification)
            })}
            .map { _ in () }
            .eraseToAnyAsyncSequence()
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func contactLinksOption() async throws -> Bool {
        try await withAsyncThrowingValue { completion in
            sdk.getContactLinksOption(with: RequestDelegate { result  in
                switch result {
                case .success(let request):
                    completion(.success(request.flag))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
    
    public func updateContactLinksOption(enabled: Bool) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.setContactLinksOption(enabled, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
    
    public func resetContactLink() async throws {
        try await withAsyncThrowingValue { completion in
            sdk.contactLinkCreateRenew(true, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
}
