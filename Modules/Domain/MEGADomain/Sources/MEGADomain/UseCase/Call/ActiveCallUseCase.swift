import Combine

public protocol ActiveCallUseCaseProtocol {
    func localAvFlagsChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never>
    func callStatusChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never>
}

public struct ActiveCallUseCase<T: CallRepositoryProtocol>: ActiveCallUseCaseProtocol {
    
    private var callRepository: T

    public init(callRepository: T) {
        self.callRepository = callRepository
    }
    
    public func localAvFlagsChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never> {
        callRepository.localAvFlagsChaged(forCallId: callId)
    }
    
    public func callStatusChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never> {
        callRepository.callStatusChaged(forCallId: callId)
    }
}
