import MEGASwift

public protocol RubbishBinRepositoryProtocol: Sendable {
    func isSyncDebrisNode(_ node: NodeEntity) -> Bool
    func cleanRubbishBin()
}
