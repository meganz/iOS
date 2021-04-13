import Foundation

class MeetingJoinAlertRouter: NSObject, MeetingJoinViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var viewControllerToPresent: UIViewController?
    
    @objc init(viewControllerToPresent: UIViewController) {
        self.viewControllerToPresent = viewControllerToPresent
    }
    
    func build() -> UIViewController {
        let vm = MeetingJoinViewModel(router: self)
        
        let vc = MeetingJoinAlertViewController(title: nil, message: nil, preferredStyle: .alert)
        
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
    
    func joinMeeting() {
        guard let viewControllerToPresent = viewControllerToPresent else {
            return
        }
        let router = MeetingCreatingViewRouter(viewControllerToPresent: viewControllerToPresent)
        router.start()
    }
}
