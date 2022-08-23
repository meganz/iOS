
import Foundation

extension ChatViewController {
    private var rightBarButtons: [UIBarButtonItem] {
        var barButtons: [UIBarButtonItem] = []

        if chatRoom.isGroup {
            if chatRoom.ownPrivilege == .moderator {
                barButtons.append(addParticpantBarButtonItem)
            }

            barButtons.append(audioCallBarButtonItem)
        } else {
            barButtons = [videoCallBarButtonItem, audioCallBarButtonItem]
        }

        return barButtons
    }

    var shouldDisableAudioVideoCall: Bool {
        return shouldDisableAudioVideoCalling
            || chatRoom.ownPrivilege.rawValue < MEGAChatRoomPrivilege.standard.rawValue
            || MEGASdkManager.sharedMEGAChatSdk().chatConnectionState(chatRoom.chatId) != .online
            || !MEGAReachabilityManager.isReachable()
            || MEGASdkManager.sharedMEGAChatSdk().mnz_existsActiveCall
            || MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId) != nil
            || isVoiceRecordingInProgress
    }

    func configureNavigationBar() {
        addRightBarButtons()
        setTitleView()
    }

    func updateRightBarButtons() {
        guard !isEditing else {
            navigationItem.rightBarButtonItems = [cancelBarButtonItem]
            return
        }
        navigationItem.rightBarButtonItems = rightBarButtons

        audioCallBarButtonItem.isEnabled = !shouldDisableAudioVideoCall
        videoCallBarButtonItem.isEnabled = !shouldDisableAudioVideoCall
    }

    private func addRightBarButtons() {
        navigationItem.rightBarButtonItems = rightBarButtons
        updateRightBarButtons()
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
            pushContactDetailsViewController(withPeerHandle: chatRoom.peerHandle(at: 0))
        }
    }

    private func pushGroupDetailsViewController() {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        if let groupDetailsViewController = storyboard.instantiateViewController(withIdentifier: "GroupChatDetailsViewControllerID") as? GroupChatDetailsViewController {
            groupDetailsViewController.chatRoom = chatRoom
            navigationController?.pushViewController(groupDetailsViewController, animated: true)
        } else {
            MEGALogError("ChatViewController: Could not GroupChatDetailsViewController")
        }
    }

    func pushContactDetailsViewController(withPeerHandle peerHandle: UInt64) {
        guard let contactDetailsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactDetailsViewControllerID") as? ContactDetailsViewController else {
            return
        }

        guard let userEmail = MEGASdkManager.sharedMEGAChatSdk().userEmailFromCache(byUserHandle: peerHandle) else {
            return
        }

        contactDetailsVC.contactDetailsMode = chatRoom.isGroup ? .fromGroupChat : .fromChat
        contactDetailsVC.userEmail = userEmail
        contactDetailsVC.userHandle = peerHandle
        contactDetailsVC.groupChatRoom = chatRoom
        navigationController?.pushViewController(contactDetailsVC, animated: true)
    }
    
    @objc func addParticipant() {
        let participantsAddingViewFactory = createParticipantsAddingViewFactory()
        
        guard participantsAddingViewFactory.shouldShowAddParticipantsScreen(withExcludedHandles: []) else {
            present(viewController: participantsAddingViewFactory.allContactsAlreadyAddedAlert {
                guard let inviteController = participantsAddingViewFactory.inviteContactController() else { return }
                self.navigationController?.pushViewController(inviteController, animated: true)
            })
            return
        }
        
        let contactsNavigationController = participantsAddingViewFactory.addContactsViewController(
            withContactsMode: .chatAddParticipant,
            additionallyExcludedParticipantsId: nil
        ) { [weak self] handles in
            guard let self = self else { return }
            for handle in handles {
                MEGASdkManager.sharedMEGAChatSdk().invite(
                    toChat: self.chatRoom.chatId,
                    user: handle,
                    privilege: MEGAChatRoomPrivilege.standard.rawValue
                )
            }
        }
        
        guard let contactsNavigationController = contactsNavigationController else { return }
        present(viewController: contactsNavigationController)
    }
    
    private func createParticipantsAddingViewFactory() -> ParticipantsAddingViewFactory {
        let chatRoomUseCase = ChatRoomUseCase(
            chatRoomRepo: ChatRoomRepository(sdk: MEGASdkManager.sharedMEGAChatSdk()),
            userStoreRepo: UserStoreRepository(store: .shareInstance()))
        return ParticipantsAddingViewFactory(
            userUseCase: UserUseCase(repo: .live),
            chatRoomUseCase: chatRoomUseCase,
            chatId: chatRoom.chatId
        )
    }
}
