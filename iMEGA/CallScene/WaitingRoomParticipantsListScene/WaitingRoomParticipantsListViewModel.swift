import ChatRepo
import Combine
import MEGADomain

protocol WaitingRoomParticipantsListRouting {
    func dismiss()
}

final class WaitingRoomParticipantsListViewModel: ObservableObject {
    private let router: any WaitingRoomParticipantsListRouting
    private var call: CallEntity

    private let callUseCase: any CallUseCaseProtocol
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol
    
    private var waitingRoomParticipants = [WaitingRoomParticipantViewModel]()

    private var subscriptions = Set<AnyCancellable>()

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
    
    init(router: some WaitingRoomParticipantsListRouting,
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
        
        configureWaitingRoomListener(forCall: call)
        populateWaitingRoomParticipants()
    }
    
    func closeTapped() {
        router.dismiss()
    }
    
    func admitAllTapped() {
        guard let sessionClientIds = call.waitingRoom?.sessionClientIds else { return }
        callUseCase.allowUsersJoinCall(call, users: sessionClientIds)
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
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId), let waitingRoomHandles = call.waitingRoom?.sessionClientIds else { return }
        
        let waitingRoomNonModeratorHandles = waitingRoomHandles.filter { chatRoomUseCase.peerPrivilege(forUserHandle: $0, chatRoom: chatRoom).isUserInWaitingRoom }

        waitingRoomParticipants = waitingRoomNonModeratorHandles.compactMap {
            WaitingRoomParticipantViewModel(chatRoomUseCase: chatRoomUseCase,
                                            chatRoomUserUseCase: ChatRoomUserUseCase(chatRoomRepo: ChatRoomUserRepository.newRepo, userStoreRepo: UserStoreRepository.newRepo),
                                            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo), 
                                            callUseCase: callUseCase,
                                            waitingRoomParticipantId: $0,
                                            chatRoom: chatRoom, 
                                            call: call)
        }
        
        Task {
            await filterWaitingRoomParticipants()
        }
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
