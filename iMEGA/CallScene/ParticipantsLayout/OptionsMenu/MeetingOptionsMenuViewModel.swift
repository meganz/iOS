import MEGADomain
import MEGAPresentation

enum MeetingOptionsMenuAction: ActionType {
    case onViewReady
    case shareLinkAction
    case renameAction
    case dismiss
}

struct MeetingOptionsMenuViewModel: ViewModelType {
    enum Command:CommandType, Equatable {
        case configView(actions: [ActionSheetAction])
    }
    
    private let router: MeetingOptionsMenuRouter
    private let chatRoom: ChatRoomEntity
    private let isMyselfModerator: Bool
    private weak var containerViewModel: MeetingContainerViewModel?
    private let sender: UIBarButtonItem

    init(router: MeetingOptionsMenuRouter,
         chatRoom: ChatRoomEntity,
         isMyselfModerator: Bool,
         containerViewModel: MeetingContainerViewModel?,
         sender: UIBarButtonItem) {
        self.router = router
        self.chatRoom = chatRoom
        self.isMyselfModerator = isMyselfModerator
        self.containerViewModel = containerViewModel
        self.sender = sender
    }
    
    var invokeCommand: ((Command) -> Void)?

    func dispatch(_ action: MeetingOptionsMenuAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.configView(actions: actions()))
        case .shareLinkAction:
            containerViewModel?.dispatch(.shareLink(presenter: nil, sender: sender, completion: { _,_,_,_ in 
                containerViewModel?.dispatch(.hideOptionsMenu)
            }))
        case .renameAction:
            containerViewModel?.dispatch(.renameChat)
        case .dismiss:
            containerViewModel?.dispatch(.hideOptionsMenu)
        }
    }
    
    // MARK: - Private methods.
    
    private func actions() -> [ActionSheetAction] {
        var actions = [ActionSheetAction]()

        if isMyselfModerator {
            actions.append(renameAction())
        }
        actions.append(shareLinkAction())
        
        return actions
    }
    
    private func renameAction() -> ActionSheetAction {
        ActionSheetAction(title: chatRoom.chatType == .meeting ?
                            Strings.Localizable.Meetings.Action.rename :
                            Strings.Localizable.renameGroup,
                          detail: nil,
                          image: Asset.Images.Generic.rename.image,
                          style: .default) {
            dispatch(.renameAction)
        }
    }
    
    private func shareLinkAction() -> ActionSheetAction {
        ActionSheetAction(title: chatRoom.chatType == .meeting ?
                            Strings.Localizable.Meetings.Action.shareLink :
                            Strings.Localizable.getChatLink,
                          detail: nil,
                          image: Asset.Images.NodeActions.share.image,
                          style: .default) {
            dispatch(.shareLinkAction)
        }
    }
}
