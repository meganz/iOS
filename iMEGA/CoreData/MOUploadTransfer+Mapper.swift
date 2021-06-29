
extension MOUploadTransfer {
    @objc func toUploadTransferEntity() -> UploadTransferEntity? {
        if let localIdentifier = localIdentifier, let parentNodeHandle = parentNodeHandle {
            return UploadTransferEntity(localIdentifier: localIdentifier,
                                        parentNodeHandle: parentNodeHandle)
        }
        
        return nil
    }
}
