import Combine
import MEGAChatSdk
import MEGADomain
import MEGASwift

public final class MeetingNoUserJoinedRepository: NSObject, MeetingNoUserJoinedRepositoryProtocol, @unchecked Sendable {
    public static let sharedRepo = MeetingNoUserJoinedRepository(chatSDK: .sharedChatSdk)
    
    @Atomic
    private var subscription: AnyCancellable?
        
    private let chatSDK: MEGAChatSdk
    
    @Atomic
    private var chatId: HandleEntity?
    
    private let source = PassthroughSubject<Void, Never>()
        
    public var monitor: AnyPublisher<Void, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(chatSDK: MEGAChatSdk) {
        self.chatSDK = chatSDK
        super.init()
        chatSDK.add(self as (any MEGAChatCallDelegate))
    }
    
    deinit {
        chatSDK.remove(self as (any MEGAChatCallDelegate))
    }

    public func start(timerDuration duration: TimeInterval, chatId: HandleEntity) {
        self.$chatId.mutate { $0 = chatId }
        let subscription = Just(Void.self)
            .delay(for: .seconds(duration), scheduler: DispatchQueue.global())
            .sink { _ in
                self.source.send()
                self.cleanUp()
            }
        $subscription.mutate {
            $0 = subscription
        }
    }
    
    private func cleanUp() {
        $subscription.wrappedValue?.cancel()
        $subscription.mutate { $0 = nil }
        $chatId.mutate { $0 = nil }
    }
}

extension MeetingNoUserJoinedRepository: MEGAChatCallDelegate {
    nonisolated public func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        if call.status == .inProgress,
           call.callCompositionChange == .peerAdded,
           call.chatId == chatId,
           call.peeridCallCompositionChange != chatSDK.myUserHandle {
            self.cleanUp()
        } else if call.status == .terminatingUserParticipation,
                    call.chatId == chatId {
            self.cleanUp()
        }
    }
}
