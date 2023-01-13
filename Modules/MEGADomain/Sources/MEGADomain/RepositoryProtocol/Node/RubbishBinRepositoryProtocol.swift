
public protocol RubbishBinRepositoryProtocol {
    func isSyncDebrisNode(_ node: NodeEntity) async -> Bool
}
