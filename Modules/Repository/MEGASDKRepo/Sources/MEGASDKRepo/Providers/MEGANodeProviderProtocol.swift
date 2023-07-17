import MEGADomain
import MEGASdk

public protocol MEGANodeProviderProtocol {
    func node(for handle: HandleEntity) async -> MEGANode?
}
