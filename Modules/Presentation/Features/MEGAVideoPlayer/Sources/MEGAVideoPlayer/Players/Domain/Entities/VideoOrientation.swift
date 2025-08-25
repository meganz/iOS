public enum VideoOrientation: String, CaseIterable, Sendable {
    case portrait
    case landscape
    
    /// Toggle to the next orientation
    public func toggled() -> VideoOrientation {
        switch self {
        case .portrait: .landscape
        case .landscape: .portrait
        }
    }
}
