import SwiftUI

/// AdsSlotView is a view that displays the main content of the app, with an optional banner ad positioned at the bottom of the screen.
/// Screens that draw the ad inside their own layout instead of under their whole content embed `AdsBannerView` directly.
/// Whether there is a banner to make room for at all is `AdsSlotViewModel.bannerHeight(isVerticallyCompact:)`, which the banner itself reads too. VerticalSizeClass should be `.regular` only, applicable for both iPhone and iPad.
/// `displayAds`: This determines if ads should be hidden. Even when isExternalAdsEnabled returns true, ads might still be hidden if the contentView is navigated to a screen where ads should not be displayed. For instance, when a user navigates to the "Account" page from the Home, Photos or Cloud drive tab, the ad will be hidden.
public struct AdsSlotView<T: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @StateObject var viewModel: AdsSlotViewModel
    public let contentView: T

    public var body: some View {
        VStack(spacing: 0) {
            contentView

            AdsBannerView(viewModel: viewModel)
        }
        .ignoresSafeArea(.keyboard)
        .ignoresSafeArea(edges: bannerHeight == 0 ? .all : [.top])
    }

    /// The screen gives up its bottom safe area to the banner only while the banner is on screen.
    private var bannerHeight: CGFloat {
        viewModel.bannerHeight(isVerticallyCompact: verticalSizeClass == .compact)
    }
}
