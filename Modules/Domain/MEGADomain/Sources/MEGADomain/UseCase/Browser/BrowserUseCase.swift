import MEGASwift

public protocol BrowserUseCaseProtocol: Sendable {
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> { get }
    var copyRequestStartUpdates: AnyAsyncSequence<Void> { get }
    var requestFinishUpdates: AnyAsyncSequence<RequestEntity> { get }
}

public struct BrowserUseCase: BrowserUseCaseProtocol {
    private let requestStatesRepository: any RequestStatesRepositoryProtocol
    private let nodeRepository: any NodeRepositoryProtocol
    
    public init(
        requestStatesRepository: some RequestStatesRepositoryProtocol,
        nodeRepository: some NodeRepositoryProtocol
    ) {
        self.requestStatesRepository = requestStatesRepository
        self.nodeRepository = nodeRepository
    }
    
    public var copyRequestStartUpdates: AnyAsyncSequence<Void> {
        requestStatesRepository.requestStartUpdates
            .compactMap { $0.type == .copy ? () : nil }
            .eraseToAnyAsyncSequence()
    }
    
    public var requestFinishUpdates: AnyAsyncSequence<RequestEntity> {
        requestStatesRepository
            .completedRequestUpdates
            .filter { $0.type == .copy || $0.type == .getAttrFile }
            .eraseToAnyAsyncSequence()
    }
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        nodeRepository.nodeUpdates
    }
}
