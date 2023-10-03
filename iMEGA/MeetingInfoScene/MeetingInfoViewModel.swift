import Combine
import MEGADomain
import MEGAPresentation
import SwiftUI

protocol MeetingInfoRouting {
    func showSharedFiles(for chatRoom: ChatRoomEntity)
    func showManageChatHistory(for chatRoom: ChatRoomEntity)
    func showEnableKeyRotation(for chatRoom: ChatRoomEntity)
    func closeMeetingInfoView()
    func showLeaveChatAlert(leaveAction: @escaping(() -> Void))
    func showShareActivity(_ link: String, title: String?, description: String?)
    func showSendToChat(_ link: String)
    func showLinkCopied()
    func showParticipantDetails(email: String, userHandle: HandleEntity, chatRoom: ChatRoomEntity, didUpdatePeerPermission: @escaping (ChatRoomParticipantPrivilege) -> Void)
    func inviteParticipants(
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        excludeParticipantsId: Set<HandleEntity>,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    )
    func showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory)
    func showNoAvailableContactsAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory)
    func edit(meeting: ScheduledMeetingEntity) -> AnyPublisher<ScheduledMeetingEntity, Never>
}

final class MeetingInfoViewModel: ObservableObject {
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private var userImageUseCase: any UserImageUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private var chatLinkUseCase: any ChatLinkUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let router: any MeetingInfoRouting
    @Published var showWaitingRoomWarningBanner = false
    @Published var isWaitingRoomOn = false
    @Published var isAllowNonHostToAddParticipantsOn = true
    @Published var isPublicChat = true
    @Published var isUserInChat = true
    @Published var isModerator = false
    
    var shouldAllowEditingWaitingRoom: Bool {
        guard let chatRoom = chatRoom else { return false }
        return !chatUseCase.isCallInProgress(for: chatRoom.chatId)
    }
    
    @PreferenceWrapper(key: .waitingRoomWarningBannerDismissed, defaultValue: false, useCase: PreferenceUseCase.default)
    var waitingRoomWarningBannerDismissed: Bool

    private var chatRoom: ChatRoomEntity?
    private var subscriptions = Set<AnyCancellable>()

    var chatRoomNotificationsViewModel: ChatRoomNotificationsViewModel?
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    @Published var chatRoomLinkViewModel: ChatRoomLinkViewModel?
    var chatRoomParticipantsListViewModel: ChatRoomParticipantsListViewModel?

    var meetingLink: String?
    
    @Published var subtitle: String = ""
    @Published var scheduledMeeting: ScheduledMeetingEntity
    
    lazy var isWaitingRoomFeatureEnabled = featureFlagProvider.isFeatureFlagEnabled(for: .waitingRoom)
    
    init(scheduledMeeting: ScheduledMeetingEntity,
         router: some MeetingInfoRouting,
         chatRoomUseCase: some ChatRoomUseCaseProtocol,
         chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
         userImageUseCase: some UserImageUseCaseProtocol,
         chatUseCase: some ChatUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         chatLinkUseCase: some ChatLinkUseCaseProtocol,
         megaHandleUseCase: some MEGAHandleUseCaseProtocol,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.scheduledMeeting = scheduledMeeting
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.userImageUseCase = userImageUseCase
        self.chatUseCase = chatUseCase
        self.accountUseCase = accountUseCase
        self.chatLinkUseCase = chatLinkUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.featureFlagProvider = featureFlagProvider
        self.chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId)
        
        if let chatRoom {
            self.chatRoomAvatarViewModel = ChatRoomAvatarViewModel(
                title: chatRoom.title ?? "",
                peerHandle: .invalid,
                chatRoomEntity: chatRoom,
                chatRoomUseCase: chatRoomUseCase,
                chatRoomUserUseCase: chatRoomUserUseCase,
                userImageUseCase: userImageUseCase,
                chatUseCase: chatUseCase,
                accountUseCase: accountUseCase,
                megaHandleUseCase: megaHandleUseCase
            )
            self.isModerator = chatRoom.ownPrivilege.toChatRoomParticipantPrivilege() == .moderator
        } else {
            self.chatRoomAvatarViewModel = nil
        }
        self.subtitle = ScheduledMeetingDateBuilder(scheduledMeeting: scheduledMeeting, chatRoom: chatRoom).buildDateDescriptionString()
        $waitingRoomWarningBannerDismissed.useCase = preferenceUseCase
        initSubscriptions()
        fetchInitialValues()
        listenToIsAllowNonHostToAddParticipantsOnChange()
        listenToIsWaitingRoomOnChange()
    }
    
    private func listenToIsAllowNonHostToAddParticipantsOnChange() {
        $isAllowNonHostToAddParticipantsOn
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self, newValue != chatRoom?.isOpenInviteEnabled else { return }
                Task {
                    await self.allowNonHostToAddParticipantsValueChanged(to: newValue)
                }
            }
            .store(in: &subscriptions)
    }
    
    private func listenToIsWaitingRoomOnChange() {
        $isWaitingRoomOn
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self, newValue != chatRoom?.isWaitingRoomEnabled else { return }
                Task {
                    await self.waitingRoomValueChanged(to: newValue)
                }
            }
            .store(in: &subscriptions)
    }
    
    private func fetchInitialValues() {
        guard let chatRoom else { return }
        isAllowNonHostToAddParticipantsOn = chatRoom.isOpenInviteEnabled
        isWaitingRoomOn = chatRoom.isWaitingRoomEnabled
        isPublicChat = chatRoom.isPublicChat
        isUserInChat = chatRoom.ownPrivilege.isUserInChat
        chatLinkUseCase.queryChatLink(for: chatRoom)
        chatRoomNotificationsViewModel = ChatRoomNotificationsViewModel(chatRoom: chatRoom)
        if chatRoom.ownPrivilege == .moderator {
            chatRoomLinkViewModel = chatRoomLinkViewModel(for: chatRoom)
        } else {
            Task { @MainActor in
                do {
                    _ = try await chatLinkUseCase.queryChatLink(for: chatRoom)
                    chatRoomLinkViewModel = chatRoomLinkViewModel(for: chatRoom)
                } catch { }
            }
        }
        
        chatRoomParticipantsListViewModel = ChatRoomParticipantsListViewModel(
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            chatUseCase: chatUseCase,
            accountUseCase: accountUseCase,
            chatRoom: chatRoom)
    }
    
    private func chatRoomLinkViewModel(for chatRoom: ChatRoomEntity) -> ChatRoomLinkViewModel {
        ChatRoomLinkViewModel(
            router: router,
            chatRoom: chatRoom,
            scheduledMeeting: scheduledMeeting,
            chatLinkUseCase: chatLinkUseCase,
            subtitle: subtitle)
    }
    
    private func initSubscriptions() {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) else { return }
        chatRoomUseCase.allowNonHostToAddParticipantsValueChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogError("error fetching allow host to add participants with error \(error)")
            }, receiveValue: { [weak self] _ in
                guard let self = self,
                      let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.scheduledMeeting.chatId) else {
                    return
                }
                self.chatRoom = chatRoom
                self.isAllowNonHostToAddParticipantsOn = chatRoom.isOpenInviteEnabled
            })
            .store(in: &subscriptions)
        
        chatRoomUseCase.waitingRoomValueChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.scheduledMeeting.chatId) else {
                    return
                }
                self.chatRoom = chatRoom
                self.isWaitingRoomOn = chatRoom.isWaitingRoomEnabled
            }
            .store(in: &subscriptions)
        
        chatUseCase
            .monitorChatPrivateModeUpdate(forChatId: scheduledMeeting.chatId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogError("error fetching private mode \(error)")
            }, receiveValue: { [weak self] chatRoom in
                self?.chatRoom = chatRoom
                self?.isPublicChat = chatRoom.isPublicChat
            })
            .store(in: &subscriptions)
        
        chatRoomUseCase.ownPrivilegeChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed privilege \(error)")
            }, receiveValue: { [weak self] _ in
                guard  let self,
                       let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.scheduledMeeting.chatId) else {
                    return
                }
                self.chatRoom = chatRoom
                self.isModerator = chatRoom.ownPrivilege.toChatRoomParticipantPrivilege() == .moderator
                self.isUserInChat = chatRoom.ownPrivilege.isUserInChat
            })
            .store(in: &subscriptions)
        
        Publishers.CombineLatest3($isModerator, $isWaitingRoomOn, $isAllowNonHostToAddParticipantsOn)
            .dropFirst(waitingRoomWarningBannerDismissed ? 3 : 0)
            .map { $0 && $1 && $2 }
            .removeDuplicates()
            .sink(receiveValue: { [weak self] show in
                guard let self else { return }
                withAnimation {
                    self.showWaitingRoomWarningBanner = show
                }
                if show {
                    waitingRoomWarningBannerDismissed = false
                }
            })
            .store(in: &subscriptions)
    }
}

extension MeetingInfoViewModel {
    // MARK: - Open Invite
    @MainActor func allowNonHostToAddParticipantsValueChanged(to enabled: Bool) {
        Task {
            do {
                guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) else { return }
                isAllowNonHostToAddParticipantsOn = try await chatRoomUseCase.allowNonHostToAddParticipants(enabled, forChatRoom: chatRoom)
            } catch {
                MEGALogDebug("Unable to set the isAllowNonHostToAddParticipantsOn to \(enabled) for \(scheduledMeeting.chatId)")
            }
        }
    }
    
    // MARK: - Waiting Room
    @MainActor func waitingRoomValueChanged(to enabled: Bool) {
        Task {
            do {
                guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) else { return }
                isWaitingRoomOn = try await chatRoomUseCase.waitingRoom(enabled, forChatRoom: chatRoom)
            } catch {
                MEGALogDebug("Unable to set the isWaitingRoomOn to \(enabled) for \(scheduledMeeting.chatId)")
            }
        }
    }
    
    // MARK: - SharedFiles
    func sharedFilesViewTapped() {
        guard let chatRoom else {
            return
        }
        router.showSharedFiles(for: chatRoom)
    }
    
    // MARK: - Chat History
    func manageChatHistoryViewTapped() {
        guard let chatRoom else {
            return
        }
        router.showManageChatHistory(for: chatRoom)
    }
    
    // MARK: - Key Rotation
    func enableEncryptionKeyRotationViewTapped() {
        guard let chatRoom else {
            return
        }
        router.showEnableKeyRotation(for: chatRoom)
    }
    
    // MARK: - Share link non host
    func shareMeetingLinkViewTapped() {
        guard let chatRoomLinkViewModel else {
            return
        }
        chatRoomLinkViewModel.showShareMeetingLinkOptions = true
    }
    
    // MARK: - Leave group
    func leaveGroupViewTapped() {
        guard let chatRoom else {
            return
        }
        
        if chatRoom.isPreview {
            chatRoomUseCase.closeChatRoomPreview(chatRoom: chatRoom)
            router.closeMeetingInfoView()
        } else {
            router.showLeaveChatAlert { [weak self] in
                guard let self = self, let stringChatId = self.megaHandleUseCase.base64Handle(forUserHandle: chatRoom.chatId) else {
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
    
    // MARK: - Edit meeting
    func editTapped() {
        router
            .edit(meeting: scheduledMeeting)
            .sink { [weak self] meeting in
                guard let self else { return }
                scheduledMeeting = meeting
                subtitle = ScheduledMeetingDateBuilder(scheduledMeeting: meeting, chatRoom: chatRoom).buildDateDescriptionString()
            }
            .store(in: &subscriptions)
    }
    
    func isChatPreview() -> Bool {
        chatRoom?.isPreview ?? false
    }
}
