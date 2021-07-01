import Foundation

protocol EnterMeetingLinkRouting {
    var viewControllerToPresent: UIViewController? { get }
    func joinMeeting(link: String)
}

class EnterMeetingLinkRouter: NSObject, EnterMeetingLinkRouting {
    
    private weak var baseViewController: UIViewController?
    private(set) weak var viewControllerToPresent: UIViewController?
    private let isGuest: Bool
    
    @objc init(viewControllerToPresent: UIViewController, isGuest: Bool) {
        self.viewControllerToPresent = viewControllerToPresent
        self.isGuest = isGuest
    }
    
    @objc func start() -> NSObject? {
        guard let viewControllerToPresent = viewControllerToPresent else {
            return nil
        }
        let viewModel = EnterMeetingLinkViewModel(router: self)
        let joinAlertWrapper = EnterMeetingLinkViewHelper(viewModel: viewModel)
        viewModel.dispatch(.showEnterMeetingLink(presenter: viewControllerToPresent))
        return joinAlertWrapper
    }
    
    func joinMeeting(link: String) {
        guard let viewControllerToPresent = viewControllerToPresent else {
            return
        }
        
        let router = MeetingCreatingViewRouter(viewControllerToPresent: viewControllerToPresent, type: isGuest ? .guestJoin : .join, link: link, userhandle: 0)
        router.start()
    }
}
