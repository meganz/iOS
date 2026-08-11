import MEGAAppSDKRepo
import MEGADomain
import MEGASwift
import MEGASwiftUI

@MainActor
package final class PromotionalBannerCache {
    static let shared = PromotionalBannerCache()

    private(set) var cachedViewModels = [PromotionalBannerViewModel]()

    private var promotedPlan: PlanEntity?
    private var promotedPlanAccountKey: String?
    private let accountUseCase: any AccountUseCaseProtocol

    /// The plan held for the signed in account, or `nil` when it was cached for a different one, so that
    /// an offer is never shown to whoever logs in next.
    var cachedPromotedPlan: PlanEntity? {
        promotedPlanAccountKey == accountKey ? promotedPlan : nil
    }

    package init(accountUseCase: some AccountUseCaseProtocol = AccountUseCase(repository: AccountRepository.newRepo)) {
        self.accountUseCase = accountUseCase
    }

    func update(with viewModels: [PromotionalBannerViewModel]) {
        cachedViewModels = viewModels
    }

    func removeBanner(withId id: Int) {
        cachedViewModels.removeAll { $0.input.id == id }
    }

    func updatePromotedPlan(_ plan: PlanEntity) {
        promotedPlan = plan
        promotedPlanAccountKey = accountKey
    }

    func clearPromotedPlan() {
        promotedPlan = nil
        promotedPlanAccountKey = nil
    }

    private var accountKey: String? {
        accountUseCase.currentUserHandle.map(String.init)
    }
}
