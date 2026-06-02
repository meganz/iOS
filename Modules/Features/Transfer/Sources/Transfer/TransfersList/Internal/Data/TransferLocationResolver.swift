import MEGADomain

/// Resolves the file system path shown on the Completed row's second line.
///
/// The two directions read from different sources, so resolution can't be a pure
/// transform of `TransferEntity`: uploads need an SDK lookup of the destination
/// folder's cloud path, while downloads use the local destination folder already
/// carried by the entity. This protocol confines the SDK-backed path to the Data
/// adapter and keeps the provider testable.
protocol TransferLocationResolving: Sendable {
    func location(for entity: TransferEntity) async -> String?
}

struct TransferLocationResolver: TransferLocationResolving {
    private let nodeUseCase: any NodeUseCaseProtocol
    private let nodeAttributeUseCase: any NodeAttributeUseCaseProtocol

    init(
        nodeUseCase: some NodeUseCaseProtocol,
        nodeAttributeUseCase: some NodeAttributeUseCaseProtocol
    ) {
        self.nodeUseCase = nodeUseCase
        self.nodeAttributeUseCase = nodeAttributeUseCase
    }

    func location(for entity: TransferEntity) async -> String? {
        switch entity.type {
        case .upload:
            guard let parent = await nodeUseCase.nodeForHandle(entity.parentHandle) else { return nil }
            return nodeAttributeUseCase.pathFor(node: parent)
        default:
            return entity.parentPath
        }
    }
}
