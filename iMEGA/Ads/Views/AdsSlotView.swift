import MEGASwiftUI
import SwiftUI

struct AdsSlotView<T: View>: View {
    @StateObject var viewModel: AdsSlotViewModel
    var contentView: T
    
    var body: some View {
        VStack(spacing: 0) {
            contentView
            
            if viewModel.displayAds {
                AdsWebView(url: viewModel.adsUrl, adsTapAction: {
                    viewModel.fetchNewAds()
                })
                .background(Color.clear)
                .padding(.vertical, 15)
                .padding(.horizontal, 5)
                .frame(height: 110)
            }
        }
        .taskForiOS14 {
            await viewModel.setUpAdSlot()
            await viewModel.loadAds()
        }
        .ignoresSafeArea()
    }
}
