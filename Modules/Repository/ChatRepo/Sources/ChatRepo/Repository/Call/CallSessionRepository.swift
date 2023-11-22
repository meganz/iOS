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
    
    mutating public func onCallSessionUpdate() -> AnyPublisher<ChatSessionEntity, Never> {
        let onCallSessionUpdate = OnCallSessionUpdateListener(sdk: chatSdk)
        onCallSessionUpdateListener = onCallSessionUpdate

        return onCallSessionUpdate
            .monitor
    }
}

private final class OnCallSessionUpdateListener: NSObject, MEGAChatCallDelegate {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<ChatSessionEntity, Never>()
    
    var monitor: AnyPublisher<ChatSessionEntity, Never> {
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
        source.send(session.toChatSessionEntity())
    }
}
