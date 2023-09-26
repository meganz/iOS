import MEGASwiftUI
import SwiftUI

public struct AdsSlotView<T: View>: View {
    @StateObject var viewModel: AdsSlotViewModel
    public let contentView: T

    public var body: some View {
        VStack(spacing: 0) {
            contentView
            
            if viewModel.displayAds {
                AdsWebView(url: viewModel.adsUrl,
                           coordinatorViewModel: AdsWebViewCoordinatorViewModel(),
                           adsTapAction: {
                    Task { await viewModel.loadAds() }
                })
                .background(Color.clear)
                .padding(.vertical, 15)
                .padding(.horizontal, 5)
                .frame(height: 110)
            }
        }
        .taskForiOS14 {
            await viewModel.monitorAdsSlotChanges()
        }
        .ignoresSafeArea()
    }
}
