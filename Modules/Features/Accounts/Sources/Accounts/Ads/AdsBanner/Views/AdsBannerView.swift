import GoogleMobileAds
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

/// The ad banner on its own, with no assumption about where on the screen it sits: `AdsSlotView`
/// stacks it under a screen's whole content, while screens that draw the ad somewhere in the middle
/// of their own layout embed it directly.
public struct AdsBannerView: View {
    /// The AdMob formats the designs ask for. Both are fixed creative sizes: the banner renders at
    /// that width whatever the screen's is, centred, rather than stretching to fill it.
    public enum Format {
        /// 320x50, the slot under a screen's whole content.
        case banner
        /// 320x100, the area the file link gives the ad inside its own layout.
        case largeBanner

        var adSize: AdSize {
            switch self {
            case .banner: AdSizeBanner
            case .largeBanner: AdSizeLargeBanner
            }
        }

        /// The gap the bottom slot keeps between the screen's content and the ad. An embedded area is
        /// spaced by the layout it sits in, so it adds none of its own.
        var topSpacing: CGFloat {
            switch self {
            case .banner: 5
            case .largeBanner: 0
            }
        }
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ObservedObject private var viewModel: AdsSlotViewModel
    private let format: Format

    public init(
        viewModel: AdsSlotViewModel,
        format: Format = .banner
    ) {
        self.viewModel = viewModel
        self.format = format
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
                adSize: format.adSize,
                adMob: viewModel.adMob,
                bannerViewDidReceiveAdsUpdate: { [weak viewModel] result in
                    viewModel?.bannerViewDidReceiveAdsUpdate(result: result)
                }
            )
            .frame(
                width: format.adSize.size.width,
                height: format.adSize.size.height
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
        .padding(.top, format.topSpacing)
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

    /// The room the banner takes: its format's height while there is an ad on show, none otherwise.
    private var height: CGFloat {
        guard viewModel.isBannerVisible(isVerticallyCompact: verticalSizeClass == .compact) else {
            return 0
        }
        
        return format.adSize.size.height
    }
}
