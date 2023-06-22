import MEGAPresentation

enum EndMeetingOptionsAction: ActionType {
    case onLeave
    case onCancel
}

struct EndMeetingOptionsViewModel: ViewModelType {
    enum Command: CommandType, Equatable {}
    
    private let router: any EndMeetingOptionsRouting
    var invokeCommand: ((Command) -> Void)?

    init(router: some EndMeetingOptionsRouting) {
        self.router = router
    }
    
    func dispatch(_ action: EndMeetingOptionsAction) {
        switch action {
        case .onLeave:
            router.dismiss {
                router.showJoinMega()
            }
        case .onCancel:
            router.dismiss {}
        }
    }
}
