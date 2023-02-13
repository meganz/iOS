import MEGADomain

struct TransferRepository: TransferRepositoryProtocol {
    static var newRepo: TransferRepository {
        TransferRepository(sdk: MEGASdk.shared)
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func download(node: NodeEntity, to localUrl: URL) async throws -> TransferEntity {
        guard let megaNode = sdk.node(forHandle: node.handle) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            sdk.startDownloadNode(megaNode, localPath: localUrl.path, fileName: nil, appData: nil, startFirst: true, cancelToken: nil, delegate: TransferDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                switch result {
                case .success (let transfer):
                    continuation.resume(returning: transfer)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }
    
    func uploadFile(at fileUrl: URL, to parent: NodeEntity) async throws -> TransferEntity {
        guard let parentNode = sdk.node(forHandle: parent.handle) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            sdk.startUpload(withLocalPath: fileUrl.path, parent: parentNode, fileName: nil, appData: nil, isSourceTemporary: false, startFirst: true, cancelToken: nil, delegate: TransferDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                switch result {
                case .success (let transfer):
                    continuation.resume(returning: transfer)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }
}
