import MEGADomain
import MEGASdk

public extension MEGATransferList {
    func toTransfers() -> [MEGATransfer] {
        let size = size.intValue
        guard size > 0 else { return [] }
        return (0..<size).compactMap { transfer(at: $0) }
    }
    
    func toTransferEntities() -> [TransferEntity] {
        let size = size.intValue
        guard size > 0 else { return [] }
        return (0..<size).compactMap { transfer(at: $0)?.toTransferEntity() }
    }
}
