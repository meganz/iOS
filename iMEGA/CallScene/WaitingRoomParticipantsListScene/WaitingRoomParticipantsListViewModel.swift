import ChatRepo
import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation

protocol WaitingRoomParticipantsListRouting {
    func dismiss()
}

final class WaitingRoomParticipantsListViewModel: ObservableObject {
    private let router: any WaitingRoomParticipantsListRouting
    private var call: CallEntity
    private let callUseCase: any CallUseCaseProtocol
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol
    @Published private var limitBannerDismissed = false
    private var waitingRoomParticipants = [WaitingRoomParticipantViewModel]()
    
    private var participantLimitReached: Bool {
        guard let limitations else { return false }
        return limitations.hasReachedInCallFreeUserParticipantLimit(
            callParticipantCount: call.numberOfParticipants
        )
    }
    private var subscriptions = Set<AnyCancellable>()
    
    private var limitations: CallLimitations?
    
    @Published var displayWaitingRoomParticipants = [WaitingRoomParticipantViewModel]()
    @Published var isSearchActive: Bool
    @Published var searchText: String {
        didSet {
            searchTask = Task { @MainActor in
                filterWaitingRoomParticipants()
            }
        }
    }
    
    private var searchTask: Task<Void, Never>?
    
    init(
        router: some WaitingRoomParticipantsListRouting,
        call: CallEntity,
        callUseCase: some CallUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.router = router
        self.call = call
        self.callUseCase = callUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.searchText = ""
        self.isSearchActive = false
        
        if let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId) {
            self.limitations = .init(
                initialLimit: call.callLimits.maxUsers,
                chatRoom: chatRoom,
                callUseCase: callUseCase,
                chatRoomUseCase: chatRoomUseCase,
                featureFlagProvider: featureFlagProvider
            )
        }
        
        configureWaitingRoomListener(forCall: call)
        configureLimitationsObserver(for: call)
        populateWaitingRoomParticipants()
    }
    
    var bannerConfig: BannerView.Config? {
        guard
            participantLimitReached, !limitBannerDismissed
        else { return nil}
        
        return .init(
            copy: Strings.Localizable.Calls.FreePlanLimitWarning.WaitingRoomList.Banner.message,
            underline: false,
            theme: .dark,
            closeAction: dismissLimitBanner,
            tapAction: nil
        )
    }
    
    func closeTapped() {
        router.dismiss()
    }
    
    func dismissLimitBanner() {
        limitBannerDismissed = true
    }
    
    var admitAllButtonDisabled: Bool {
        participantLimitReached
    }
    
    var admitUserCellButtonDisabled: Bool {
        participantLimitReached
    }
    
    func admitAllTapped() {
        guard let userIds = call.waitingRoom?.userIds else { return }
        callUseCase.allowUsersJoinCall(call, users: userIds)
        router.dismiss()
    }
    
    // MARK: - Private
    
    @MainActor
    private func filterWaitingRoomParticipants() {
        guard !Task.isCancelled else { return }
        
        if searchText.isNotEmpty {
            displayWaitingRoomParticipants = waitingRoomParticipants.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        } else {
            displayWaitingRoomParticipants = waitingRoomParticipants
        }
    }
    
    private func populateWaitingRoomParticipants() {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId), let waitingRoomUserHandles = call.waitingRoom?.userIds else { return }
        
        let waitingRoomNonModeratorUserHandles = waitingRoomUserHandles.filter { chatRoomUseCase.peerPrivilege(forUserHandle: $0, chatRoom: chatRoom).isUserInWaitingRoom }
        
        waitingRoomParticipants = waitingRoomNonModeratorUserHandles.compactMap {
            WaitingRoomParticipantViewModel(
                chatRoomUseCase: chatRoomUseCase,
                chatRoomUserUseCase: ChatRoomUserUseCase(chatRoomRepo: ChatRoomUserRepository.newRepo, userStoreRepo: UserStoreRepository.newRepo),
                chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
                callUseCase: callUseCase,
                waitingRoomParticipantId: $0,
                chatRoom: chatRoom,
                call: call,
                admitButtonDisabled: admitUserCellButtonDisabled
            )
        }
        
        Task {
            await filterWaitingRoomParticipants()
        }
    }
    
    private func configureLimitationsObserver(for call: CallEntity) {
        limitations?.limitsChangedPublisher
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)
    }
    
    private func configureWaitingRoomListener(forCall call: CallEntity) {
        callUseCase.callWaitingRoomUsersUpdate(forCall: call)
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .sink { [weak self] call in
                self?.manageWaitingRoom(for: call)
            }
            .store(in: &subscriptions)
    }
    
    private func manageWaitingRoom(for call: CallEntity) {
        self.call = call
        populateWaitingRoomParticipants()
    }
}
