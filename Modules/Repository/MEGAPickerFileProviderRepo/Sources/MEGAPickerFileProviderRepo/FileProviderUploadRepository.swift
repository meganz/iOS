import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPickerFileProviderDomain
import MEGASdk
import MEGASwift

public struct FileProviderUploadRepository: FileProviderUploadRepositoryProtocol {
    public static var newRepo: FileProviderUploadRepository {
        FileProviderUploadRepository(sdk: .sharedSdk)
    }

    private let sdk: MEGASdk

    init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    public func upload(
        fileAt url: URL,
        named name: String,
        to parent: NodeEntity,
        modificationDate: Date?,
        progress: @escaping @Sendable (Int) -> Void
    ) async throws -> NodeEntity {
        let options = UploadOptionsEntity(
            fileName: name,
            mtime: modificationDate.map { Int64($0.timeIntervalSince1970) } ?? UploadOptionsEntity.invalidCustomModTime,
            // The file belongs to the system, which removes it once the upload has been reported.
            isSourceTemporary: false,
            startFirst: true
        )
        // Cancelled like a download in `FileProviderDownloadRepository`, including over quota.
        let cancelToken = ThreadSafeCancelToken()
        let isOverQuota = Atomic(wrappedValue: false)
        let transfer = try await withTaskCancellationHandler {
            try await withAsyncThrowingValue { (completion: @escaping @Sendable (Result<TransferEntity, any Error>) -> Void) in
                let delegate = TransferDelegate(
                    progress: { progress($0.transferredBytes) },
                    completion: { result in
                        switch result {
                        case .success(let transfer):
                            completion(.success(transfer))
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
                sdk.startUpload(
                    withLocalPath: url.path,
                    parentHandle: parent.handle,
                    cancelToken: cancelToken.value,
                    options: options.toMEGAUploadOptions(),
                    delegate: delegate
                )
            }
        } onCancel: {
            cancelToken.cancel()
        }
        guard let node = sdk.node(forHandle: transfer.nodeHandle) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        return node.toNodeEntity()
    }

    public func fingerprint(ofFileAt url: URL, modificationDate: Date?) -> String? {
        guard let modificationDate else {
            return sdk.fingerprint(forFilePath: url.path)
        }
        return sdk.fingerprint(forFilePath: url.path, modificationTime: modificationDate)
    }
}
