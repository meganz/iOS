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
        do {
            switch try await useCase.upgradeOption() {
            case let .available(accountDetails, recommendedPlan):
                viewState = .upgradeAvailable(
                    header: mapper.header(accountDetails: accountDetails),
                    currentPlan: mapper.currentPlan(accountDetails: accountDetails),
                    recommendedPlan: mapper.recommendedPlan(recommendedPlan, accountDetails: accountDetails)
                )
            case let .unavailable(accountDetails):
                viewState = .noUpgradeAvailable(
                    header: mapper.header(accountDetails: accountDetails),
                    currentPlan: mapper.currentPlan(accountDetails: accountDetails)
                )
            }
        } catch {
            viewState = .error
        }
    }
}
