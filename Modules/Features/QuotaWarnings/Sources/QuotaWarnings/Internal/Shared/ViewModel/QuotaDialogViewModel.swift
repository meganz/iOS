import MEGADomain
import SwiftUI

@MainActor
final class QuotaDialogViewModel: ObservableObject {
    enum ViewState {
        case loading
        case error
        case upgradeAvailable(accountDetailsEntity: AccountDetailsEntity, planEntity: PlanEntity)
        case noUpgradeAvailable(accountDetailsEntity: AccountDetailsEntity)
    }

    @Published var viewState: ViewState = .loading

    private let useCase: any QuotaDialogUseCaseProtocol

    init(useCase: some QuotaDialogUseCaseProtocol) {
        self.useCase = useCase
    }

    func load() async {
        do {
            async let account = useCase.accountDetails()
            async let plan = useCase.recommendedPlan()

            let (accountDetailsEntity, planEntity) = try await (account, plan)

            if let planEntity {
                viewState = .upgradeAvailable(
                    accountDetailsEntity: accountDetailsEntity,
                    planEntity: planEntity
                )
            } else {
                viewState = .noUpgradeAvailable(accountDetailsEntity: accountDetailsEntity)
            }
        } catch {
            viewState = .error
        }
    }
}
