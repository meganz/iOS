import Foundation

public protocol NodeValidationRepositoryProtocol: RepositoryProtocol {
    func hasVersions(nodeHandle: HandleEntity) -> Bool
    func isDownloaded(nodeHandle: HandleEntity) -> Bool
    func isInRubbishBin(nodeHandle: HandleEntity) -> Bool
    func isFileNode(handle: HandleEntity) -> Bool
    func isNode(_ node: NodeEntity, descendantOf ancestor: NodeEntity) async -> Bool
}
