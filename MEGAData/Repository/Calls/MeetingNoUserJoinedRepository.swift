
import Combine

final class MeetingNoUserJoinedRepository: NSObject, MeetingNoUserJoinedRepositoryProtocol {
    static var newRepo: MeetingNoUserJoinedRepository {
        MeetingNoUserJoinedRepository(chatSDK: MEGASdkManager.sharedMEGAChatSdk())
    }
    
    private var subscription: AnyCancellable?
        
    private let chatSDK: MEGAChatSdk
    private(set) var chatId: HandleEntity?
    private let source = PassthroughSubject<Void, Never>()
        
    var monitor: AnyPublisher<Void, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(chatSDK: MEGAChatSdk) {
        self.chatSDK = chatSDK
        super.init()
        chatSDK.add(self as MEGAChatCallDelegate)
    }
    
    deinit {
        chatSDK.remove(self as MEGAChatCallDelegate)
    }

    func start(timerDuration duration: TimeInterval, chatId: HandleEntity) {
        self.chatId = chatId
        subscription = Just(Void.self)
            .delay(for: .seconds(duration), scheduler: DispatchQueue.global())
            .sink() { _ in
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
    func onChatCallUpdate(_ api: MEGAChatSdk!, call: MEGAChatCall!) {
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
