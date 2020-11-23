import Foundation

enum StartConversationAction: ActionType {
    case viewDidLoad
}

enum StartConversationCommand: CommandType, Equatable {
    case networkAvailablityUpdate(_ isNetworkAvailable: Bool)
}

final class StartConversationViewModel: ViewModelType {

    var invokeCommand: ((StartConversationCommand) -> Void)?

    func dispatch(_ action: StartConversationAction) {
        switch action {
        case .viewDidLoad: registerNetworkListener()
        }
    }
    
    private func registerNetworkListener() {
        reachabilityUseCase.registerNetworkChangeListener { [weak self] networkReachability in
            guard let self = self else { return }
            self.invokeCommand?(.networkAvailablityUpdate(.unreachable != networkReachability))
        }
    }
    
    // MARK: - Properties
    
    private let reachabilityUseCase: ReachabilityUseCaseProtocol
    private let router: NewChatRouter

    init(
        reachabilityUseCase: ReachabilityUseCaseProtocol,
        router: NewChatRouter
    ) {
        self.reachabilityUseCase = reachabilityUseCase
        self.router = router
    }

    // MARK: - Action & Command

    typealias Action = StartConversationAction

    typealias Command = StartConversationCommand
}
