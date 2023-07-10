import MEGADomain

public protocol ViewIDRepositoryProtocol: RepositoryProtocol {
    func generateViewId() -> ViewID?
}
