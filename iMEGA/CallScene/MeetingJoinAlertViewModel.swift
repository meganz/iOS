import Foundation

enum MeetingJoinViewAction: ActionType {
    case onViewReady
    
    case didTapJoinButton(String)
}

final class MeetingJoinViewModel: ViewModelType {
    enum Command: CommandType {
        case updateMeetingName(String)
   
    }
    
    // MARK: - Private properties
    private let router: MeetingJoinViewRouting
    // MARK: - Internel properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: MeetingJoinViewRouting) {
        self.router = router
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: MeetingJoinViewAction) {
        switch action {
        case .onViewReady:
            break
        case .didTapJoinButton(let link):
            let url =  URL(string: link)
            MEGALinkManager.linkURL = url
            MEGALinkManager.processLinkURL(url)
            break
        }
      
    }
    
}
