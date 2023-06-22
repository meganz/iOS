import Foundation
import MEGAPresentation

enum EnterMeetingLinkViewAction: ActionType {
    case didTapJoinButton(String)
}

final class EnterMeetingLinkViewModel: ViewModelType {
    enum Command: CommandType { }
    
    // MARK: - Private properties
    private let router: any EnterMeetingLinkRouting
    // MARK: - Internel properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: some EnterMeetingLinkRouting) {
        self.router = router
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: EnterMeetingLinkViewAction) {
        switch action {
        case .didTapJoinButton(let link):
            let url = URL(string: link)
            
            if let url = url, (url as NSURL).mnz_type() == .publicChatLink {
                MEGALinkManager.linkURL = url
                MEGALinkManager.processLinkURL(url)
            } else {
                router.showLinkError()
            }
        }
    }
}
