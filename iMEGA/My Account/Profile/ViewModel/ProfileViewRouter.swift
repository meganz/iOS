final class ProfileViewRouter {
    private weak var navigationController: UINavigationController?
    private let viewModel: ProfileViewModel
    
    init(navigationController: UINavigationController?, viewModel: ProfileViewModel) {
        self.navigationController = navigationController
        self.viewModel = viewModel
    }
    
    func build() -> UIViewController {
        UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(identifier: "ProfileViewControllerID", creator: { coder in
            return ProfileViewController(coder: coder, viewModel: self.viewModel)
        })
    }
    
    func start() {
        guard let navigationController else {
            assertionFailure("Must pass UINavigationController in ProfileViewRouter")
            MEGALogDebug("[Profile] No UINavigationController passed on ProfileViewRouter")
            return
        }

        navigationController.pushViewController(build(), animated: true)
    }
}
