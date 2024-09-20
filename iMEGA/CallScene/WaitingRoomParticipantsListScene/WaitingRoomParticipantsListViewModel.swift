import ChatRepo
import Combine
import Chat
import MEGADomain
import MEGAL10n
import MEGAPresentation

protocol WaitingRoomParticipantsListRouting {
    func dismiss()
}

@MainActor
final class WaitingRoomParticipantsListViewModel: ObservableObject {
    private let router: any WaitingRoomParticipantsListRouting
    private var call: CallEntity
    private let callUseCase: any CallUseCaseProtocol
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol
    @Published private var limitBannerDismissed = false
    private var waitingRoomParticipants = [WaitingRoomParticipantViewModel]()
    
    @Published private var participantLimitReached: Bool = false
    @Published private var participantsPlusWaitingRoomLimitReached: Bool = false
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
        chatRoomUseCase: some ChatRoomUseCaseProtocol
    ) {
        self.router = router
        self.call = call
        self.callUseCase = callUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.searchText = ""
        self.isSearchActive = false
        if let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId) {
            let limitations = CallLimitations(
                initialLimit: call.callLimits.maxUsers,
                chatRoom: chatRoom,
                callUseCase: callUseCase,
                chatRoomUseCase: chatRoomUseCase
            )
            
            self.participantLimitReached = limitations.hasReachedInCallFreeUserParticipantLimit(
                callParticipantCount: call.numberOfParticipants
            )
            self.participantsPlusWaitingRoomLimitReached = limitations.hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit(
                callParticipantCount: call.numberOfParticipants,
                callParticipantsInWaitingRoom: waitingRoomParticipants.count
            )
            self.limitations = limitations
        }
        
        configureWaitingRoomListener(forCall: call)
        configureLimitationsObserver(for: call)
        populateWaitingRoomParticipants()
    }
    
    var bannerConfig: BannerView.Config? {
        guard
            participantLimitReached || participantsPlusWaitingRoomLimitReached, !limitBannerDismissed
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
        participantsPlusWaitingRoomLimitReached
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
                admitButtonDisabled: participantLimitReached
            )
        }
        
        checkParticipantsPlusWaitingRoomLimit()
        filterWaitingRoomParticipants()
    }
    
    private func configureLimitationsObserver(for call: CallEntity) {
        limitations?.limitsChangedPublisher
            .sink { [weak self] in
                self?.checkCallLimitsAndUpdateLimitsState()
            }
            .store(in: &subscriptions)
    }
    
    private func checkCallLimitsAndUpdateLimitsState() {
        // reading call properties again since they are likely changed now
        guard
            let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId),
            let call = callUseCase.call(for: chatRoom.chatId)
        else { return }
        self.call = call
        // right now we use static version of method to check limit
        // as the CallLimitations does not know current number of call participants
        // this should be added on next iteration
        participantLimitReached = CallLimitations.callParticipantsLimitReached(
            isMyselfModerator: true,
            currentLimit: call.callLimits.maxUsers,
            callParticipantCount: call.numberOfParticipants
        )
        checkParticipantsPlusWaitingRoomLimit()
        waitingRoomParticipants.forEach { $0.admitButtonDisabled = participantLimitReached }
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
    
    private func checkParticipantsPlusWaitingRoomLimit() {
        guard let limitations else { return }
        participantsPlusWaitingRoomLimitReached =  limitations.hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit(
            callParticipantCount: call.numberOfParticipants,
            callParticipantsInWaitingRoom: waitingRoomParticipants.count
        )
    }
}
