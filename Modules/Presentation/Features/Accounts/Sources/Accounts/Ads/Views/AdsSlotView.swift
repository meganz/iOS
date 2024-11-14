import MEGADesignToken
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

/// AdsSlotView is a view that displays the main content of the app, with an optional banner ad positioned at the bottom of the screen.
/// `shouldHideAds`: This checks whether ads should be hidden on a tab such as Home, Photos and Cloud Drive tab. Chat and Shared Item tab will not contain ads. It evaluates both the current verticalSizeClass and the state of ad enablement. VerticalSizeClass should be `.regular` only, applicable for both iPhone and iPad.
/// `displayAds`: This determines if ads should be hidden. Even when isExternalAdsEnabled returns true, ads might still be hidden if the contentView is navigated to a screen where ads should not be displayed. For instance, when a user navigates to the "Account" page from the Home, Photos or Cloud drive tab, the ad will be hidden.
public struct AdsSlotView<T: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @StateObject var viewModel: AdsSlotViewModel
    public let contentView: T

    public var body: some View {
        VStack(spacing: 0) {
            contentView
            
            if viewModel.isExternalAdsEnabled == true {
                AdMobBannerView(adMob: viewModel.adMob)
                    .background()
                    .frame(height: shouldHideAds ? 0 : 50)
                    .opacity(shouldHideAds ? 0 : 1)
            }
        }
        .onFirstAppear(perform: {
            viewModel.onViewFirstAppeared?()
        })
        .task {
            await viewModel.setupAdsRemoteFlag()
            await viewModel.initializeGoogleAds()
        }
        .onAppear {
            viewModel.startMonitoringAdsSlotUpdates()
            viewModel.setupSubscriptions()
        }
        .onDisappear {
            viewModel.stopMonitoringAdsSlotUpdates()
        }
        .ignoresSafeArea(.keyboard)
        .ignoresSafeArea(edges: shouldHideAds || !(viewModel.isExternalAdsEnabled ?? false) ? .all : [.top])
    }
    
    private var shouldHideAds: Bool {
        verticalSizeClass == .compact || !viewModel.displayAds
    }
}
