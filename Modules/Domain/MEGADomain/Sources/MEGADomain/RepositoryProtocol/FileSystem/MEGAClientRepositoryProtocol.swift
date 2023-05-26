import Foundation

public protocol MEGAClientRepositoryProtocol: RepositoryProtocol {
    func doesExistNodesOnDemandDatabase(for session: String) -> Bool
}
