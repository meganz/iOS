import MEGAAppPresentation

extension AppDelegate {
    @objc func revampedOpenTabBasedOnNotificationMegatype() {
        guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp) else {
            openTabBasedOnNotificationMegatype()
            return
        }

        guard [MEGANotificationType.shareFolder, .chatMessage, .contactRequest].contains(megatype) else { return }

        let manageNotificationBlock = { [weak self] in
            guard let self, let mainTBC else { return }

            switch megatype {
            case .shareFolder:
                mainTBC.selectedIndex = TabManager.menuTabIndex()
                navigateToSharedItems()
            case .chatMessage:
                mainTBC.selectedIndex = TabManager.chatTabIndex()
                handleChatMessageType()
            case .contactRequest:
                mainTBC.selectedIndex = TabManager.homeTabIndex()
                handleContactRequestType()
            default:
                // If the megatype doesn't correspond to a tab, do nothing.
                return
            }
        }

        // Ensure no modal view is presented before switching tabs
        guard let rootViewController = window.rootViewController, rootViewController.presentedViewController != nil else {
            manageNotificationBlock()
            return
        }

        rootViewController.dismiss(animated: true, completion: manageNotificationBlock)
    }

    private func handleChatMessageType() {
        // If a chat screen is already visible, pop it to the root to avoid stacking chats
        if UIApplication.mnz_visibleViewController() is ChatViewController {
            if let navController = mainTBC?.viewControllers?[TabManager.chatTabIndex()] as? MEGANavigationController {
                navController.popToRootViewController(animated: false)
            }
        }
    }

    private func handleContactRequestType() {
        // If the requests screen is already visible, no need to push another one
        guard !(UIApplication.mnz_visibleViewController() is ContactRequestsViewController) else {
            return
        }

        // Push the contact requests view controller onto the navigation stack
        if let navController = mainTBC?.selectedViewController as? MEGANavigationController {
            let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
            let contactRequestsVC = storyboard.instantiateViewController(withIdentifier: "ContactsRequestsViewControllerID")
            navController.pushViewController(contactRequestsVC, animated: false)
        }
    }

    private func navigateToSharedItems() {
        guard let presenter = mainTBC?.selectedViewController as? (any AccountMenuItemsNavigating) else {
            return assertionFailure("Trying to navigate to SharedItems screen but selected view controller is not of type AccountMenuItemsNavigating")
        }
        presenter.showSharedItems()
    }
}
