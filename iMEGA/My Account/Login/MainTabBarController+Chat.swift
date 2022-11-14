import MEGADomain

extension MainTabBarController {
    private var shouldShowNewChatRoomListingScreen: Bool {
        FeatureFlagProvider(
            useCase: FeatureFlagUseCase(repository: FeatureFlagRepository.newRepo)
        )
        .isFeatureFlagEnabled(for: .chatRoomsListingRevamp)
    }
    
    @objc func chatViewController() -> UIViewController {
        if #available(iOS 14.0, *), shouldShowNewChatRoomListingScreen {
            let router = ChatRoomsListRouter(tabBarController: self)
            return router.build()
        } else {
            guard let chatNavigationController = UIStoryboard(name: "Chat", bundle: nil).instantiateInitialViewController() as? MEGANavigationController else {
                return MEGANavigationController()
            }
            
            if let chatRoomsViewController = chatNavigationController.viewControllers.first as? ChatRoomsViewController, chatRoomsViewController.conforms(to: MyAvatarPresenterProtocol.self) {
                chatRoomsViewController.configureMyAvatarManager()
            }
            return chatNavigationController
        }
    }
    
    @objc func showStartConversation() {
        selectedIndex = TabType.chat.rawValue
        guard let navigationController = self.children[safe: TabType.chat.rawValue] as? MEGANavigationController else {
            return
        }
        
        if #available(iOS 14.0, *), shouldShowNewChatRoomListingScreen {
            if let chatRoomsListViewController = navigationController.viewControllers.first as? ChatRoomsListViewController {
                chatRoomsListViewController.viewModel.router.presentStartConversation()
            }
        } else {
            if let chatRoomViewController = navigationController.viewControllers.first as? ChatRoomsViewController {
                chatRoomViewController.showStartConversation()
            }
        }
    }
    
    @objc func openChatRoom(withPublicLink publicLink: String?, chatID: ChatId) {
        selectedIndex = TabType.chat.rawValue
        guard let navigationController = self.children[safe: TabType.chat.rawValue] as? MEGANavigationController else {
            return
        }
        
        if #available(iOS 14.0, *), shouldShowNewChatRoomListingScreen {
            let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo,
                                                  userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()))
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
        } else {
            if let chatRoomViewController = navigationController.viewControllers.first as? ChatRoomsViewController {
                if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                    rootViewController.dismiss(animated: true) {
                        self.openChatRoom(usingChatRoomsViewController: chatRoomViewController,
                                          chatID: chatID,
                                          publicLink: publicLink)
                    }
                } else {
                    openChatRoom(usingChatRoomsViewController: chatRoomViewController,
                                 chatID: chatID,
                                 publicLink: publicLink)
                }
            }
        }
    }
    
    @objc func openChatRoom(chatId: ChatId) {
        openChatRoom(withPublicLink: nil, chatID: chatId)
    }
    
    //MARK: - Private methods.
    
    private func openChatRoom(usingChatRoomsViewController vc: ChatRoomsViewController, chatID: ChatId, publicLink: String?) {
        if let publicLink {
            vc.openChatRoom(withPublicLink: publicLink, chatID: chatID)
        } else {
            vc.openChatRoom(withID: chatID)
        }
    }
}

