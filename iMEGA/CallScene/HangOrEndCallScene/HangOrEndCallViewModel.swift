import MEGADomain

enum HangOrEndCallAction: ActionType {
    case leaveCall
    case endCallForAll
}

struct HangOrEndCallViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
    }
    
    private let router: HangOrEndCallRouting
    private let analyticsEventUseCase: AnalyticsEventUseCaseProtocol
    
    init(router: HangOrEndCallRouting, analyticsEventUseCase: AnalyticsEventUseCaseProtocol) {
        self.router = router
        self.analyticsEventUseCase = analyticsEventUseCase
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    func dispatch(_ action: HangOrEndCallAction) {
        switch action {
        case .leaveCall:
            router.leaveCall()
        case .endCallForAll:
            analyticsEventUseCase.sendAnalyticsEvent(.meetings(.endCallForAll))
            router.endCallForAll()
        }
    }
}
