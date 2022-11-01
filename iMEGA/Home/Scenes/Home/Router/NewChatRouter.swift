import Foundation
import MEGADomain

final class NewChatRouter {

    // MARK: - Navigation Controllers

    private weak var navigationController: UINavigationController?

    private weak var tabBarController: MainTabBarController?

    // MARK: - Lifecycles

    init(navigationController: UINavigationController?, tabBarController: MainTabBarController?) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    // MARK: - Display Start A New Chat Selection

    func presentNewChat(from navigationController: UINavigationController?, chatOptionType: ChatOptionType = .none) {
        let contactsNavigationController = contactsViewController(chatOptionType: chatOptionType)
        navigationController?.present(contactsNavigationController, animated: true, completion: nil)
    }

    private func contactsViewController(chatOptionType: ChatOptionType) -> UINavigationController {
        let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
        let contactsNavigationController = storyboard.instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as! UINavigationController
        let contactController = contactsNavigationController.viewControllers.first as! ContactsViewController
        contactController.contactsMode = .chatStartConversation
        contactController.chatOptionType = chatOptionType
        setupContactsSelection(for: contactController)
        return contactsNavigationController
    }

    private func setupContactsSelection(for contactController: ContactsViewController) {
        contactController.userSelected = { [weak self] users in
            guard let self = self else { return }
            guard let selectedUser: MEGAUser = users?.first else { return }
            self.chatRoom(byUserHandle: selectedUser.handle) { chatRoom in
                self.switchToChat(withChatID: chatRoom.chatId)
            }
        }

        contactController.chatSelected = { [weak self] chatId in
            self?.switchToChat(withChatID: chatId)
        }

        contactController.createGroupChat = { [weak self] (users, groupName, keyRotation, getChatLink, allowNonHostToAddParticipants) in
            guard let self = self else { return }
            let megaUsers = (users as? [MEGAUser]) ?? []
            switch keyRotation {
            case true:
                self.createChatRoom(byUsers: megaUsers,
                                    groupName: groupName,
                                    allowNonHostToAddParticipants: allowNonHostToAddParticipants,
                                    completion: { chatRoom in
                    DispatchQueue.main.async {
                        self.switchToChat(withChatID: chatRoom.chatId)
                    }
                })
            case false:
                self.createPublicChatRoom(
                    forUsers: megaUsers,
                    chatRoomName: groupName,
                    shouldGetChatLink: getChatLink,
                    allowNonHostToAddParticipants: allowNonHostToAddParticipants
                ) { chatId, publicChatLink in
                    DispatchQueue.main.async {
                        guard let publicChatLink = publicChatLink, !publicChatLink.isEmpty else {
                            self.switchToChat(withChatID: chatId)
                            return
                        }
                        self.switchToChat(withPublicLink: publicChatLink, chatID: chatId)
                    }
                }
            }
        }
    }

    private func chatRequestDelegate(
        ofShouldGetChatLink getChatLink: Bool,
        completion: @escaping (HandleEntity, String?) -> Void
    ) -> MEGAChatGenericRequestDelegate {
        let chatSDK = MEGASdkManager.sharedMEGAChatSdk()
        return MEGAChatGenericRequestDelegate { (request, error) in
            switch getChatLink {
            case false:
                completion(request.chatHandle, nil)
            case true:
                let publicChatLinkCreationDelegate = MEGAChatGenericRequestDelegate { (request, error) in
                    guard error.type == .MEGAChatErrorTypeOk else { return }
                    completion(request.chatHandle, request.text)
                }
                chatSDK.createChatLink(request.chatHandle, delegate: publicChatLinkCreationDelegate)
            }
        }
    }

    private func createPublicChatRoom(
        forUsers users: [MEGAUser],
        chatRoomName: String?,
        shouldGetChatLink: Bool,
        allowNonHostToAddParticipants: Bool,
        completion: @escaping (HandleEntity, String?) -> Void
    ) {
        let chatSDK = MEGASdkManager.sharedMEGAChatSdk()
        let chatPeers = MEGAChatPeerList.mnz_standardPrivilegePeerList(usersArray: users)
        chatSDK.createPublicChat(withPeers: chatPeers,
                                 title: chatRoomName,
                                 speakRequest: false,
                                 waitingRoom: false,
                                 openInvite: allowNonHostToAddParticipants,
                                 delegate: chatRequestDelegate(ofShouldGetChatLink: shouldGetChatLink, completion: completion))
    }

    private func createChatRoom(byUsers users: [MEGAUser],
                                groupName: String?,
                                allowNonHostToAddParticipants: Bool,
                                completion: @escaping (MEGAChatRoom) -> Void) {
        let chatSDK = MEGASdkManager.sharedMEGAChatSdk()
        chatSDK.mnz_createChatRoom(usersArray: users,
                                   title: groupName,
                                   allowNonHostToAddParticipants: allowNonHostToAddParticipants,
                                   completion: completion)
    }

    private func chatRoom(byUserHandle userHandle: HandleEntity,
                          completion: @escaping (MEGAChatRoom) -> Void) {
        let chatSDK = MEGASdkManager.sharedMEGAChatSdk()
        if let chatRoom = chatSDK.chatRoom(byUser: userHandle) {
            completion(chatRoom)
        } else {
            chatSDK.mnz_createChatRoom(userHandle: userHandle, completion: { chatRoom in
                completion(chatRoom)
            })
        }
    }

    private func switchToChat(withChatID chatID: HandleEntity) {
        tabBarController?.openChatRoomNumber(NSNumber(value: chatID))
    }

    private func switchToChat(withPublicLink publicLink: String, chatID: HandleEntity) {
        tabBarController?.openChatRoom(withPublicLink: publicLink, chatID: chatID)
    }
}
