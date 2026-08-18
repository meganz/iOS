import Foundation
import MEGADomain

public protocol AppOpenPromoDialogUseCaseProtocol: Sendable {
    /// The plan whose offer should be advertised as the app opens by presenting the promo dialog, along with whether
    /// other plans are on offer, or `nil` when nothing should be shown: no advertisable offer, or one the reshow
    /// interval still holds back.
    func promotedPlanToPresent() async throws -> PromotedPlanFetchResult?
    /// Records that the dialog was shown for `promotedPlan`'s offer, spending its reshow allowance.
    /// Only call this once the dialog actually appeared on screen.
    func recordDialogShown(for promotedPlan: PromotedPlanEntity)
}

public struct AppOpenPromoDialogUseCase: AppOpenPromoDialogUseCaseProtocol {
    private let promotedPlanUseCase: any PromotedPlanUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let makeAllowance: @Sendable (HandleEntity, MobileOfferEntity) -> any PromoDialogReshowAllowing

    public init(
        promotedPlanUseCase: some PromotedPlanUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol
    ) {
        self.init(
            promotedPlanUseCase: promotedPlanUseCase,
            accountUseCase: accountUseCase,
            makeAllowance: { PromoDialogReshowAllowance.onAppOpen(accountHandle: $0, offer: $1) }
        )
    }

    init(
        promotedPlanUseCase: some PromotedPlanUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        makeAllowance: @escaping @Sendable (HandleEntity, MobileOfferEntity) -> any PromoDialogReshowAllowing
    ) {
        self.promotedPlanUseCase = promotedPlanUseCase
        self.accountUseCase = accountUseCase
        self.makeAllowance = makeAllowance
    }

    public func promotedPlanToPresent() async throws -> PromotedPlanFetchResult? {
        guard let accountHandle = accountUseCase.currentUserHandle else { return nil }
        guard let fetchResult = try await promotedPlanUseCase.fetchPromotedPlan(checksForExpiry: true) else { return nil }
        guard makeAllowance(accountHandle, fetchResult.promotedPlan.offer).isAvailable else { return nil }
        return fetchResult
    }

    public func recordDialogShown(for promotedPlan: PromotedPlanEntity) {
        guard let accountHandle = accountUseCase.currentUserHandle else { return }
        makeAllowance(accountHandle, promotedPlan.offer).consume()
    }
}
