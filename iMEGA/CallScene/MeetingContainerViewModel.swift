import Combine
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation

enum MeetingContainerAction: ActionType {
    case onViewReady
    case hangCall(presenter: UIViewController?, sender: UIButton?)
    case tapOnBackButton
    case changeMenuVisibility
    case showOptionsMenu(presenter: UIViewController, sender: UIBarButtonItem, isMyselfModerator: Bool)
    case hideOptionsMenu
    case shareLink(presenter: UIViewController?, sender: AnyObject, completion: UIActivityViewController.CompletionWithItemsHandler?)
    case renameChat
    case dismissCall(completion: (() -> Void)?)
    case endGuestUserCall(completion: (() -> Void)?)
    case speakerEnabled(_ enabled: Bool)
    case displayParticipantInMainView(_ participant: CallParticipantEntity)
    case didDisplayParticipantInMainView(_ participant: CallParticipantEntity)
    case didSwitchToGridView
    case participantAdded
    case participantRemoved
    case showEndCallDialogIfNeeded
    case removeEndCallAlertAndEndCall
    case showJoinMegaScreen
    case endCallForAll
    case participantJoinedWaitingRoom
    case showScreenShareWarning
    case leaveCallFromRecordingAlert
    case showMutedBy(String)
    case showCallWillEndAlert(timeToEndCall: Double, completion: ((Double) -> Void))
    case transitionToLongForm
    // this one is to hide snack bar when user swipes to show participant list
    case willTransitionToLongForm
    case inviteParticipantsTapped
    case shareLinkTapped(AnyObject)
    case copyLinkTapped
    case sendLinkToChatTapped
}

/**
 layout is set CallCollectionView and stored on the MeetingParticipantsLayoutViewModel
 it can be changed via nav bar in the MeetingParticipantLayoutViewController
 or via CallControlsView -> Action Sheet menu
 class below is used for exchange information between MeetingsFloatingPanel and MeetingsParticipantLayout
 about the state of the layout toggle
 */
class ParticipantLayoutUpdateChannel {
    var updateLayout: ((ParticipantsLayoutMode) -> Void)?
    var getCurrentLayout: (() -> ParticipantsLayoutMode)?
    var layoutSwitchingEnabled: (() -> Bool)?
}

@MainActor
final class MeetingContainerViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
    }
    
    private enum Constants {
        static let muteMicTimerDuration = 60 // 1 minute
    }
    
    private let router: any MeetingContainerRouting
    private let chatRoom: ChatRoomEntity
    private let callUseCase: any CallUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let authUseCase: any AuthUseCaseProtocol
    private let noUserJoinedUseCase: any MeetingNoUserJoinedUseCaseProtocol
    private let analyticsEventUseCase: any AnalyticsEventUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let callManager: any CallManagerProtocol
    private let tracker: any AnalyticsTracking
    
    private var noUserJoinedSubscription: AnyCancellable?
    private var muteMicSubscription: AnyCancellable?
    private var muteUnmuteFailedNotificationsSubscription: AnyCancellable?
    private var seeWaitingRoomListEventSubscription: AnyCancellable?
    private var callUpdateSubscription: AnyCancellable?
    
    private var call: CallEntity? {
        callUseCase.call(for: chatRoom.chatId)
    }
    
    private var isOneToOneChat: Bool {
        chatRoomUseCase.chatRoom(forChatId: chatRoom.chatId)?.chatType == .oneToOne
    }
    
    init(
        router: some MeetingContainerRouting,
        chatRoom: ChatRoomEntity,
        callUseCase: some CallUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        authUseCase: some AuthUseCaseProtocol,
        noUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol,
        analyticsEventUseCase: some AnalyticsEventUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol,
        callManager: some CallManagerProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.router = router
        self.chatRoom = chatRoom
        self.callUseCase = callUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatUseCase = chatUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.accountUseCase = accountUseCase
        self.authUseCase = authUseCase
        self.noUserJoinedUseCase = noUserJoinedUseCase
        self.analyticsEventUseCase = analyticsEventUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.callManager = callManager
        self.tracker = tracker
        
        subscribeToSeeWaitingRoomListNotification()
        subscribeToOnCallUpdate()
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    func dispatch(_ action: MeetingContainerAction) {
        switch action {
        case .onViewReady:
            router.showMeetingUI(containerViewModel: self)
            if isOneToOneChat == false {
                muteMicSubscription = Just(Void.self)
                    .delay(for: .seconds(Constants.muteMicTimerDuration), scheduler: RunLoop.main)
                    .sink { [weak self] _ in
                        guard let self else { return }
                        
                        muteMicrophoneIfNoOtherParticipantsArePresent()
                        muteMicSubscription = nil
                    }
                
                noUserJoinedSubscription = noUserJoinedUseCase
                    .monitor
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in
                        guard let self else { return }
                        
                        showEndCallDialogIfNeeded {
                            self.cancelNoUserJoinedSubscription()
                        }
                        noUserJoinedSubscription = nil
                    }
            }
            tracker.trackAnalyticsEvent(with: CallScreenEvent())
        case .hangCall(let presenter, let sender):
            hangCall(presenter: presenter, sender: sender)
        case .tapOnBackButton:
            router.dismiss(animated: true, completion: nil)
        case .changeMenuVisibility:
            router.toggleFloatingPanel(containerViewModel: self)
        case .showOptionsMenu(let presenter, let sender, let isMyselfModerator):
            router.toggleFloatingPanel(containerViewModel: self)
            router.showOptionsMenu(presenter: presenter, sender: sender, isMyselfModerator: isMyselfModerator, containerViewModel: self)
        case .hideOptionsMenu:
            router.toggleFloatingPanel(containerViewModel: self)
        case .shareLink(let presenter, let sender, let completion):
            shareLink(presenter, sender, completion)
        case .renameChat:
            router.renameChat()
        case .dismissCall(let completion):
            hangAndDismissCall(completion: completion)
        case .endGuestUserCall(let completion):
            hangAndDismissCall {
                if self.accountUseCase.isGuest {
                    self.authUseCase.logout()
                }
                
                guard let completion = completion else { return }
                completion()
            }
        case .speakerEnabled(let speakerEnabled):
            router.enableSpeaker(speakerEnabled)
        case .displayParticipantInMainView(let participant):
            router.displayParticipantInMainView(participant)
        case .didDisplayParticipantInMainView(let participant):
            router.didDisplayParticipantInMainView(participant)
        case .didSwitchToGridView:
            router.didSwitchToGridView()
        case .participantAdded:
            cancelMuteMicrophoneSubscription()
            cancelNoUserJoinedSubscription()
            router.removeEndCallDialog(finishCountDown: true, completion: nil)
        case .participantRemoved:
            muteMicrophoneIfNoOtherParticipantsArePresent()
        case .showEndCallDialogIfNeeded:
            showEndCallDialogIfNeeded()
        case .removeEndCallAlertAndEndCall:
            removeEndCallAlertAndEndCall()
        case .showJoinMegaScreen:
            router.showJoinMegaScreen()
        case .endCallForAll:
            endCallForAll()
        case .participantJoinedWaitingRoom:
            router.removeEndCallDialog(finishCountDown: false, completion: nil)
        case .showScreenShareWarning:
            router.showScreenShareWarning()
        case .leaveCallFromRecordingAlert:
            endCall()
        case .showMutedBy(let name):
            router.showMutedMessage(by: name)
        case .showCallWillEndAlert(let timeToEndCall, let completion):
            router.showCallWillEndAlert(timeToEndCall: timeToEndCall, completion: completion)
        case .transitionToLongForm:
            router.showFloatingPanelIfNeeded(
                containerViewModel: self,
                completion: { [weak self] in
                    self?.router.transitionToLongForm()
                }
            )
        case .willTransitionToLongForm:
            router.hideSnackBar()
        case .shareLinkTapped(let sender):
            shareLink(from: sender)
        case .copyLinkTapped:
            copyLinkToClipboard()
        case .sendLinkToChatTapped:
            sendLinkToChat()
        case .inviteParticipantsTapped:
            router.notifyFloatingPanelInviteParticipants()
        }
    }
    
    // MARK: - Private
    private func hangCall(presenter: UIViewController?, sender: UIButton?) {
        callManager.endCall(in: chatRoom, endForAll: false)
    }
    
    private func endCallForAll() {
        callManager.endCall(in: chatRoom, endForAll: true)
    }
    
    private func hangCall() {
        callManager.endCall(in: chatRoom, endForAll: false)
    }
    
    private func hangAndDismissCall(completion: (() -> Void)?) {
        hangCall()
        router.dismiss(animated: true, completion: completion)
    }
    
    private func muteMicrophoneIfNoOtherParticipantsArePresent() {
        if let call = call,
           call.hasLocalAudio,
           isOneToOneChat == false,
           isOnlyMyselfInTheMeeting() {
            callManager.muteCall(in: chatRoom, muted: true)
        }
    }
    
    private func isOnlyMyselfInTheMeeting() -> Bool {
        guard let call = call,
              call.numberOfParticipants == 1,
              call.participants.first == accountUseCase.currentUserHandle else {
            return false
        }
        
        return true
    }
    
    private func showEndCallDialogIfNeeded(stayOnCallCompletion: (() -> Void)? = nil) {
        guard isOnlyMyselfInTheMeeting() else { return }
        router.showEndCallDialog { [weak self] in
            guard let self else { return }
            self.analyticsEventUseCase.sendAnalyticsEvent(.meetings(.endCallInNoParticipantsPopup))
            self.endCall()
        } stayOnCallCompletion: { [weak self] in
            guard let self else { return }
            self.analyticsEventUseCase.sendAnalyticsEvent(.meetings(.stayOnCallInNoParticipantsPopup))
            stayOnCallCompletion?()
        }
    }
    
    private func cancelMuteMicrophoneSubscription() {
        muteMicSubscription?.cancel()
        muteMicSubscription = nil
    }
    
    private func cancelNoUserJoinedSubscription() {
        noUserJoinedSubscription?.cancel()
        noUserJoinedSubscription = nil
    }
    
    private func removeEndCallAlertAndEndCall() {
        router.removeEndCallDialog(finishCountDown: true) { [weak self] in
            guard let self else { return }
            self.endCall()
        }
    }
    
    private func endCall() {
        if accountUseCase.isGuest {
            self.dispatch(.endGuestUserCall {
                self.dispatch(.showJoinMegaScreen)
            })
        } else {
            self.hangAndDismissCall(completion: nil)
        }
    }
    
    private func subscribeToSeeWaitingRoomListNotification() {
        seeWaitingRoomListEventSubscription = NotificationCenter
            .default
            .publisher(for: .seeWaitingRoomListEvent)
            .sink { [weak self] _ in
                guard let self else { return }
                router.selectWaitingRoomList(containerViewModel: self)
            }
    }
    
    var floatingPanelShown: Bool {
        router.floatingPanelShown
    }
    
    private func shareLink(from sender: AnyObject) {
        tracker.trackAnalyticsEvent(with: ShareLinkBarButtonPressedEvent())
        let shareLinkOptions = ShareLinkOptions(
            sender: sender) { [weak self] in
                self?.dispatch(.sendLinkToChatTapped)
            } copyLinkAction: { [weak self] in
                self?.dispatch(.copyLinkTapped)
            } shareLinkAction: { [weak self] presenter in
                self?.dispatch(
                    .shareLink(
                        presenter: presenter,
                        sender: sender,
                        completion: nil
                    )
                )
            }
        router.showShareLinkOptionsAlert(shareLinkOptions)
    }
    
    private func copyLinkToClipboard() {
        tracker.trackAnalyticsEvent(with: CopyLinkToPasteboardPressedEvent())
        Task {
            do {
                let link = try await chatRoomUseCase.fetchPublicLink(forChatRoom: chatRoom)
                router.showLinkCopied()
                UIPasteboard.general.string = link
            } catch {
                router.showShareMeetingError()
            }
        }
    }
    
    private func sendLinkToChat() {
        tracker.trackAnalyticsEvent(with: SendLinkToChatPressedEvent())
        Task {
            do {
                let link = try await chatRoomUseCase.fetchPublicLink(forChatRoom: chatRoom)
                router.sendLinkToChat(link)
            } catch {
                router.showShareMeetingError()
            }
        }
    }
    
    private func shareLink(_ presenter: UIViewController?, _ sender: AnyObject, _ completion: UIActivityViewController.CompletionWithItemsHandler?) {
        tracker.trackAnalyticsEvent(with: ShareLinkPressedEvent())
        Task {
            do {
                let link = try await chatRoomUseCase.fetchPublicLink(forChatRoom: chatRoom)
                let metadataItemSource = try await prepareMetadataItemSource(for: link)
                
                router.showShareChatLinkActivity(
                    presenter: presenter,
                    sender: sender,
                    link: link,
                    metadataItemSource: metadataItemSource,
                    isGuestAccount: accountUseCase.isGuest,
                    completion: completion
                )
            } catch {
                router.showShareMeetingError()
            }
        }
    }
    
    private func prepareMetadataItemSource(for link: String) async throws -> ChatLinkPresentationItemSource {
        guard let url = URL(string: link) else {
            throw ChatLinkErrorEntity.generic
        }
        var title = (chatRoom.title ?? "") + "\n" + link
        var subject = ""
        var message = ""
        if chatRoom.isMeeting {
            subject = Strings.Localizable.Meetings.Info.ShareMeetingLink.subject
            message =
            Strings.Localizable.Meetings.Info.ShareMeetingLink.invitation((chatUseCase.myFullName() ?? "")) + "\n" +
            Strings.Localizable.Meetings.Info.ShareMeetingLink.meetingName(chatRoom.title ?? "")
            if let scheduledMeeting = scheduledMeetingUseCase.scheduledMeetingsByChat(chatId: chatRoom.chatId).first {
                let meetingDate = ScheduledMeetingDateBuilder(scheduledMeeting: scheduledMeeting, chatRoom: chatRoom).buildDateDescriptionString()
                title = scheduledMeeting.title + "\n" + meetingDate
                message += "\n" +
                Strings.Localizable.Meetings.Info.ShareMeetingLink.meetingTime(meetingDate)
            }
            message += "\n" + Strings.Localizable.Meetings.Info.ShareMeetingLink.meetingLink(link)
        } else {
            title = chatRoom.title ?? ""
            message = title + "\n" + link
        }
        return ChatLinkPresentationItemSource(
            title: title,
            subject: subject,
            message: message,
            url: url
        )
    }
    
    private func subscribeToOnCallUpdate() {
        callUpdateSubscription = callUseCase.onCallUpdate()
            .sink { [weak self] call in
                self?.onChatCallUpdate(for: call)
            }
    }
    
    private func onChatCallUpdate(for call: CallEntity) {
        guard call.changeType == .status else { return }
        switch call.status {
        case .terminatingUserParticipation, .destroyed:
            manageCallTerminatedForGuestUserIfNeeded(call)
            manageCallTerminatedErrorIfNeeded(call)
        default:
            break
        }
    }
    
    private func manageCallTerminatedErrorIfNeeded(_ call: CallEntity) {
        switch call.termCodeType {
        case .tooManyParticipants:
            hangAndDismissCall {
                SVProgressHUD.showError(withStatus: Strings.Localizable.Error.noMoreParticipantsAreAllowedInThisGroupCall)
            }
        case .protocolVersion:
            hangCall()
            router.showProtocolErrorAlert()
        case .callUsersLimit:
            hangCall()
            if accountUseCase.isGuest {
                tracker.trackAnalyticsEvent(with: IOSGuestEndCallFreePlanUsersLimitDialogEvent())
            }
            router.showUsersLimitErrorAlert()
        case .callDurationLimit:
            if call.isOwnClientCaller { // or is chat room organiser - future implementation
                hangCall()
                guard let accountDetails = accountUseCase.currentAccountDetails else { return }
                tracker.trackAnalyticsEvent(with: UpgradeToProToGetUnlimitedCallsDialogEvent())
                router.showUpgradeToProDialog(accountDetails)
            } else {
                hangAndDismissCall(completion: nil)
            }
        default:
            router.dismiss(animated: true, completion: nil)
        }
    }
    
    private func manageCallTerminatedForGuestUserIfNeeded(_ call: CallEntity) {
        if call.status == .terminatingUserParticipation && accountUseCase.isGuest {
            self.dispatch(.endGuestUserCall {
                self.dispatch(.showJoinMegaScreen)
            })
        }
    }
}
