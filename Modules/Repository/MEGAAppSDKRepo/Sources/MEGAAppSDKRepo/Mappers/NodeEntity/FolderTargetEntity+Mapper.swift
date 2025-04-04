import MEGADomain
import MEGASdk

extension FolderTargetEntity {
    public func toMEGAFolderTargetType() -> MEGAFolderTargetType {
        switch self {
        case .inShare:
            .inShare
        case .outShare:
            .outShare
        case .publicLink:
            .publicLink
        case .rootNode:
            .rootNode
        case .all:
            .all
        }
    }
    
    func toInt32() -> Int32 {
        Int32(toMEGAFolderTargetType().rawValue)
    }
}
