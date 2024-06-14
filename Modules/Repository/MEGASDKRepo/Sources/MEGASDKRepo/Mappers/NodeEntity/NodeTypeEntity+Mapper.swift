import MEGADomain
import MEGASdk

extension MEGANodeType {
    public func toNodeTypeEntity() -> NodeTypeEntity {
        switch self {
        case .file:
            .file
        case .folder:
            .folder
        case .root:
            .root
        case .incoming:
            .incoming
        case .rubbish:
            .rubbish
        case .unknown:
            .unknown
        @unknown default:
            .unknown
        }
    }
}

extension NodeTypeEntity {
    public func toMEGANodeType() -> MEGANodeType {
        switch self {
        case .unknown:
            .unknown
        case .file:
            .file
        case .folder:
            .folder
        case .root:
            .root
        case .incoming:
            .incoming
        case .rubbish:
            .rubbish
        }
    }
}
