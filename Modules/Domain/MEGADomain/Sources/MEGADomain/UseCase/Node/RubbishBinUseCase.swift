import MEGASwift

public protocol RubbishBinUseCaseProtocol: Sendable {
    func isSyncDebrisNode(_ node: NodeEntity) -> Bool
    func cleanRubbishBin()
}

public struct RubbishBinUseCase<R: RubbishBinRepositoryProtocol>: RubbishBinUseCaseProtocol {
    private let rubbishBinRepository: R
    
    public init(rubbishBinRepository: R) {
        self.rubbishBinRepository = rubbishBinRepository
    }
    
    public func isSyncDebrisNode(_ node: NodeEntity) -> Bool {
        rubbishBinRepository.isSyncDebrisNode(node)
    }
    
    public func cleanRubbishBin() {
        rubbishBinRepository.cleanRubbishBin()
    }
}
