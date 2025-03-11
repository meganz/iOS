import GoogleMobileAds
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
    private let adSize = GADAdSizeBanner
    public let contentView: T

    public var body: some View {
        VStack(spacing: 0) {
            contentView
            
            if viewModel.isExternalAdsEnabled == true {
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
                .frame(height: shouldHideAds ? 0 : 50)
                .background(TokenColors.Background.surface1.swiftUI)
                .opacity(shouldHideAds ? 0 : 1)
            }
        }
        .onFirstAppear(perform: {
            viewModel.onViewFirstAppeared?()
        })
        .onAppear {
            viewModel.setupSubscriptions()
            viewModel.startMonitoringAdsSlotUpdates()
        }
        .onDisappear {
            viewModel.stopMonitoringAdsSlotUpdates()
        }
        .ignoresSafeArea(.keyboard)
        .ignoresSafeArea(edges: shouldHideAds || !(viewModel.isExternalAdsEnabled ?? false) ? .all : [.top])
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
    
    private var shouldHideAds: Bool {
        verticalSizeClass == .compact || !viewModel.displayAds
    }
}
