import Foundation

protocol MeetingJoinViewRouting: Routing {
    func dismiss()
    func joinMeeting(link: String)

}

class MeetingJoinAlertRouter: NSObject, MeetingJoinViewRouting {
    
    private weak var baseViewController: UIViewController?
    private weak var viewControllerToPresent: UIViewController?
    private let isGuest: Bool
    
    @objc init(viewControllerToPresent: UIViewController, isGuest: Bool) {
        self.viewControllerToPresent = viewControllerToPresent
        self.isGuest = isGuest
    }
    
    func build() -> UIViewController {
        let vm = MeetingJoinViewModel(router: self)
        
        let vc = MeetingJoinAlertViewController(title: NSLocalizedString("Enter Meeting Link", comment: ""), message: nil, preferredStyle: .alert)
        vc.configure()
        vc.viewModel = vm
        baseViewController = vc
        return vc
    }
    
    @objc func start() {
        guard let viewControllerToPresent = viewControllerToPresent else {
            return
        }
        viewControllerToPresent.present(build(), animated: true, completion: nil)
    }
    
    // MARK: - UI Actions
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func joinMeeting(link: String) {
        guard let viewControllerToPresent = viewControllerToPresent else {
            return
        }
        let router = MeetingCreatingViewRouter(viewControllerToPresent: viewControllerToPresent, type: isGuest ? .guestJoin : .join, link: link)
        router.start()
    }
}
