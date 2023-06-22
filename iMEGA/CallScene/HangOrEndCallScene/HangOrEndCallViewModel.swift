import MEGADomain
import MEGAPresentation

enum HangOrEndCallAction: ActionType {
    case leaveCall
    case endCallForAll
}

struct HangOrEndCallViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
    }
    
    private let router: any HangOrEndCallRouting
    private let analyticsEventUseCase: any AnalyticsEventUseCaseProtocol
    
    init(router: some HangOrEndCallRouting, analyticsEventUseCase: any AnalyticsEventUseCaseProtocol) {
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
