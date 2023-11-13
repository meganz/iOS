import MEGADomain
import MEGASdk

public extension MEGATransferList {
    func toTransfers() -> [MEGATransfer] {
        guard size > 0 else { return [] }
        return (0..<size).compactMap { transfer(at: $0) }
    }
    
    func toTransferEntities() -> [TransferEntity] {
        guard size > 0 else { return [] }
        return (0..<size).compactMap { transfer(at: $0)?.toTransferEntity() }
    }
}
