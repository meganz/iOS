import Foundation
import MEGADomain

@MainActor
final class NodeTagsCellViewModel {
    private let accountUseCase: any AccountUseCaseProtocol

    var shouldShowProTag: Bool {
        accountUseCase.isFreeTierUser
    }

    init(accountUseCase: some AccountUseCaseProtocol) {
        self.accountUseCase = accountUseCase
    }
}
