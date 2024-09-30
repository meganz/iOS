import MEGADesignToken
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

public struct AdsSlotView<T: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @StateObject var viewModel: AdsSlotViewModel
    public let contentView: T

    public var body: some View {
        VStack(spacing: 0) {
            contentView
            
            if verticalSizeClass != .compact && viewModel.isExternalAdsEnabled {
                AdMobBannerView(
                    refreshAdsPublisher: viewModel.refreshAdsPublisher,
                    adMobUnitID: viewModel.adMobUnitID
                )
                .transition(.opacity)
                .frame(height: viewModel.displayAds ? 100 : 0)
                .opacity(viewModel.displayAds ? 1 : 0)
            }
        }
        .task {
            await viewModel.setupABTestVariant()
            await viewModel.initializeGoogleAds()
            await viewModel.monitorAdsSlotChanges()
        }
        .onAppear {
            viewModel.setupSubscriptions()
        }
        .ignoresSafeArea()
    }
}
