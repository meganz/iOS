import ChatRepo
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASDKRepo

extension GroupChatDetailsViewController {
    @objc var userPrivilegeIsAboveReadOnly: Bool {
        chatRoom.ownPrivilege.rawValue > MEGAChatRoomPrivilege.ro.rawValue
    }
    
    @objc var shouldShowGetChatLinkButton: Bool {
        userPrivilegeIsAboveReadOnly && chatRoom.isPublicChat && !chatRoom.isPreview
    }

    @objc func trackLeaveMeetingRowTapped() {
        DIContainer.tracker.trackAnalyticsEvent(with: MeetingInfoLeaveMeetingButtonTappedEvent())
    }
    
    @objc func trackAddParticipantsRowTapped() {
        DIContainer.tracker.trackAnalyticsEvent(with: MeetingInfoAddParticipantButtonTappedEvent())
    }
    
    @objc func addChatCallDelegate() {
        MEGAChatSdk.shared.add(self as (any MEGAChatCallDelegate))
    }
    
    @objc func removeChatCallDelegate() {
        MEGAChatSdk.shared.remove(self as (any MEGAChatCallDelegate))
    }
    
    @objc func addChatRoomDelegate() {
        guard let chatRoom else { return }
        MEGAChatSdk.shared.addChatRoomDelegate(chatRoom.chatId, delegate: self)
    }
    
    @objc func removeChatRoomDelegate() {
        guard let chatRoom else { return }
        MEGAChatSdk.shared.removeChatRoomDelegate(chatRoom.chatId, delegate: self)
    }
    
    @objc func shouldShowAddParticipants() -> Bool {
        guard let chatRoom else { return false }
        let chatRoomPrivilege = chatRoom.ownPrivilege.toChatRoomPrivilegeEntity()
        return (chatRoom.ownPrivilege == .moderator || chatRoom.isOpenInviteEnabled) && !MEGASdk.isGuest && chatRoomPrivilege.isUserInChat
    }
    
    @objc func openChatRoom(chatId: HandleEntity, delegate: any MEGAChatRoomDelegate) {
        guard let chatRoom = ChatRoomRepository.newRepo.chatRoom(forChatId: chatId) else { return }
        
        if ChatRoomRepository.newRepo.isChatRoomOpen(chatRoom) {
            ChatRoomRepository.newRepo.closeChatRoom(chatId: chatRoom.chatId, delegate: delegate)
        }
        try? ChatRoomRepository.newRepo.openChatRoom(chatId: chatRoom.chatId, delegate: delegate)
    }
    
    var callsManager: any CallsManagerProtocol {
        CallsManager.shared
    }
    
    var callController: any CallControllerProtocol {
        CallControllerProvider().provideCallController()
    }
    
    var callUseCase: some CallUseCaseProtocol {
        CallUseCase(repository: CallRepository.newRepo)
    }
    
    @objc func showEndCallForAll() {
        let endCallDialog = EndCallDialog(
            type: .endCallForAll,
            forceDarkMode: false,
            autodismiss: true
        ) { [weak self] in
            self?.endCallDialog = nil
        } endCallAction: { [weak self] in
            guard let self else { return }
            
            let statsRepoSitory = AnalyticsRepository(sdk: MEGASdk.shared)
            AnalyticsEventUseCase(repository: statsRepoSitory).sendAnalyticsEvent(.meetings(.endCallForAll))
            
            let chatRoomEntity = chatRoom.toChatRoomEntity()
            
            // when user is inside the call, we use callManager to end the call and
            // let CallKit know about this [MEET-4151]
            if callsManager.callUUID(forChatRoom: chatRoomEntity) != nil {
                callController.endCall(in: chatRoomEntity, endForAll: true)
            } else if let call = callUseCase.call(for: chatRoomEntity.chatId) {
                // but when current user left (call manager doesn't know about the call)
                // the call and this user is a host [only then he can see 'end for all
                // option], we use callUseCase directly to end the call for all
                callUseCase.endCall(for: call.callId)
            }
            
            self.navigationController?.popViewController(animated: true)
        }
        
        endCallDialog.show()
        self.endCallDialog = endCallDialog
    }
    
    private func createParticipantsAddingViewFactory() -> ParticipantsAddingViewFactory {
        ParticipantsAddingViewFactory(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            chatRoom: chatRoom.toChatRoomEntity()
        )
    }
    
    private func showInviteContacts() {
        guard let inviteController = createParticipantsAddingViewFactory().inviteContactController() else { return }
        navigationController?.pushViewController(inviteController, animated: true)
    }
    
    private func changeChatNotificationStatus(sender: UISwitch) {
        if sender.isOn {
            chatNotificationControl.turnOffDND(chatId: ChatIdEntity(chatRoom.chatId))
        } else {
            chatNotificationControl.turnOnDND(chatId: ChatIdEntity(chatRoom.chatId), isChatTypeMeeting: chatRoom.isMeeting, sender: sender)
        }
    }
    
    @objc func addParticipant() {
        let participantsAddingViewFactory = createParticipantsAddingViewFactory()
        
        guard participantsAddingViewFactory.hasVisibleContacts else {
            let noAvailableContactsAlert = participantsAddingViewFactory.noAvailableContactsAlert(inviteAction: showInviteContacts)
            present(noAvailableContactsAlert, animated: true)
            return
        }
        
        guard participantsAddingViewFactory.hasNonAddedVisibleContacts(withExcludedHandles: []) else {
            let allContactsAlreadyAddedAlert = participantsAddingViewFactory.allContactsAlreadyAddedAlert(inviteAction: showInviteContacts)
            present(allContactsAlreadyAddedAlert, animated: true)
            return
        }
        
        let contactsNavigationController = participantsAddingViewFactory.addContactsViewController(
            withContactsMode: .chatAddParticipant,
            additionallyExcludedParticipantsId: nil
        ) { [weak self] handles in
            guard let self else { return }
            for handle in handles {
                MEGAChatSdk.shared.invite(
                    toChat: self.chatRoom.chatId,
                    user: handle,
                    privilege: MEGAChatRoomPrivilege.standard.rawValue
                )
            }
        }
        
        guard let contactsNavigationController = contactsNavigationController else { return }
        present(contactsNavigationController, animated: true)
    }
    
    @objc func configureAllowNonHostToAddParticipantsCell(_ cell: GroupChatDetailsViewTableViewCell) {
        cell.nameLabel.text = Strings.Localizable.Meetings.AddContacts.AllowNonHost.message
        cell.leftImageView.image = UIImage.addContact
        cell.controlSwitch.isOn = chatRoom.isOpenInviteEnabled
        cell.delegate = self
    }
    
    @objc func shareLinkActivityItem(_ url: URL) -> ChatLinkPresentationItemSource {
        let chatUseCase = ChatUseCase(chatRepo: ChatRepository.newRepo)
        var title = ""
        var subject = ""
        var message = ""
        if chatRoom.isMeeting {
            title = (chatRoom.title ?? "") + "\n" + url.absoluteString
            subject = Strings.Localizable.Meetings.Info.ShareMeetingLink.subject
            message = Strings.Localizable.Meetings.Info.ShareMeetingLink.invitation((chatUseCase.myFullName() ?? "")) + "\n" +
            Strings.Localizable.Meetings.Info.ShareMeetingLink.meetingName(chatRoom.title ?? "") + "\n" +
            Strings.Localizable.Meetings.Info.ShareMeetingLink.meetingLink(url.absoluteString)
        } else {
            title = chatRoom.title ?? ""
            message = title + "\n" + url.absoluteString
        }
        return ChatLinkPresentationItemSource(
            title: title,
            subject: subject,
            message: message,
            url: url
        )
    }
    
    @objc func updateAppearance() {
        view.backgroundColor = backgroundGroupedColor()
        tableView.backgroundColor = backgroundGroupedColor()
        groupInfoView.backgroundColor = backgroundElevatedColor()
        
        participantsLabel.textColor = TokenColors.Text.secondary
        groupInfoBottomSeparatorView.backgroundColor = TokenColors.Border.strong
    }
    
    @objc func backgroundGroupedColor() -> UIColor {
        TokenColors.Background.page
    }
    
    @objc func backgroundElevatedColor() -> UIColor {
        TokenColors.Background.page
    }
    
    @objc func iconPrimaryColor() -> UIColor {
        TokenColors.Icon.primary
    }
    
    @objc func iconRedColor() -> UIColor {
        TokenColors.Support.error
    }
    
    @objc func configLeftImageForLeftGroup(for cell: GroupChatDetailsViewTableViewCell?) {
        guard let cell else { return }
        
        cell.leftImageView.image = UIImage.leaveGroup.withRenderingMode(.alwaysTemplate)
        cell.leftImageView.tintColor = iconRedColor()
    }
    
    @objc func groupChatAddParticipantImage() -> UIImage {
        UIImage.groupChatAddParticipant
    }
    
    @objc func setTableHeaderFooterViewBackgroundColor(
        _ headerFooterView: GenericHeaderFooterView
    ) {
        headerFooterView.setPreferredBackgroundColor(TokenColors.Background.page)
    }
}

extension GroupChatDetailsViewController: MEGAChatCallDelegate {
    public func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        guard call.chatId == self.chatRoom.chatId else { return }
        
        let statusToReload: [MEGAChatCallStatus] = [.inProgress,
                                                    .userNoPresent,
                                                    .destroyed]
        if statusToReload.contains(call.status) {
            self.reloadData()
        }
    }
}

extension GroupChatDetailsViewController: MEGAChatRoomDelegate {
    public func onChatRoomUpdate(_ api: MEGAChatSdk, chat: MEGAChatRoom) {
        if chat.hasChanged(for: .openInvite) {
            DispatchQueue.main.async {
                self.chatRoom = chat
                self.reloadData()
            }
        }
    }
}

extension GroupChatDetailsViewController: GroupChatDetailsViewTableViewCellDelegate {
    public func controlSwitchValueChanged(_ sender: UISwitch, from cell: GroupChatDetailsViewTableViewCell) {
        guard let section = tableView.indexPath(for: cell)?.section else { return }
        switch UInt(section) {
        case GroupChatDetailsSection.chatNotifications.rawValue:
            changeChatNotificationStatus(sender: sender)
        case GroupChatDetailsSection.allowNonHostToAddParticipants.rawValue:
            MEGAChatSdk.shared.openInvite(sender.isOn, chatId: chatRoom.chatId)
        default:
            break
        }
    }
}

extension GroupChatDetailsViewController: PushNotificationControlProtocol {
    func presentAlertController(_ alert: UIAlertController) {
        present(alert, animated: true)
    }
    
    func reloadDataIfNeeded() {
        tableView?.reloadData()
    }
    
    func pushNotificationSettingsLoaded() {
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: Int(GroupChatDetailsSection.chatNotifications.rawValue))) as? GroupChatDetailsViewTableViewCell else {
            return
        }
        if cell.controlSwitch != nil {
            cell.controlSwitch.isEnabled = true
        }
    }
}
