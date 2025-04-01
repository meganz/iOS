import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAL10n

final class ChatRoomLinkViewModel: ObservableObject {
    private let router: any MeetingInfoRouting
    private var chatRoom: ChatRoomEntity
    private let scheduledMeeting: ScheduledMeetingEntity
    private var chatLinkUseCase: any ChatLinkUseCaseProtocol
    private var chatUseCase: any ChatUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let subtitle: String

    @Published var isMeetingLinkOn = false
    @Published var isMeetingLinkUIEnabled = false
    @Published var showShareMeetingLinkOptions = false
    @Published var showChatLinksMustHaveCustomTitleAlert = false

    private var subscriptions = Set<AnyCancellable>()
    private var meetingLink: String?

    init(
        router: some MeetingInfoRouting,
        chatRoom: ChatRoomEntity,
        scheduledMeeting: ScheduledMeetingEntity,
        chatLinkUseCase: some ChatLinkUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        subtitle: String
    ) {
        self.router = router
        self.chatRoom = chatRoom
        self.scheduledMeeting = scheduledMeeting
        self.chatLinkUseCase = chatLinkUseCase
        self.chatUseCase = chatUseCase
        self.tracker = tracker
        self.subtitle = subtitle
        
        initSubscriptions()
        fetchInitialValues()
    }
    
    private func fetchInitialValues() {
        chatLinkUseCase.queryChatLink(for: chatRoom)
    }
    
    private func initSubscriptions() {
        self.chatLinkUseCase
            .monitorChatLinkUpdate(for: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogError("error fetching chat link \(error)")
            }, receiveValue: { [weak self] link in
                guard let self,
                      isMeetingLinkUIEnabled != true
                        || isMeetingLinkOn != (link != nil)
                        || meetingLink != link else {
                    return
                }
                
                isMeetingLinkUIEnabled = true
                isMeetingLinkOn = link != nil
                meetingLink = link
            })
            .store(in: &subscriptions)
    }
    
    func update(enableMeetingLinkTo isEnabled: Bool) {
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
        tracker.trackAnalyticsEvent(with: ScheduledMeetingShareMeetingLinkButtonEvent())
        showShareMeetingLinkOptions = true
    }
    
    func shareOptions() -> [ShareChatLinkOption] {
        ShareChatLinkOption.allCases
    }
    
    @MainActor
    func shareOptionTapped(_ shareOption: ShareChatLinkOption) {
        guard let meetingLink else { return }
        switch shareOption {
        case .send:
            router.sendLinkToChat(meetingLink)
        case .copy:
            UIPasteboard.general.string = meetingLink
            router.showLinkCopied()
        case .share:
            guard let url = URL(string: meetingLink) else { return }
            
            let metadataItemSource = ChatLinkPresentationItemSourceFactory.makeItemSource(
                title: scheduledMeeting.title,
                subtitle: subtitle,
                username: chatUseCase.myFullName() ?? "",
                url: url
            )
            
            router.showShareMeetingLinkActivity(
                meetingLink,
                metadataItemSource: metadataItemSource
            )
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
