extension PhotosViewController: MyAvatarPresenterProtocol {
    func setupMyAvatar(barButton: UIBarButtonItem) {
        objcWrapper_parent.navigationItem.leftBarButtonItem = barButton
    }
    
    func configureMyAvatarManager() {
        guard let navController = objcWrapper_parent.navigationController else { return }
        myAvatarManager = MyAvatarManager(navigationController: navController, delegate: self)
        myAvatarManager?.setup()
    }
    
    func refreshMyAvatar() {
        myAvatarManager?.refreshMyAvatar()
    }
}
