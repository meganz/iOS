public enum VideoScalingMode: Equatable, Sendable {
    /// Video fits within the viewport, maintaining aspect ratio without cropping
    case fit
    /// Video fills the entire viewport, cropping along the minor axis as needed
    case fill

    func toggled() -> Self {
        switch self {
        case .fit: .fill
        case .fill: .fit
        }
    }
}
