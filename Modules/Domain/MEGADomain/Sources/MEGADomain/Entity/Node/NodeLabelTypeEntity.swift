public enum NodeLabelTypeEntity: Sendable, CaseIterable {
    case unknown
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case grey
}

extension NodeLabelTypeEntity {
    public var labelString: String {
        switch self {
        case .unknown: ""
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .green: "Green"
        case .blue: "Blue"
        case .purple: "Purple"
        case .grey: "Grey"
        }
    }
}
