import Foundation
import MEGAAppPresentation
import MEGADomain

enum StartConversationAction: ActionType {
    case viewDidLoad
}

enum StartConversationCommand: CommandType, Equatable {
    case networkAvailabilityUpdate(_ isNetworkAvailable: Bool)
}

final class StartConversationViewModel: ViewModelType {
    private var networkMonitorTask: Task<Void, Never>?
    
    var invokeCommand: ((StartConversationCommand) -> Void)?

    func dispatch(_ action: StartConversationAction) {
        switch action {
        case .viewDidLoad: registerNetworkListener()
        }
    }
    
    @MainActor
    private func registerNetworkListener() {
        let connectionSequence = networkMonitorUseCase.connectionSequence
        
        networkMonitorTask = Task { [weak self] in
            for await isConnected in connectionSequence {
                self?.invokeCommand?(.networkAvailabilityUpdate(isConnected))
            }
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
    
    deinit {
        networkMonitorTask?.cancel()
        networkMonitorTask = nil
    }

    // MARK: - Action & Command

    typealias Action = StartConversationAction

    typealias Command = StartConversationCommand
}
