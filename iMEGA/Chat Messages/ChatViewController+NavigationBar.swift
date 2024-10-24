import ChatRepo
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

extension ChatViewController {
    func configureNavigationBar() {
        addRightBarButtons()
        setTitleView()
    }
    
    func updateRightBarButtons() {
        guard !isEditing else {
            navigationItem.rightBarButtonItems = createNavBarRightButtonItems(isEditing: true)
            return
        }
        navigationItem.rightBarButtonItems = createNavBarRightButtonItems()
                
        chatContentViewModel.dispatch(.updateCallNavigationBarButtons(shouldDisableAudioVideoCalling, isVoiceRecordingInProgress))
    }
    
    private func addRightBarButtons() {
        navigationItem.rightBarButtonItems = createNavBarRightButtonItems()
        updateRightBarButtons()
    }
    
    private func createNavBarRightButtonItems(isEditing: Bool = false) -> [UIBarButtonItem] {
        let navBarRightItems = chatContentViewModel.determineNavBarRightItems(isEditing: isEditing)
        switch navBarRightItems {
        case .cancel:
            return [cancelBarButtonItem]
        case .addParticipantAndAudioCall:
            return [addParticipantBarButtonItem, audioCallBarButtonItem]
        case .audioCall:
            return [audioCallBarButtonItem]
        case .videoAndAudioCall:
            return [videoCallBarButtonItem, audioCallBarButtonItem]
        default:
            return []
        }
    }
    
    private func setTitleView() {
        let titleView = ChatTitleView.instanceFromNib
        titleView.chatRoom = chatRoom
        titleView.tapHandler = { [weak self] in
            self?.didTapTitle()
        }
        navigationItem.titleView = titleView
    }
    
    private func didTapTitle() {
        if chatRoom.isGroup {
            if MEGALinkManager.joiningOrLeavingChatBase64Handles.contains(MEGASdk.base64Handle(forUserHandle: chatRoom.chatId) ?? "") {
                return
            }
            pushGroupDetailsViewController()
        } else {
            guard let peerHandle = chatRoom.oneToOneRoomOtherParticipantUserHandle() else { return }
            pushContactDetailsViewController(withPeerHandle: peerHandle)
        }
    }
    
    private func pushGroupDetailsViewController() {
        guard let navigationController else { return }
        if let scheduledMeeting = chatHasFutureScheduledMeeting() {
            MeetingInfoRouter(presenter: navigationController, scheduledMeeting: scheduledMeeting).start()
        } else {
            let storyboard = UIStoryboard(name: "Chat", bundle: nil)
            if let groupDetailsViewController = storyboard.instantiateViewController(withIdentifier: "GroupChatDetailsViewControllerID") as? GroupChatDetailsViewController {
                groupDetailsViewController.chatRoom = chatRoom.toMEGAChatRoom()
                navigationController.pushViewController(groupDetailsViewController, animated: true)
            } else {
                MEGALogError("ChatViewController: Could not GroupChatDetailsViewController")
            }
        }
    }
    
    private func chatHasFutureScheduledMeeting() -> ScheduledMeetingEntity? {
        let scheduledMeetingUseCase = ScheduledMeetingUseCase(repository: ScheduledMeetingRepository(chatSDK: MEGAChatSdk.shared))
        let scheduledMeetings = scheduledMeetingUseCase.scheduledMeetingsByChat(chatId: chatRoom.chatId)
        
        return scheduledMeetings.first(where: {
            if $0.rules.frequency == .invalid {
                return $0.endDate >= Date()
            } else {
                if let until = $0.rules.until {
                    return until >= Date()
                } else {
                    return true
                }
            }
        })
    }
    
    func pushContactDetailsViewController(withPeerHandle peerHandle: UInt64) {
        guard let contactDetailsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactDetailsViewControllerID") as? ContactDetailsViewController else {
            return
        }
        
        guard let userEmail = MEGAChatSdk.shared.userEmailFromCache(byUserHandle: peerHandle) else {
            return
        }
        
        contactDetailsVC.contactDetailsMode = chatRoom.isGroup ? .fromGroupChat : .fromChat
        contactDetailsVC.userEmail = userEmail
        contactDetailsVC.userHandle = peerHandle
        contactDetailsVC.groupChatRoom = chatRoom.toMEGAChatRoom()
        navigationController?.pushViewController(contactDetailsVC, animated: true)
    }
    
    @objc func addParticipant() {
        let participantsAddingViewFactory = createParticipantsAddingViewFactory()
        
        guard participantsAddingViewFactory.hasVisibleContacts else {
            present(viewController: participantsAddingViewFactory.noAvailableContactsAlert(inviteAction: showInviteContacts))
            return
        }
        
        guard participantsAddingViewFactory.hasNonAddedVisibleContacts(withExcludedHandles: []) else {
            present(viewController: participantsAddingViewFactory.allContactsAlreadyAddedAlert(inviteAction: showInviteContacts))
            return
        }
        
        let contactsNavigationController = participantsAddingViewFactory.addContactsViewController(
            withContactsMode: .chatAddParticipant,
            additionallyExcludedParticipantsId: nil
        ) { [weak self] handles in
            guard let self else { return }
            chatContentViewModel.dispatch(.inviteParticipants(handles))
        }
        
        guard let contactsNavigationController = contactsNavigationController else { return }
        present(viewController: contactsNavigationController)
    }
    
    private func showInviteContacts() {
        guard let inviteController = createParticipantsAddingViewFactory().inviteContactController() else { return }
        navigationController?.pushViewController(inviteController, animated: true)
    }
    
    private func createParticipantsAddingViewFactory() -> ParticipantsAddingViewFactory {
        ParticipantsAddingViewFactory(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            chatRoom: chatRoom
        )
    }
}
