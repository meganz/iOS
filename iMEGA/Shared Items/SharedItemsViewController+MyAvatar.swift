extension SharedItemsViewController: MyAvatarPresenterProtocol {
    func setupMyAvatar(barButton: UIBarButtonItem) {
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    func configureMyAvatarManager() {
        guard let navController = navigationController else { return }
        myAvatarManager = MyAvatarManager(navigationController: navController, delegate: self)
        myAvatarManager?.setup()
    }
    
    func refreshMyAvatar() {
        myAvatarManager?.refreshMyAvatar()
    }
}
