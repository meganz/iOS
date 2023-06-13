import Foundation
import MEGADomain
import MEGAPresentation

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
        networkMonitorUseCase.networkPathChanged { [weak self] (connected) in
            guard let self = self else { return }
            self.invokeCommand?(.networkAvailablityUpdate(connected))
        }
    }
    
    // MARK: - Properties
    
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let router: NewChatRouter

    init(
        networkMonitorUseCase: any NetworkMonitorUseCaseProtocol,
        router: NewChatRouter
    ) {
        self.networkMonitorUseCase = networkMonitorUseCase
        self.router = router
    }

    // MARK: - Action & Command

    typealias Action = StartConversationAction

    typealias Command = StartConversationCommand
}
