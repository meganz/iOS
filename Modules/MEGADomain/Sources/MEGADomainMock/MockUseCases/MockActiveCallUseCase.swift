import Combine
import MEGADomain

public struct MockActiveCallUseCase: ActiveCallUseCaseProtocol {
    
    public var callUpdatePublisher: PassthroughSubject<CallEntity, Never>

    public init(
        callUpdatePublisher: PassthroughSubject<CallEntity, Never> = PassthroughSubject<CallEntity, Never>()
    ) {
        self.callUpdatePublisher = callUpdatePublisher
    }
    
    public func localAvFlagsChaged(forCallId callId: MEGADomain.HandleEntity) -> AnyPublisher<MEGADomain.CallEntity, Never> {
        callUpdatePublisher.eraseToAnyPublisher()
    }
    
    public func callStatusChaged(forCallId callId: MEGADomain.HandleEntity) -> AnyPublisher<MEGADomain.CallEntity, Never> {
        callUpdatePublisher.eraseToAnyPublisher()
    }
}
