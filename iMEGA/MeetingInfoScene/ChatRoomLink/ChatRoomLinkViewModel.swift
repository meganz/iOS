
import MEGADomain
import Combine

final class ChatRoomLinkViewModel: ObservableObject {
    private var chatLinkUseCase: ChatLinkUseCaseProtocol
    private let router: MeetingInfoRouting

    private var chatRoom: ChatRoomEntity
    private let scheduledMeeting: ScheduledMeetingEntity

    @Published var isMeetingLinkOn = false
    @Published var isMeetingLinkDisabled = false
    @Published var showShareMeetingLinkOptions = false
    @Published var showChatLinksMustHaveCustomTitleAlert = false

    private var isChatLinkFirstQuery = false
    private var subscriptions = Set<AnyCancellable>()

    var meetingLink: String?

    init(router: MeetingInfoRouting,
         chatRoom: ChatRoomEntity,
         scheduledMeeting: ScheduledMeetingEntity,
         chatLinkUseCase: ChatLinkUseCaseProtocol) {
        self.router = router
        self.chatRoom = chatRoom
        self.scheduledMeeting = scheduledMeeting
        self.chatLinkUseCase = chatLinkUseCase

        fetchInitialValues()
        initSubscriptions()
    }
    
    private func fetchInitialValues() {
        isMeetingLinkDisabled = chatRoom.ownPrivilege != .moderator
        isChatLinkFirstQuery = true
        chatLinkUseCase.queryChatLink(for: chatRoom)
    }
    
    private func initSubscriptions() {
        self.chatLinkUseCase
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
    
    func meetingLinkValueChanged(to enabled: Bool) {
        guard !isChatLinkFirstQuery else {
            isChatLinkFirstQuery = false
            return
        }
        
        if meetingLink == nil {
            if chatRoom.hasCustomTitle {
                chatLinkUseCase.createChatLink(for: chatRoom)
            } else {
                showChatLinksMustHaveCustomTitleAlert = true
                isMeetingLinkOn = false
            }
        } else {
            chatLinkUseCase.removeChatLink(for: chatRoom)
        }
    }
    
    func shareMeetingLinkTapped() {
        showShareMeetingLinkOptions = true
    }
    
    func shareOptions() -> [ShareChatLinkOption] {
        [.send, .copy, .share, .cancel]
    }
    
    func shareOptionTapped(_ shareOption: ShareChatLinkOption) {
        guard let meetingLink else { return }
        switch shareOption {
        case .send:
            router.showSendToChat(meetingLink)
        case .copy:
            router.showLinkCopied()
        case .share:
            router.showShareActivity(meetingLink,
                                     title: scheduledMeeting.title,
                                     description: scheduledMeeting.description)
        case .cancel:
            showShareMeetingLinkOptions = false
        }
    }
}

enum ShareChatLinkOption: String, CaseIterable {
    case send
    case copy
    case share
    case cancel
    
    var localizedTitle: String {
        switch self {
        case .send:
            return Strings.Localizable.General.sendToChat
        case .copy:
            return Strings.Localizable.copy
        case .share:
            return Strings.Localizable.General.share
        case .cancel:
            return Strings.Localizable.cancel
        }
    }
}
