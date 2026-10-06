import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPickerFileProviderDomain
import MEGASdk
import MEGASwift

public struct FileProviderDownloadRepository: FileProviderDownloadRepositoryProtocol {
    public static var newRepo: FileProviderDownloadRepository {
        FileProviderDownloadRepository(sdk: .sharedSdk)
    }

    private let sdk: MEGASdk

    init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    public func download(node: NodeEntity, to url: URL, progress: @escaping @Sendable (Int) -> Void) async throws {
        guard let megaNode = sdk.node(forHandle: node.handle) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        // The SDK cancels a transfer whose token is cancelled even while it is running, and finishes it as
        // cancelled after deleting the partial file.
        let cancelToken = ThreadSafeCancelToken()
        // Over quota, the SDK does not fail the transfer: it reports a temporary error and retries once the quota is
        // available again, which can take a very long time, so Files would wait on the download all that time. The transfer is
        // cancelled instead, and finishes as over quota rather than as cancelled.
        let isOverQuota = Atomic(wrappedValue: false)
        try await withTaskCancellationHandler {
            try await withAsyncThrowingVoidValue { completion in
                let delegate = TransferDelegate(
                    progress: { progress($0.transferredBytes) },
                    completion: { result in
                        switch result {
                        case .success:
                            completion(.success)
                        case .failure(let error):
                            let wasCancelledForQuota = error == .cancelled && isOverQuota.wrappedValue
                            completion(.failure(wasCancelledForQuota ? TransferErrorEntity.overquota : error))
                        }
                    },
                    temporaryError: { _, error in
                        guard error.type == .quotaExceeded else { return }
                        isOverQuota.mutate { $0 = true }
                        cancelToken.cancel()
                    }
                )
                sdk.startDownloadNode(
                    megaNode,
                    localPath: url.path,
                    fileName: nil,
                    appData: nil,
                    startFirst: true,
                    cancelToken: cancelToken.value,
                    collisionCheck: .fingerprint,
                    collisionResolution: .overwrite,
                    delegate: delegate
                )
            }
        } onCancel: {
            cancelToken.cancel()
        }
    }
}
