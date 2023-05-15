import Foundation
import MEGAPresentation
import MEGADomain

enum AccountHallAction: ActionType {
    case onViewAppear
}

final class AccountHallViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case reload
    }
    
    var invokeCommand: ((Command) -> Void)?
    var incomingContactRequestsCount = 0
    var relevantUnseenUserAlertsCount: UInt = 0
    
    private let accountHallUsecase: AccountHallUseCaseProtocol
    
    // MARK: - Init
    
    init(accountHallUsecase: AccountHallUseCaseProtocol) {
        self.accountHallUsecase = accountHallUsecase
    }
    
    // MARK: - Dispatch actions
    
    func dispatch(_ action: AccountHallAction) {
        switch action {
        case .onViewAppear:
            fetchCounts()
        }
    }
    
    // MAKR: - Private
    
    private func fetchCounts() {
        Task {
            incomingContactRequestsCount = await accountHallUsecase.incomingContactsRequestsCount()
            relevantUnseenUserAlertsCount = await accountHallUsecase.relevantUnseenUserAlertsCount()
            
            await reloadCounts()
        }
    }
    
    @MainActor
    private func reloadCounts() {
        invokeCommand?(.reload)
    }
}
