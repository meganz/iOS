import MEGADomain
import MEGASdk
import MEGASwift

public struct DeviceRepository: DeviceRepositoryProtocol {
    public static var newRepo: DeviceRepository {
        DeviceRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func fetchDeviceName(_ deviceId: String?) async throws -> String? {
        try await withAsyncThrowingValue { completion in
            sdk.getDeviceName(
                deviceId,
                delegate: RequestDelegate { result in
                    switch result {
                    case .success(let request):
                        completion(.success(request.name))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            )
        }
    }
    
    public func renameDevice(_ deviceId: String?, newName: String) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.renameDevice(
                deviceId,
                newName: newName,
                delegate: RequestDelegate { result in
                    switch result {
                    case .success:
                        completion(.success)
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            )
        }
    }
}
