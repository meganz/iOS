import MEGADesignToken
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

/// AdsSlotView is a view that displays the main content of the app, with an optional banner ad positioned at the bottom of the screen.
/// `shouldContainAds`: This checks whether ads should be displayed on the view. It evaluates both the current verticalSizeClass and the state of ad enablement. VerticalSizeClass should be `.regular` only, applicable for both iPhone and iPad.
/// `displayAds`: This determines if ads should be hidden. Even when shouldContainAds returns true, ads might still be hidden if the contentView is navigated to a screen where ads should not be displayed, such as the "Chats" or "Shared Items" tabs. For instance, when a user navigates to the "Account" page from the Home, Photos or Cloud drive tab, the ad will be hidden.
public struct AdsSlotView<T: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @StateObject var viewModel: AdsSlotViewModel
    public let contentView: T

    public var body: some View {
        VStack(spacing: 0) {
            contentView
            
            if shouldContainAds {
                AdMobBannerView(
                    refreshAdsPublisher: viewModel.refreshAdsPublisher,
                    adMob: viewModel.adMob
                )
                .transition(.opacity)
                .frame(height: viewModel.displayAds ? 50 : 0)
                .opacity(viewModel.displayAds ? 1 : 0)
            }
        }
        .task {
            await viewModel.setupAdsRemoteFlag()
            await viewModel.initializeGoogleAds()
            await viewModel.monitorAdsSlotChanges()
        }
        .onAppear {
            viewModel.setupSubscriptions()
        }
        .ignoresSafeArea(
            edges: shouldContainAds && viewModel.displayAds ? [.top] : .all
        )
    }
    
    private var shouldContainAds: Bool {
        verticalSizeClass != .compact && viewModel.isExternalAdsEnabled
    }
}
