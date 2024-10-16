import Foundation
import MEGADomain

final class NodeTagsCellViewModel {
    private let accountUseCase: any AccountUseCaseProtocol

    var isPaidAccount: Bool {
        accountUseCase.hasValidSubscription
    }

    init(accountUseCase: some AccountUseCaseProtocol) {
        self.accountUseCase = accountUseCase
    }
}
