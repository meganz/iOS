
extension MOUploadTransfer {
    @objc func toUploadTransferEntity() -> TransferRecordDTO? {
        if let localIdentifier = localIdentifier, let parentNodeHandle = parentNodeHandle {
            return TransferRecordDTO(localIdentifier: localIdentifier,
                                        parentNodeHandle: parentNodeHandle)
        }
        
        return nil
    }
}
