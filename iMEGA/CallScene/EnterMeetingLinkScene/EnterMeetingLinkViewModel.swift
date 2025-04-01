import Foundation
import MEGAAppPresentation

enum EnterMeetingLinkViewAction: ActionType {
    case didTapJoinButton(String)
}

final class EnterMeetingLinkViewModel: ViewModelType {
    enum Command: CommandType { }
    
    private let linkManager: any MEGALinkManagerProtocol.Type
    
    // MARK: - Private properties
    private let router: any EnterMeetingLinkRouting
    // MARK: - Internel properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: some EnterMeetingLinkRouting, 
         linkManager: any MEGALinkManagerProtocol.Type = MEGALinkManager.self) {
        self.router = router
        self.linkManager = linkManager
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: EnterMeetingLinkViewAction) {
        switch action {
        case .didTapJoinButton(let link):
            let url = URL(string: link)
            
            if let url = url, (url as NSURL).mnz_type() == .publicChatLink {
                linkManager.adapterLinkURL = url
                linkManager.processLinkURL(url)
            } else {
                router.showLinkError()
            }
        }
    }
}
