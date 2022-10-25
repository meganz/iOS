import MEGADomain

extension MainTabBarController {
    @objc func chatViewController() -> UIViewController {
        let featureFlagProvider = FeatureFlagProvider(useCase: FeatureFlagUseCase(repository: FeatureFlagRepository.newRepo))
        if #available(iOS 14.0, *), featureFlagProvider.isFeatureFlagEnabled(for: .chatRoomsListingRevamp) {
            let isRightToLeftLanguage = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft
            return ChatRoomsListRouter().build(isRightToLeftLanguage: isRightToLeftLanguage)
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
}

