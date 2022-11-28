import MEGADomain
import Combine

protocol MeetingInfoRouting {
    func showSharedFiles(for chatRoom: ChatRoomEntity)
    func showManageChatHistory(for chatRoom: ChatRoomEntity)
    func showEnableKeyRotation(for chatRoom: ChatRoomEntity)
    func showChatLinksMustHaveCustomTitleAlert()
    func closeMeetingInfoView()
    func showLeaveChatAlert(leaveAction: @escaping(() -> Void))
}

final class MeetingInfoViewModel: ObservableObject {
    private let chatListItem: ChatListItemEntity
    private var chatRoomUseCase: ChatRoomUseCaseProtocol
    private var userImageUseCase: UserImageUseCaseProtocol
    private let chatUseCase: ChatUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol
    private var chatLinkUseCase: ChatLinkUseCaseProtocol
    private let router: MeetingInfoRouting
    @Published var isMeetingLinkOn = false
    @Published var isMeetingLinkDisabled = false
    @Published var isAllowNonHostToAddParticipantsOn = true
    @Published var isPublicChat = true
    @Published var isUserInChat = true

    private var isChatLinkFirstQuery = false
    private var isAllowNonHostToAddParticipantsRemote = false
    private var chatRoom: ChatRoomEntity?
    private var subscriptions = Set<AnyCancellable>()

    var chatRoomNotificationsViewModel: ChatRoomNotificationsViewModel?
    var chatRoomAvatarViewModel: ChatRoomAvatarViewModel

    var meetingLink: String?
    
    init(chatListItem: ChatListItemEntity,
         router: MeetingInfoRouting,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         userImageUseCase: UserImageUseCaseProtocol,
         chatUseCase: ChatUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         chatLinkUseCase: ChatLinkUseCaseProtocol
    ) {
        self.chatListItem = chatListItem
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.userImageUseCase = userImageUseCase
        self.chatUseCase = chatUseCase
        self.userUseCase = userUseCase
        self.chatLinkUseCase = chatLinkUseCase
        self.chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId)
        self.isMeetingLinkDisabled = chatRoom?.ownPrivilege != .moderator
        self.chatRoomAvatarViewModel =  ChatRoomAvatarViewModel(
            chatListItem: chatListItem,
            chatRoomUseCase: chatRoomUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: chatUseCase,
            userUseCase: userUseCase
        )
        initSubscriptions()
        fetchInitialValues()
    }
    
    private func fetchInitialValues() {
        guard let chatRoom else { return }
        isAllowNonHostToAddParticipantsOn = chatRoom.isOpenInviteEnabled
        isPublicChat = chatRoom.isPublicChat
        isChatLinkFirstQuery = true
        chatLinkUseCase.queryChatLink(for: chatRoom)
        chatRoomNotificationsViewModel = ChatRoomNotificationsViewModel(chatRoom: chatRoom)
    }
    
    private func initSubscriptions() {
        chatRoomUseCase.allowNonHostToAddParticipantsValueChanged(forChatId: chatListItem.chatId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogError("error fetching allow host to add participants with error \(error)")
            }, receiveValue: { [weak self] handle in
                guard let self = self,
                      let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatListItem.chatId) else {
                    return
                }
                self.isAllowNonHostToAddParticipantsRemote = true
                self.chatRoom = chatRoom
                self.isAllowNonHostToAddParticipantsOn = chatRoom.isOpenInviteEnabled
            })
            .store(in: &subscriptions)
        
        chatUseCase
            .monitorChatPrivateModeUpdate(forChatId: chatListItem.chatId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogError("error fetching private mode \(error)")
            }, receiveValue: { [weak self] chatRoom in
                self?.chatRoom = chatRoom
                self?.isPublicChat = chatRoom.isPublicChat
            })
            .store(in: &subscriptions)
        
        guard let chatRoom else { return }

        chatLinkUseCase
            .monitorChatLinkUpdate(for: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogError("error fetching chat link \(error)")
            }, receiveValue: { [weak self] link in
                guard let self else { return }
                if self.isChatLinkFirstQuery {
                    if link == nil {
                        self.isChatLinkFirstQuery = false
                    } else {
                        self.isMeetingLinkOn.toggle()
                    }
                }
                self.meetingLink = link
            })
            .store(in: &subscriptions)
    }
}

extension MeetingInfoViewModel{
    //MARK: - Meeting Link
    func meetingLinkValueChanged(to enabled: Bool) {
        guard !isChatLinkFirstQuery else {
            isChatLinkFirstQuery = false
            return
        }
        
        guard let chatRoom else { return }
        
        if meetingLink == nil {
            if chatRoom.hasCustomTitle {
                chatLinkUseCase.createChatLink(for: chatRoom)
            } else {
                router.showChatLinksMustHaveCustomTitleAlert()
            }
        } else {
            chatLinkUseCase.removeChatLink(for: chatRoom)
        }
    }
    
    func shareMeetingLinkTapped() {
        print("[cma] Link tapped: \(String(describing: meetingLink))")
    }
    
    //MARK: - Open Invite
    func allowNonHostToAddParticipantsValueChanged(to enabled: Bool) {
        guard !isAllowNonHostToAddParticipantsRemote else {
            isAllowNonHostToAddParticipantsRemote = false
            return
        }
        
        Task{
            do {
                isAllowNonHostToAddParticipantsOn = try await chatRoomUseCase.allowNonHostToAddParticipants(enabled: isAllowNonHostToAddParticipantsOn, chatId: chatListItem.chatId)
            } catch {
                
            }
        }
    }
    
    //MARK: - SharedFiles
    func sharedFilesViewTapped() {
        guard let chatRoom else {
            return
        }
        router.showSharedFiles(for: chatRoom)
    }
    
    //MARK: - Chat History
    func manageChatHistoryViewTapped() {
        guard let chatRoom else {
            return
        }
        router.showManageChatHistory(for: chatRoom)
    }
    
    //MARK: - Key Rotation
    func enableEncryptionKeyRotationViewTapped() {
        guard let chatRoom else {
            return
        }
        router.showEnableKeyRotation(for: chatRoom)
    }
    
    //MARK: - Leave group
    func leaveGroupViewTapped() {
        guard let chatRoom else {
            return
        }
        
        if chatRoom.isPreview {
            chatRoomUseCase.closeChatRoomPreview(chatRoom: chatRoom)
            router.closeMeetingInfoView()
        } else {
            router.showLeaveChatAlert { [weak self] in
                guard let self = self, let stringChatId = MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) else {
                    return
                }
                MEGALinkManager.joiningOrLeavingChatBase64Handles.add(stringChatId)
                Task {
                    let success = await self.chatRoomUseCase.leaveChatRoom(chatRoom: chatRoom)
                    if success {
                        MEGALinkManager.joiningOrLeavingChatBase64Handles.remove(stringChatId)
                    }
                }
                self.router.closeMeetingInfoView()
            }
        }
    }
    
    func isChatPreview() -> Bool {
        chatRoom?.isPreview ?? false
    }
}
