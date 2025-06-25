import MEGAAppPresentation

extension PhotosViewController: MyAvatarPresenterProtocol {
    func setupMyAvatar(barButton: UIBarButtonItem) {
        objcWrapper_parent.navigationItem.leftBarButtonItem = barButton
    }
    
    func configureMyAvatarManager() {
        guard !DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp) else {
            return
        }
        guard let navController = objcWrapper_parent.navigationController else { return }
        myAvatarManager = MyAvatarManager(navigationController: navController, delegate: self)
        myAvatarManager?.setup()
    }
    
    func refreshMyAvatar() {
        myAvatarManager?.refreshMyAvatar()
    }
}
