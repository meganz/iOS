import MEGADomain
import MEGASdk
import MEGASwift

public struct TransferRepository: TransferRepositoryProtocol {
    public static var newRepo: TransferRepository {
        TransferRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public var completedTransferUpdates: AnyAsyncSequence<TransferEntity> {
        MEGAUpdateHandlerManager
            .shared
            .transferFinishUpdates
            .compactMap { try? $0.get() }
            .eraseToAnyAsyncSequence()
    }
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func download(node: NodeEntity,
                         to localUrl: URL,
                         collisionResolution: CollisionResolutionEntity = .renameNewWithSuffix,
                         startHandler: ((TransferEntity) -> Void)?,
                         progressHandler: ((TransferEntity) -> Void)?) async throws -> TransferEntity {
        guard let megaNode = sdk.node(forHandle: node.handle) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        return try await withAsyncThrowingValue { completion in
            sdk.startDownloadNode(
                megaNode,
                localPath: localUrl.path,
                fileName: nil,
                appData: nil,
                startFirst: true,
                cancelToken: nil,
                collisionCheck: CollisionCheck.fingerprint,
                collisionResolution: collisionResolution.toCollisionResolution(),
                delegate: TransferDelegate(start: startHandler, progress: progressHandler) { result in
                    switch result {
                    case .success(let transfer):
                        completion(.success(transfer))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
        }
    }
    
    public func uploadFile(at fileUrl: URL,
                           to parent: NodeEntity,
                           startHandler: ((TransferEntity) -> Void)?,
                           progressHandler: ((TransferEntity) -> Void)?) async throws -> TransferEntity {
        guard let parentNode = sdk.node(forHandle: parent.handle) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        return try await withAsyncThrowingValue { completion in
            sdk.startUpload(withLocalPath: fileUrl.path,
                            parent: parentNode,
                            fileName: nil,
                            appData: nil,
                            isSourceTemporary: false,
                            startFirst: true,
                            cancelToken: nil,
                            delegate: TransferDelegate(start: startHandler, progress: progressHandler) { result in
                switch result {
                case .success(let transfer):
                    completion(.success(transfer))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
    
    private func cancelTransfers(for direction: Int, sdk: MEGASdk) async throws {
        try await withAsyncThrowingValue { continuation in
            sdk.cancelTransfers(forDirection: direction, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    continuation(.success)
                case .failure(let error):
                    continuation(.failure(error))
                }
            })
        }
    }
    
    public func cancelDownloadTransfers() async throws {
        try await cancelTransfers(for: 0, sdk: sdk)
    }
    
    public func cancelUploadTransfers() async throws {
        try await cancelTransfers(for: 1, sdk: sdk)
    }
}
