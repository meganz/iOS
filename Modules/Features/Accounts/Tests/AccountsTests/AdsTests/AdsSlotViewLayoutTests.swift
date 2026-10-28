@testable import Accounts
import AccountsMock
import MEGAAppPresentationMock
import MEGADomainMock
import MEGAPreferenceMocks
import SwiftUI
import Testing

@MainActor
@Suite("AdsSlotView layout")
struct AdsSlotViewLayoutTests {
    /// A vertical tab bar (iPhone Duo) adds a side safe area. A content view controller that leaves it out
    /// sees no room for the vertical bar, so its tab bar stays horizontal.
    @Test("Content covers the side safe area and keeps its inset while the banner shows")
    func contentCoversSideSafeArea_whenBannerIsVisible() {
        let sideInset: CGFloat = 84
        let content = UIViewController()
        let viewModel = makeViewModel()
        viewModel.isExternalAdsEnabled = true
        viewModel.displayAds = true
        viewModel.adsLoadingState = .loaded
        #expect(viewModel.isBannerVisible(isVerticallyCompact: false))

        let host = UIHostingController(rootView: AdsSlotView(viewModel: viewModel, contentView: ContentWrapper(viewController: content)))
        host.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: sideInset)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 466, height: 678))
        window.rootViewController = host
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        let contentFrame = content.view.convert(content.view.bounds, to: window)
        #expect(contentFrame.minX == 0)
        #expect(contentFrame.width == window.bounds.width)
        #expect(content.view.safeAreaInsets.right == sideInset)
        window.isHidden = true
    }

    private func makeViewModel() -> AdsSlotViewModel {
        AdsSlotViewModel(
            adsSlotUpdatesProvider: MockAdsSlotUpdatesProvider(),
            adsUseCase: MockAdsUseCase(),
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.externalAds: true]),
            adMobConsentManager: MockGoogleMobileAdsConsentManager(),
            appEnvironmentUseCase: MockAppEnvironmentUseCase(),
            accountUseCase: MockAccountUseCase(),
            purchaseUseCase: MockAccountPlanPurchaseUseCase(),
            preferenceUseCase: MockPreferenceUseCase(),
            tracker: MockTracker(),
            notificationCenter: NotificationCenter(),
            isFolderLink: false
        )
    }
}

private struct ContentWrapper: UIViewControllerRepresentable {
    let viewController: UIViewController
    func makeUIViewController(context: Context) -> UIViewController { viewController }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
