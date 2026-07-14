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
            switch try await useCase.upgradeOption() {
            case let .available(accountDetails, plan):
                viewState = .upgradeAvailable(
                    accountDetailsEntity: accountDetails,
                    planEntity: plan
                )
            case let .unavailable(accountDetails):
                viewState = .noUpgradeAvailable(accountDetailsEntity: accountDetails)
            }
        } catch {
            viewState = .error
        }
    }
}
