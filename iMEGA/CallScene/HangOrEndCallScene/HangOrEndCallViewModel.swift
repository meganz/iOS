import MEGADomain

enum HangOrEndCallAction: ActionType {
    case leaveCall
    case endCallForAll
}

struct HangOrEndCallViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
    }
    
    private let router: HangOrEndCallRouting
    private let statsUseCase: MeetingStatsUseCaseProtocol
    
    init(router: HangOrEndCallRouting, statsUseCase: MeetingStatsUseCaseProtocol) {
        self.router = router
        self.statsUseCase = statsUseCase
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    func dispatch(_ action: HangOrEndCallAction) {
        switch action {
        case .leaveCall:
            router.leaveCall()
        case .endCallForAll:
            statsUseCase.sendEndCallForAllStats()
            router.endCallForAll()
        }
    }
}
