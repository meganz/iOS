import MEGADomain

extension MainTabBarController {
    @objc func chatViewController() -> UIViewController {
        ChatRoomsListRouter(tabBarController: self).build()
    }
    
    @objc func showStartConversation() {
        selectedIndex = TabType.chat.rawValue
        guard let navigationController = self.children[safe: TabType.chat.rawValue] as? MEGANavigationController else {
            return
        }
        
        if let chatRoomsListViewController = navigationController.viewControllers.first as? ChatRoomsListViewController {
            chatRoomsListViewController.viewModel.router.presentStartConversation()
        }
    }
    
    @objc func openChatRoom(withPublicLink publicLink: String?, chatID: ChatIdEntity) {
        selectedIndex = TabType.chat.rawValue
        guard let navigationController = self.children[safe: TabType.chat.rawValue] as? MEGANavigationController else {
            return
        }
        
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo)
        let chatUseCase = ChatUseCase(
            chatRepo: ChatRepository(
                sdk: MEGASdkManager.sharedMEGASdk(),
                chatSDK: MEGASdkManager.sharedMEGAChatSdk()
            )
        )
        
        var totalUnreadChats = chatUseCase.unreadChatMessagesCount()
        if let totalChatRoomUnreadChats = chatRoomUseCase.chatRoom(forChatId: chatID)?.unreadCount, totalChatRoomUnreadChats > 0 {
            totalUnreadChats -= 1
        }

        if let chatRoomsListViewController = navigationController.viewControllers.first as? ChatRoomsListViewController {
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                rootViewController.dismiss(animated: true) {
                    chatRoomsListViewController.viewModel.router.openChatRoom(withChatId: chatID, publicLink: publicLink, unreadMessageCount: totalUnreadChats)
                }
            } else {
                chatRoomsListViewController.viewModel.router.openChatRoom(withChatId: chatID, publicLink: publicLink, unreadMessageCount: totalUnreadChats)
            }
        }
    }
    
    @objc func openChatRoom(chatId: ChatIdEntity) {
        openChatRoom(withPublicLink: nil, chatID: chatId)
    }
}
