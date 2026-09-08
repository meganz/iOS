import MEGADomain

extension CancellableTransfer {
    /// Maps this transfer to the entity handed to a `CancellableTransferUseCaseProtocol`.
    ///
    /// - Important: Map at the point the transfer is started, not earlier: `name` is mutated while
    ///   the flow runs, and the entity is a snapshot that would not pick the new value up. It is set
    ///   when a name collision is resolved with "Rename", which `resolvedUploadOptions` folds into
    ///   the upload options here.
    var cancellableTransferEntity: CancellableTransferEntity {
        CancellableTransferEntity(
            handle: handle,
            parentHandle: parentHandle,
            messageId: messageId,
            chatId: chatId,
            fileLinkURL: fileLinkURL,
            localFileURL: localFileURL,
            appData: appData,
            startFirst: priority,
            isFile: isFile,
            type: type.toCancellableTransferTypeEntity(),
            uploadOptions: resolvedUploadOptions,
            name: name
        )
    }
}

private extension CancellableTransferType {
    func toCancellableTransferTypeEntity() -> CancellableTransferTypeEntity {
        switch self {
        case .download: .download
        case .upload: .upload
        case .downloadChat: .downloadChat
        case .downloadFileLink: .downloadFileLink
        }
    }
}
