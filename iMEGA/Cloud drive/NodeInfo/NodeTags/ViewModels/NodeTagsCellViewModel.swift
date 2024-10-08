import Foundation
import MEGADomain

final class NodeTagsCellViewModel {
    private let accountUseCase: any AccountUseCaseProtocol

    var isProUser: Bool {
        accountUseCase.hasValidProOrUnexpiredBusinessAccount()
    }

    init(accountUseCase: some AccountUseCaseProtocol) {
        self.accountUseCase = accountUseCase
    }
}
