import MEGASwiftUI
import SwiftUI

public struct AdsSlotView<T: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @StateObject var viewModel: AdsSlotViewModel
    public let contentView: T

    public var body: some View {
        VStack(spacing: 0) {
            contentView
            
            if viewModel.displayAds && verticalSizeClass != .compact {
                HStack {
                    AdsWebView(url: viewModel.adsUrl,
                               coordinatorViewModel: AdsWebViewCoordinatorViewModel(),
                               adsTapAction: {
                        Task { await viewModel.loadAds() }
                    })
                    .frame(width: 320, height: 50)
                    .padding(.bottom, 10)
                }
                .background(Color.clear)
                .padding(.vertical, 10)
                .padding(.horizontal, 5)
                .frame(height: 100)
            }
        }
        .taskForiOS14 {
            await viewModel.monitorAdsSlotChanges()
        }
        .ignoresSafeArea()
    }
}
