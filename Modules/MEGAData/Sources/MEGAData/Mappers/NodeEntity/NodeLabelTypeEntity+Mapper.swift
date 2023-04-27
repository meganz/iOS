import MEGADomain
import MEGASdk

extension MEGANodeLabel {
    public init?(nodeLabelTypeEntity: NodeLabelTypeEntity) {
        switch nodeLabelTypeEntity {
        case .unknown:
            self = .unknown
        case .red:
            self = .red
        case .orange:
            self = .orange
        case .yellow:
            self = .yellow
        case .green:
            self = .green
        case .blue:
            self = .blue
        case .purple:
            self = .purple
        case .grey:
            self = .grey
        }
    }
    
    public func toNodeLabelTypeEntity() -> NodeLabelTypeEntity {
        switch self {
        case .unknown:
            return .unknown
        case .red:
            return .red
        case .orange:
            return .orange
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .grey:
            return .grey
        @unknown default:
            return .unknown
        }
    }
}
