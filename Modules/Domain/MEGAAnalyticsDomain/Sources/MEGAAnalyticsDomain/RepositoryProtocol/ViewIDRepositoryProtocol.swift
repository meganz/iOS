import MEGADomain

public protocol ViewIDRepositoryProtocol: RepositoryProtocol, Sendable {
    func generateViewId() -> ViewID?
}
