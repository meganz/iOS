import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGASwift

/// Wires up the ad banner for screens that draw it inside their own layout, at a place of their
/// choosing, rather than letting `AdsSlotRouter` stack it under the whole screen.
@MainActor
public struct AdsBannerViewBuilder {
    private let accountUseCase: any AccountUseCaseProtocol
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let nodeUseCase: (any NodeUseCaseProtocol)?
    private let publicLink: String?
    private let isFolderLink: Bool
    
    public init(
        accountUseCase: some AccountUseCaseProtocol,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        nodeUseCase: (any NodeUseCaseProtocol)? = nil,
        publicLink: String? = nil,
        isFolderLink: Bool = false
    ) {
        self.accountUseCase = accountUseCase
        self.purchaseUseCase = purchaseUseCase
        self.nodeUseCase = nodeUseCase
        self.publicLink = publicLink
        self.isFolderLink = isFolderLink
    }
    
    public func build(
        format: AdsBannerView.Format,
        adsFreeViewProPlanAction: (() -> Void)? = nil
    ) -> AdsBannerView {
        let viewModel = AdsSlotViewModel(
            adsSlotUpdatesProvider: EmbeddedAdsSlotUpdatesProvider(),
            adsUseCase: AdsUseCase(repository: AdsRepository.newRepo),
            nodeUseCase: nodeUseCase,
            appEnvironmentUseCase: AppEnvironmentUseCase.appShared,
            accountUseCase: accountUseCase,
            purchaseUseCase: purchaseUseCase,
            preferenceUseCase: PreferenceUseCase.default,
            adsFreeViewProPlanAction: adsFreeViewProPlanAction,
            publicNodeLink: publicLink,
            isFolderLink: isFolderLink
        )
        
        return AdsBannerView(viewModel: viewModel, format: format)
    }
}

/// An embedded banner is part of the screen that shows it, so it comes and goes with that screen and
/// its slot never has to be reconfigured, unlike the one under a tab that hides as the tab navigates.
@MainActor
private struct EmbeddedAdsSlotUpdatesProvider: AdsSlotUpdatesProviderProtocol {
    var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> {
        SingleItemAsyncSequence(item: AdsSlotConfig(displayAds: true))
            .eraseToAnyAsyncSequence()
    }
}
