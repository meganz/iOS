import ChatRepo
import MEGADomain

extension MainTabBarController {
    @objc func chatViewController() -> UIViewController {
        ChatRoomsListRouter(
            tabBarController: self,
            shareLinkRouter: ShareLinkDialogRouter(presenter: self)
        ).build()
    }
    
    @objc func showStartConversation() {
        selectedIndex = TabManager.chatTabIndex()
        existingChatRoomsListViewController?.viewModel.router.presentStartConversation()
    }
    
    var existingChatRoomsListViewController: ChatRoomsListViewController? {
        guard let navigationController = children[safe: TabManager.chatTabIndex()] as? MEGANavigationController else {
            return nil
        }
        
        return navigationController.viewControllers.first as? ChatRoomsListViewController
    }

    func openChatRoom(withPublicLink publicLink: String?, chatID: ChatIdEntity) {
        selectedIndex = TabManager.chatTabIndex()
        guard let navigationController = selectedViewController as? MEGANavigationController else {
            return
        }
        
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)
        let chatUseCase = ChatUseCase(chatRepo: ChatRepository.newRepo)
        
        var totalUnreadChats = chatUseCase.unreadChatMessagesCount()
        if let totalChatRoomUnreadChats = chatRoomUseCase.chatRoom(forChatId: chatID)?.unreadCount, totalChatRoomUnreadChats > 0 {
            totalUnreadChats -= 1
        }

        guard let chatRoomsListViewController = navigationController.viewControllers.first as? ChatRoomsListViewController,
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatID)  else { return }

        chatRoomsListViewController.viewModel.selectChatMode(chatRoom.isMeeting ? .meetings : .chats)
        
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            rootViewController.dismiss(animated: true) {
                chatRoomsListViewController.viewModel.router.openChatRoom(withChatId: chatID, publicLink: publicLink)
            }
        } else {
            chatRoomsListViewController.viewModel.router.openChatRoom(withChatId: chatID, publicLink: publicLink)
        }
    }
    
    @objc func openChatRoom(chatId: ChatIdEntity) {
        openChatRoom(withPublicLink: nil, chatID: chatId)
    }
}
