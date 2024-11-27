import MEGADomain
import MEGASdk
import MEGASwift

public struct TransferRepository: TransferRepositoryProtocol {
    public static var newRepo: TransferRepository {
        TransferRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
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
}
