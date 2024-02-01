public protocol RubbishBinUseCaseProtocol {
    func isSyncDebrisNode(_ node: NodeEntity) -> Bool
    func cleanRubbishBin() 
}

public struct RubbishBinUseCase<T: RubbishBinRepositoryProtocol>: RubbishBinUseCaseProtocol {
    private let rubbishBinRepository: T
    
    public init(rubbishBinRepository: T) {
        self.rubbishBinRepository = rubbishBinRepository
    }
    
    public func isSyncDebrisNode(_ node: NodeEntity) -> Bool {
        rubbishBinRepository.isSyncDebrisNode(node)
    }
    
    public func cleanRubbishBin() {
        rubbishBinRepository.cleanRubbishBin()
    }
}
