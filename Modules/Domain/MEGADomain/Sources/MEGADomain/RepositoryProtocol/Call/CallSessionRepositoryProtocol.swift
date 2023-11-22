import Combine

public protocol CallSessionRepositoryProtocol {
    mutating func onCallSessionUpdate() -> AnyPublisher<ChatSessionEntity, Never>
}
