import MEGADomain
import MEGAInfrastructure
import SwiftUI

@MainActor
final class QuotaDialogViewModel: ObservableObject {
    enum ViewState {
        case loading
        case error
        case upgradeAvailable(header: QuotaDialogHeader, currentPlan: CurrentPlan?, recommendedPlan: RecommendedPlan, audience: QuotaDialogAudience)
        case noUpgradeAvailable(header: QuotaDialogHeader, currentPlan: CurrentPlan?, supportEmail: EmailEntity, audience: QuotaDialogAudience)
        case signIn(header: QuotaDialogHeader, recommendedPlan: RecommendedPlan)
    }

    @Published var viewState: ViewState = .loading

    private let useCase: any QuotaDialogUseCaseProtocol
    private let mapper: any QuotaDialogMapping
    private let emailFormatter: CustomPlanEmailFormatter

    init(
        useCase: some QuotaDialogUseCaseProtocol,
        mapper: some QuotaDialogMapping,
        emailFormatter: CustomPlanEmailFormatter = CustomPlanEmailFormatter()
    ) {
        self.useCase = useCase
        self.mapper = mapper
        self.emailFormatter = emailFormatter
    }

    func load() async {
        viewState = .loading
        do {
            switch try await useCase.upgradeOption() {
            case let .available(accountDetails, recommendedPlan):
                viewState = .upgradeAvailable(
                    header: mapper.header(accountDetails: accountDetails, canUpgrade: true),
                    currentPlan: mapper.currentPlan(accountDetails: accountDetails),
                    recommendedPlan: mapper.recommendedPlan(recommendedPlan, accountDetails: accountDetails),
                    audience: audience(for: accountDetails)
                )
            case let .unavailable(accountDetails):
                viewState = .noUpgradeAvailable(
                    header: mapper.header(accountDetails: accountDetails, canUpgrade: false),
                    currentPlan: mapper.currentPlan(accountDetails: accountDetails),
                    supportEmail: emailFormatter.makeEmail(
                        planName: mapper.planName(accountDetails: accountDetails),
                        userEmail: useCase.userEmail
                    ),
                    audience: audience(for: accountDetails)
                )
            case let .signIn(recommendedPlan):
                viewState = .signIn(
                    header: mapper.header(accountDetails: nil, canUpgrade: true),
                    recommendedPlan: mapper.recommendedPlan(recommendedPlan, accountDetails: nil)
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

    // MARK: - Private

    private func audience(for accountDetails: AccountDetailsEntity) -> QuotaDialogAudience {
        accountDetails.isFree ? .free : .paid
    }
}
