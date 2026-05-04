import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASwift

public struct TransfersSettingsRepository: TransfersSettingsRepositoryProtocol {
    public static var newRepo: TransfersSettingsRepository {
        TransfersSettingsRepository(sdk: MEGASdk.sharedSdk)
    }

    private let sdk: MEGASdk

    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    public func maxConnections(for direction: TransferDirectionEntity) async throws -> Int {
        try await withAsyncThrowingValue(in: { completion in
            let delegate = RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(Int(request.number)))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            switch direction {
            case .download:
                sdk.getMaxDownloadConnections(with: delegate)
            case .upload:
                sdk.getMaxUploadConnections(with: delegate)
            }
        })
    }

    public func setMaxConnections(_ connections: Int, for direction: TransferDirectionEntity) async throws {
        try await withAsyncThrowingValue(in: { completion in
            sdk.setMaxConnectionsForDirection(
                direction.transferType,
                connections: connections,
                delegate: RequestDelegate { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            )
        })
    }
}

private extension TransferDirectionEntity {
    var transferType: MEGATransferType {
        switch self {
        case .download: .download
        case .upload: .upload
        }
    }
}
