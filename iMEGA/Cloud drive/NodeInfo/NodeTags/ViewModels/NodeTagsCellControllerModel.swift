import Foundation
import MEGADomain

@MainActor
final class NodeTagsCellControllerModel {
    private let accountUseCase: any AccountUseCaseProtocol
    private(set) lazy var cellViewModel: NodeTagsCellViewModel = NodeTagsCellViewModel(accountUseCase: accountUseCase)

    var hasValidSubscription: Bool {
        accountUseCase.hasValidSubscription
    }
    
    var currentAccountDetails: AccountDetailsEntity? {
        accountUseCase.currentAccountDetails
    }

    init(accountUseCase: some AccountUseCaseProtocol) {
        self.accountUseCase = accountUseCase
    }
}
