import Combine
import MEGAChatSdk
import MEGADomain

public final class MeetingNoUserJoinedRepository: NSObject, MeetingNoUserJoinedRepositoryProtocol {
    public static var newRepo: MeetingNoUserJoinedRepository {
        MeetingNoUserJoinedRepository(chatSDK: .sharedChatSdk)
    }

    private var subscription: AnyCancellable?
        
    private let chatSDK: MEGAChatSdk
    private(set) var chatId: HandleEntity?
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
        self.chatId = chatId
        subscription = Just(Void.self)
            .delay(for: .seconds(duration), scheduler: DispatchQueue.global())
            .sink { _ in
                self.source.send()
                self.cleanUp()
            }
    }
    
    private func cleanUp() {
        subscription?.cancel()
        subscription = nil
        chatId = nil
    }
}

extension MeetingNoUserJoinedRepository: MEGAChatCallDelegate {
    public func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
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
