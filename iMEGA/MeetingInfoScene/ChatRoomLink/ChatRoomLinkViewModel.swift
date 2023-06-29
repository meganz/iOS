
import Combine
import MEGADomain

final class ChatRoomLinkViewModel: ObservableObject {
    private var chatLinkUseCase: any ChatLinkUseCaseProtocol
    private let router: MeetingInfoRouting

    private var chatRoom: ChatRoomEntity
    private let scheduledMeeting: ScheduledMeetingEntity
    private let subtitle: String

    @Published var isMeetingLinkOn = false
    @Published var showShareMeetingLinkOptions = false
    @Published var showChatLinksMustHaveCustomTitleAlert = false

    private var isChatLinkFirstQuery = false
    private var subscriptions = Set<AnyCancellable>()
    private var meetingLink: String?

    init(router: MeetingInfoRouting,
         chatRoom: ChatRoomEntity,
         scheduledMeeting: ScheduledMeetingEntity,
         chatLinkUseCase: any ChatLinkUseCaseProtocol,
         subtitle: String) {
        self.router = router
        self.chatRoom = chatRoom
        self.scheduledMeeting = scheduledMeeting
        self.chatLinkUseCase = chatLinkUseCase
        self.subtitle = subtitle

        initSubscriptions()
        fetchInitialValues()
        listenToMeetingLinkToggleChange()
    }
    
    private func listenToMeetingLinkToggleChange() {
        $isMeetingLinkOn
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self, !isChatLinkFirstQuery else { return }
                update(enableMeetingLinkTo: newValue)
            }
            .store(in: &subscriptions)
    }
    
    private func fetchInitialValues() {
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
                if isChatLinkFirstQuery {
                    isMeetingLinkOn = link != nil
                    isChatLinkFirstQuery = false
                }
                meetingLink = link
            })
            .store(in: &subscriptions)
    }
    
    private func update(enableMeetingLinkTo isEnabled: Bool) {
        if isEnabled {
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
        ShareChatLinkOption.allCases
    }
    
    func shareOptionTapped(_ shareOption: ShareChatLinkOption) {
        guard let meetingLink else { return }
        switch shareOption {
        case .send:
            router.showSendToChat(meetingLink)
        case .copy:
            UIPasteboard.general.string = meetingLink
            router.showLinkCopied()
        case .share:
            router.showShareActivity(meetingLink,
                                     title: scheduledMeeting.title,
                                     description: subtitle)
        }
    }
}

enum ShareChatLinkOption: String, CaseIterable {
    case send
    case copy
    case share
    
    var localizedTitle: String {
        switch self {
        case .send:
            return Strings.Localizable.Meetings.Info.ShareOptions.sendToChat
        case .copy:
            return Strings.Localizable.copy
        case .share:
            return Strings.Localizable.General.share
        }
    }
}
