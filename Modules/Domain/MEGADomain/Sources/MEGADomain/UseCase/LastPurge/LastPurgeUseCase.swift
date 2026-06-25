import MEGASwift

public protocol LastPurgeUseCaseProtocol: Sendable {
    var lastPurgeEventSequence: AnyAsyncSequence<LastPurgeEventEntity> { get }
    func acknowledgeLastPurge(timestamp: Int64) async throws
}

public extension LastPurgeUseCaseProtocol {
    /// Async method to get the first inactivity purge event for the current session
    func inactivityPurgeEvent() async -> LastPurgeEventEntity? {
        await lastPurgeEventSequence.first { $0.isInactivity }
    }
}

public struct LastPurgeUseCase: LastPurgeUseCaseProtocol {
    private let repository: any LastPurgeRepositoryProtocol

    public init(repository: some LastPurgeRepositoryProtocol) {
        self.repository = repository
    }

    public var lastPurgeEventSequence: AnyAsyncSequence<LastPurgeEventEntity> {
        repository.lastPurgeSequence
    }

    public func acknowledgeLastPurge(timestamp: Int64) async throws {
        try await repository.acknowledgeLastPurge(timestamp: timestamp)
    }
}
