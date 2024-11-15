import MEGASwift

public protocol RequestStatProgressUseCaseProtocol: Sendable {
    /// - Returns: an AsyncSequence that emits event updates related to reqStatProgress, per mil progress or -1 in the EventEntity number property
    var requestStatsProgress: AnyAsyncSequence<EventEntity> { get }
}

public struct RequestStatProgressUseCase<T: EventRepositoryProtocol>: RequestStatProgressUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public var requestStatsProgress: AnyAsyncSequence<EventEntity> {
        repo
            .event
            .filter { $0.type == .reqStatProgress }
            .eraseToAnyAsyncSequence()
    }
}
