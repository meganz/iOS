import MEGADomain
import MEGASdk
import MEGASwift

public struct RenameRepository: RenameRepositoryProtocol {
    public static var newRepo: RenameRepository {
        RenameRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func renameDevice(_ deviceId: String, newName: String) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.renameDevice(deviceId, newName: newName, delegate: RequestDelegate { result in
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
