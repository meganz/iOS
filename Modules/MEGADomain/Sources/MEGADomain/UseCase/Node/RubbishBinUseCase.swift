public protocol RubbishBinUseCaseProtocol {
    func isSyncDebrisNode(_ node: NodeEntity) async -> Bool
}

public struct RubbishBinUseCase<T: RubbishBinRepositoryProtocol>: RubbishBinUseCaseProtocol {
    private let rubbishBinRepository: T
    
    public init(rubbishBinRepository: T) {
        self.rubbishBinRepository = rubbishBinRepository
    }
    
    public func isSyncDebrisNode(_ node: NodeEntity) async -> Bool {
        await rubbishBinRepository.isSyncDebrisNode(node)
    }
}
