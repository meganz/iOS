import MEGADomain
import Combine

final class ActiveCallViewModel: ObservableObject {
    private var call: CallEntity
    private let router: ChatRoomsListRouting
    private let activeCallUseCase: ActiveCallUseCaseProtocol
    private var chatRoomUseCase: ChatRoomUseCaseProtocol

    @Published private(set) var muted: UIImage?
    @Published private(set) var video: UIImage?
    @Published private(set) var isReconnecting: Bool
    @Published private(set) var message: String = ""

    private var baseDate = Date()

    private var cancellableTimer: Cancellable?

    private let timer = Timer.publish(every: 1, on: .main, in: .common)

    private var subscriptions = Set<AnyCancellable>()

    init(call: CallEntity,
         router: ChatRoomsListRouting,
         activeCallUseCase: ActiveCallUseCaseProtocol,
         chatRoomUseCase: ChatRoomUseCaseProtocol
    ) {
        self.call = call
        self.router = router
        self.activeCallUseCase = activeCallUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.isReconnecting = call.status == .connecting
        self.muted = call.hasLocalAudio ? nil : UIImage(asset: Asset.Images.Chat.Calls.userMutedBanner)
        self.video = call.hasLocalVideo ? UIImage(asset: Asset.Images.Chat.Calls.callSlotsBanner) : nil
        
        initSubscriptions()
    }
    
    private func initSubscriptions() {
        activeCallUseCase.localAvFlagsChaged(forCallId: call.callId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] call in
                guard let self else { return }
                self.call = call
                self.muted = call.hasLocalAudio ? nil : UIImage(asset: Asset.Images.Chat.Calls.userMutedBanner)
                self.video = call.hasLocalVideo ? UIImage(asset: Asset.Images.Chat.Calls.callSlotsBanner) : nil
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
            guard let durationString = interval.timeDisplayString() else { return }
            message = Strings.Localizable.touchToReturnToCall(durationString)
        }
    }
    
    func activeCallViewTapped() {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId) else { return }
        router.openCallView(for: call, in: chatRoom)
    }
}
