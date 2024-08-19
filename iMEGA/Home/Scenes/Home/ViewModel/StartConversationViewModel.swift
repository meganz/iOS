import Combine
import Foundation
import MEGADomain
import MEGAPresentation

enum StartConversationAction: ActionType {
    case viewDidLoad
}

enum StartConversationCommand: CommandType, Equatable {
    case networkAvailabilityUpdate(_ isNetworkAvailable: Bool)
}

final class StartConversationViewModel: ViewModelType {
    private var cancellable: Set<AnyCancellable> = []
    
    var invokeCommand: ((StartConversationCommand) -> Void)?

    func dispatch(_ action: StartConversationAction) {
        switch action {
        case .viewDidLoad: registerNetworkListener()
        }
    }
    
    private func registerNetworkListener() {
        networkMonitorUseCase.networkPathChangedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasNetworkConnection in
                guard let self else { return }
                self.invokeCommand?(.networkAvailabilityUpdate(hasNetworkConnection))
            }
            .store(in: &cancellable)
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
