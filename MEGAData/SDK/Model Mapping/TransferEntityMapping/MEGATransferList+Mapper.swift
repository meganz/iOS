import MEGADomain

extension MEGATransferList {
    func toTransfers() -> [MEGATransfer] {
        guard (size?.intValue ?? 0) > 0 else { return [] }
        return (0..<size.intValue).compactMap { transfer(at: $0) }
    }
    
    func toTransferEntities() -> [TransferEntity] {
        guard (size?.intValue ?? 0) > 0 else { return [] }
        return (0..<size.intValue).compactMap { transfer(at: $0).toTransferEntity() }
    }
}
