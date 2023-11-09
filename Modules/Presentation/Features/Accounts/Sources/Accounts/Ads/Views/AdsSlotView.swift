import MEGASwiftUI
import SwiftUI

public struct AdsSlotView<T: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @StateObject var viewModel: AdsSlotViewModel
    @State private var showAds: Bool = false
    public let contentView: T

    public var body: some View {
        VStack(spacing: 0) {
            contentView
            
            if verticalSizeClass != .compact {
                HStack {
                    AdsWebView(url: viewModel.adsUrl,
                               coordinatorViewModel: AdsWebViewCoordinatorViewModel(),
                               adsTapAction: {
                        Task { await viewModel.loadNewAds() }
                    })
                    .frame(width: 320, height: 50)
                    .padding(.bottom, 10)
                }
                .transition(.opacity)
                .background(Color.clear)
                .padding(.vertical, 10)
                .padding(.horizontal, 5)
                .frame(height: showAds ? 110 : 0)
                .opacity(showAds ? 1 : 0)
            }
        }
        .onChange(of: viewModel.displayAds) { newValue in
            withAnimation(.easeOut(duration: 0.1)) {
                showAds = newValue
            }
        }
        .task {
            viewModel.monitorAdsSlotChanges()
        }
        .ignoresSafeArea()
    }
}
