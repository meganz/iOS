import Combine
import MEGAChatSdk
import MEGADomain

public struct CallSessionRepository: CallSessionRepositoryProtocol {
    public static var newRepo: CallSessionRepository {
        CallSessionRepository(chatSdk: .sharedChatSdk)
    }
    
    private let chatSdk: MEGAChatSdk
    private var onCallSessionUpdateListener: OnCallSessionUpdateListener?
    
    public init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }
    
    public mutating func onCallSessionUpdate() -> AnyPublisher<(ChatSessionEntity, CallEntity), Never> {
        let onCallSessionUpdate = OnCallSessionUpdateListener(sdk: chatSdk)
        onCallSessionUpdateListener = onCallSessionUpdate

        return onCallSessionUpdate
            .monitor
    }
}

private final class OnCallSessionUpdateListener: NSObject, MEGAChatCallDelegate {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<(ChatSessionEntity, CallEntity), Never>()
    
    var monitor: AnyPublisher<(ChatSessionEntity, CallEntity), Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self, queueType: .globalBackground)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onChatSessionUpdate(_ api: MEGAChatSdk, chatId: UInt64, callId: UInt64, session: MEGAChatSession) {
        guard let call = api.chatCall(forCallId: callId) else { return }
        source.send((session.toChatSessionEntity(), call.toCallEntity()))
    }
}
