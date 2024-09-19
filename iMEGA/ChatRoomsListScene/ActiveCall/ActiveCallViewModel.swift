import Combine
import MEGADomain
import MEGAL10n

final class ActiveCallViewModel: ObservableObject {
    private var call: CallEntity
    private let router: any ChatRoomsListRouting
    private let activeCallUseCase: any ActiveCallUseCaseProtocol
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol

    @Published private(set) var muted: UIImage?
    @Published private(set) var video: UIImage?
    @Published private(set) var isReconnecting: Bool
    @Published private(set) var message: String = ""

    private var baseDate = Date()

    private var cancellableTimer: (any Cancellable)?

    private let timer = Timer.publish(every: 1, on: .main, in: .common)

    private var subscriptions = Set<AnyCancellable>()

    init(call: CallEntity,
         router: any ChatRoomsListRouting,
         activeCallUseCase: any ActiveCallUseCaseProtocol,
         chatRoomUseCase: any ChatRoomUseCaseProtocol
    ) {
        self.call = call
        self.router = router
        self.activeCallUseCase = activeCallUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.isReconnecting = call.status == .connecting
        self.muted = call.hasLocalAudio ? nil : UIImage(resource: .userMutedBanner)
        self.video = call.hasLocalVideo ? UIImage(resource: .callSlotsBanner) : nil
        
        initSubscriptions()
    }
    
    private func initSubscriptions() {
        activeCallUseCase.localAvFlagsChaged(forCallId: call.callId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] call in
                guard let self else { return }
                self.call = call
                self.muted = call.hasLocalAudio ? nil : UIImage(resource: .userMutedBanner)
                self.video = call.hasLocalVideo ? UIImage(resource: .callSlotsBanner) : nil
            }
            .store(in: &subscriptions)
        
        activeCallUseCase.callStatusChaged(forCallId: call.callId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] call in
                guard let self else { return }
                self.call = call
                self.isReconnecting = call.status == .connecting
                if self.isReconnecting {
                    self.message = Strings.Localizable.reconnecting
                }
            }
            .store(in: &subscriptions)

        updateDuration(interval: 0)
        initTimer()
    }
    
    private func initTimer() {
        cancellableTimer = timer
            .autoconnect()
            .map { [weak self] output in
                output.timeIntervalSince(self?.baseDate ?? Date())
            }
            .sink { [weak self] timeInterval in
                self?.updateDuration(interval: timeInterval)
            }
    }
    
    private func updateDuration(interval: TimeInterval) {
        if !isReconnecting {
            let interval = interval + TimeInterval(call.duration)
            message = Strings.Localizable.Chat.CallInProgress.tapToReturnToCall(interval.timeString)
        }
    }
    
    @MainActor
    func activeCallViewTapped() {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId) else { return }
        router.openCallView(for: call, in: chatRoom)
    }
}
