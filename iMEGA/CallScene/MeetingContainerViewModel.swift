import Chat
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
    case presentShareLinkActivity(
        presenter: UIViewController?,
        sender: AnyObject,
        completion: UIActivityViewController.CompletionWithItemsHandler?
    )
    case shareLinkTappedBarButtonTapped(AnyObject)
    case presentShareLinkOptions(AnyObject)
    case shareLinkEmptyMeetingButtonTapped(AnyObject)
    case renameChat
    case dismissCall(completion: (() -> Void)?)
    case endGuestUserCall(completion: (() -> Void)?)
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
    private let callUpdateUseCase: any CallUpdateUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let authUseCase: any AuthUseCaseProtocol
    private let noUserJoinedUseCase: any MeetingNoUserJoinedUseCaseProtocol
    private let analyticsEventUseCase: any AnalyticsEventUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let callController: any CallControllerProtocol
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
        callUpdateUseCase: some CallUpdateUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        authUseCase: some AuthUseCaseProtocol,
        noUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol,
        analyticsEventUseCase: some AnalyticsEventUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol,
        callController: some CallControllerProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.router = router
        self.chatRoom = chatRoom
        self.callUseCase = callUseCase
        self.callUpdateUseCase = callUpdateUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatUseCase = chatUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.accountUseCase = accountUseCase
        self.authUseCase = authUseCase
        self.noUserJoinedUseCase = noUserJoinedUseCase
        self.analyticsEventUseCase = analyticsEventUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.callController = callController
        self.tracker = tracker
        
        subscribeToSeeWaitingRoomListNotification()
        monitorOnCallUpdate()
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
        case .presentShareLinkOptions(let sender):
            presentShareLinkOptions(from: sender)
        case .presentShareLinkActivity(let presenter, let sender, let completion):
            presentShareLinkActivity(presenter, sender, completion)
        case .shareLinkTappedBarButtonTapped(let sender):
            // tracking handled in the MeetingParticipantsLayoutViewModel
            presentShareLinkOptions(from: sender)
        case .shareLinkEmptyMeetingButtonTapped(let sender):
            // tracking handled in the MeetingParticipantsLayoutViewModel
            presentShareLinkOptions(from: sender)
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
        case .copyLinkTapped:
            copyLinkToClipboard()
        case .sendLinkToChatTapped:
            sendLinkToChat()
        case .inviteParticipantsTapped:
            trackInviteParticipantsPressed()
            router.notifyFloatingPanelInviteParticipants()
        }
    }
    
    private func trackInviteParticipantsPressed() {
        tracker.trackAnalyticsEvent(with: InviteParticipantsPressedEvent())
    }
    
    // MARK: - Private
    private func hangCall(presenter: UIViewController?, sender: UIButton?) {
        callController.endCall(in: chatRoom, endForAll: false)
    }
    
    private func endCallForAll() {
        callController.endCall(in: chatRoom, endForAll: true)
    }
    
    private func hangCall() {
        callController.endCall(in: chatRoom, endForAll: false)
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
            callController.muteCall(in: chatRoom, muted: true)
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
    
    private func presentShareLinkOptions(from sender: AnyObject) {
        let shareLinkOptions = ShareLinkOptions { [weak self] in
            self?.dispatch(.sendLinkToChatTapped)
        } copyLinkAction: { [weak self] in
            self?.dispatch(.copyLinkTapped)
        } shareLinkAction: { [weak self] presenter in
            self?.dispatch(
                .presentShareLinkActivity(
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
    
    private func presentShareLinkActivity(_ presenter: UIViewController?, _ sender: AnyObject, _ completion: UIActivityViewController.CompletionWithItemsHandler?) {
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
                let meetingDate = ScheduledMeetingDateBuilder(
                    scheduledMeeting: scheduledMeeting
                ).buildDateDescriptionString()
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
    
    private func monitorOnCallUpdate() {
        let callUpdates = callUpdateUseCase.monitorOnCallUpdate()
        Task { [weak self] in
            for await call in callUpdates {
                self?.onCallUpdate(call)
            }
        }
    }
    
    private func onCallUpdate(_ call: CallEntity) {
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
