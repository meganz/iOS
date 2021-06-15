import Foundation

enum EnterMeetingLinkViewAction: ActionType {
    case showEnterMeetingLink(presenter: UIViewController)
    case didTapJoinButton(String)
}

final class EnterMeetingLinkViewModel: ViewModelType {
    enum Command: CommandType {
        case showEnterMeetingLink(presenter: UIViewController)
        case linkError(presenter: UIViewController)
    }
    
    // MARK: - Private properties
    private let router: EnterMeetingLinkRouting
    // MARK: - Internel properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: EnterMeetingLinkRouting) {
        self.router = router
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: EnterMeetingLinkViewAction) {
        switch action {
        case .showEnterMeetingLink(let presenter):
            invokeCommand?(.showEnterMeetingLink(presenter: presenter))
        case .didTapJoinButton(let link):
            let url = URL(string: link)
            
            if let url = url, (url as NSURL).mnz_type() == .publicChatLink {
                MEGALinkManager.linkURL = url
                MEGALinkManager.processLinkURL(url)
            } else {
                guard let presenter = router.viewControllerToPresent else {
                    return
                }
                
                invokeCommand?(.linkError(presenter: presenter))
            }
        }
      
    }
    
}
