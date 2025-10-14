import MEGASwift

public protocol RubbishBinUseCaseProtocol: Sendable {
    func isSyncDebrisNode(_ node: NodeEntity) -> Bool
    func cleanRubbishBin()
    func cleanRubbishBin(_ completion: (@Sendable () -> Void)?)
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
    
    public func cleanRubbishBin(_ completion: (@Sendable () -> Void)?) {
        rubbishBinRepository.cleanRubbishBin(completion)
    }
}
