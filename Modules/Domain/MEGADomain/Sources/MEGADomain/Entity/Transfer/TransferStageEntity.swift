public enum TransferStageEntity: UInt, Sendable, Comparable {
    case none
    case scan
    case createTree
    case transferringFiles
    
    public static func < (lhs: TransferStageEntity, rhs: TransferStageEntity) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
