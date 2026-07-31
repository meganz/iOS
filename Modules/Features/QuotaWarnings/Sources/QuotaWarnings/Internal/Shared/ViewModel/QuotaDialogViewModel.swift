import MEGADomain
import SwiftUI

@MainActor
final class QuotaDialogViewModel: ObservableObject {
    enum ViewState {
        case loading
        case error
        case upgradeAvailable(header: QuotaDialogHeader, currentPlan: CurrentPlan, recommendedPlan: RecommendedPlan)
        case noUpgradeAvailable(header: QuotaDialogHeader, currentPlan: CurrentPlan)
    }

    @Published var viewState: ViewState = .loading

    private let useCase: any QuotaDialogUseCaseProtocol
    private let mapper: any QuotaDialogMapping

    init(
        useCase: some QuotaDialogUseCaseProtocol,
        mapper: some QuotaDialogMapping
    ) {
        self.useCase = useCase
        self.mapper = mapper
    }

    func load() async {
        viewState = .loading
        do {
            switch try await useCase.upgradeOption() {
            case let .available(accountDetails, recommendedPlan):
                viewState = .upgradeAvailable(
                    header: mapper.header(accountDetails: accountDetails, canUpgrade: true),
                    currentPlan: mapper.currentPlan(accountDetails: accountDetails),
                    recommendedPlan: mapper.recommendedPlan(recommendedPlan, accountDetails: accountDetails)
                )
            case let .unavailable(accountDetails):
                viewState = .noUpgradeAvailable(
                    header: mapper.header(accountDetails: accountDetails, canUpgrade: false),
                    currentPlan: mapper.currentPlan(accountDetails: accountDetails)
                )
            }
        } catch is CancellationError {
            // The view disappeared, or a logout tore the products down. Either way this dialog is
            // on its way out, so leave the state alone rather than flashing an error at it.
        } catch {
            viewState = .error
        }
    }
    
    func retry() async {
        await load()
    }
}
