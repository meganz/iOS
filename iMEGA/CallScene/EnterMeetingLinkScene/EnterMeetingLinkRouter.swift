import Foundation

protocol EnterMeetingLinkRouting: Routing {
    func joinMeeting(link: String)
    func showLinkError()
}

final class EnterMeetingLinkRouter: NSObject, EnterMeetingLinkRouting {
    
    private weak var baseViewController: UIViewController?
    private weak var viewControllerToPresent: UIViewController?
    private let isGuest: Bool
    
    @objc init(viewControllerToPresent: UIViewController, isGuest: Bool) {
        self.viewControllerToPresent = viewControllerToPresent
        self.isGuest = isGuest
    }
    
    func build() -> UIViewController {
        let viewModel = EnterMeetingLinkViewModel(router: self)
        return EnterMeetingLinkControllerWrapper.createViewController(withViewModel: viewModel)
    }
    
    @objc func start() {
        guard let viewControllerToPresent = viewControllerToPresent else { return }
        viewControllerToPresent.present(build(), animated: true)
    }
    
    func joinMeeting(link: String) {
        guard let viewControllerToPresent = viewControllerToPresent else {
            return
        }
        
        let router = MeetingCreatingViewRouter(viewControllerToPresent: viewControllerToPresent, type: isGuest ? .guestJoin : .join, link: link, userhandle: 0)
        router.start()
    }
    
    func showLinkError() {
        guard let viewControllerToPresent = viewControllerToPresent else { return }

        let title = NSLocalizedString("meetings.joinMeeting.header", comment: "")
        let message = NSLocalizedString("meetings.joinMeeting.description", comment: "")
        let cancelButtonText = NSLocalizedString("ok", comment: "")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelButtonText, style: .cancel))
        viewControllerToPresent.present(alert, animated: true)
    }
}
