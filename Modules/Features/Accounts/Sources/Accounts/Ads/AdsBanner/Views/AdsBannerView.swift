import GoogleMobileAds
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

/// The ad banner on its own, with no assumption about where on the screen it sits: `AdsSlotView`
/// stacks it under a screen's whole content, while screens that draw the ad somewhere in the middle
/// of their own layout embed it directly.
public struct AdsBannerView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ObservedObject private var viewModel: AdsSlotViewModel
    private let adSize = AdSizeBanner

    public init(viewModel: AdsSlotViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            if viewModel.isExternalAdsEnabled == true {
                banner
            }
        }
        .onAppear {
            viewModel.setupSubscriptions()
            viewModel.startMonitoringAdsSlotUpdates()
            viewModel.startMonitoringOnAccountUpdates()
        }
        .onDisappear {
            viewModel.stopMonitoringAdsSlotUpdates()
            viewModel.stopMonitoringOnAccountUpdates()
        }
    }

    private var banner: some View {
        HStack(alignment: .top, spacing: 0) {
            AdMobBannerView(
                adSize: adSize,
                adMob: viewModel.adMob,
                bannerViewDidReceiveAdsUpdate: { [weak viewModel] result in
                    viewModel?.bannerViewDidReceiveAdsUpdate(result: result)
                }
            )
            .frame(
                width: adSize.size.width,
                height: adSize.size.height
            )

            if viewModel.showCloseButton {
                closeButton
                    .frame(width: 16, height: 16)
                    .adaptiveSheetModal(isPresented: $viewModel.showAdsFreeView) {
                        AdsFreeView(
                            viewModel: AdsFreeViewModel(
                                purchaseUseCase: viewModel.purchaseUseCase,
                                viewProPlanAction: viewModel.adsFreeViewProPlanAction
                            )
                        )
                        .interactiveDismissDisabled()
                    }
            }
        }
        .padding(.top, 5)
        .frame(maxWidth: .infinity)
        // Both the height and the opacity are driven by the same value: the banner is there but
        // takes no room and shows nothing until an ad has loaded into it.
        .frame(height: height)
        .background(TokenColors.Background.surface1.swiftUI)
        .opacity(height == 0 ? 0 : 1)
        // A zero height frame does not clip what it holds, so the banner is still laid out over the
        // content below it and, invisible as it is, would still take that content's taps.
        .allowsHitTesting(height != 0)
    }

    private var closeButton: some View {
        Button {
            viewModel.didTapCloseAdsButton()
        } label: {
            Image("close")
                .resizable(capInsets: EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2))
                .renderingMode(.template)
                .foregroundStyle(TokenColors.Button.primary.swiftUI)
        }
        .background(TokenColors.Background.page.swiftUI)
    }

    private var height: CGFloat {
        viewModel.bannerHeight(isVerticallyCompact: verticalSizeClass == .compact)
    }
}
