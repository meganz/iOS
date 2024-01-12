import MEGASwiftUI
import SwiftUI

public struct AdsSlotView<T: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel: AdsSlotViewModel
    @State private var showAds: Bool = false
    public let contentView: T

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            contentView
            
            if verticalSizeClass != .compact {
                ZStack {
                    backgroundColor
                    
                    Button {
                        Task { await viewModel.didTapAdsContent() }
                    } label: {
                        Image("close")
                            .background(Color(red: 0.916, green: 0.916, blue: 0.936))
                    }
                    .frame(
                        idealWidth: 24,
                        maxWidth: .infinity,
                        idealHeight: 24,
                        maxHeight: .infinity,
                        alignment: .topTrailing
                    )
                    
                    AdsWebView(url: viewModel.adsUrl,
                               coordinatorViewModel: AdsWebViewCoordinatorViewModel(),
                               adsTapAction: {
                        Task { await viewModel.didTapAdsContent() }
                    })
                    .frame(width: 320, height: 50)
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 20, trailing: 5))
                }
                .transition(.opacity)
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
            await viewModel.setupABTestVariant()
            viewModel.setupSubscriptions()
            viewModel.monitorAdsSlotChanges()
        }
        .ignoresSafeArea()
    }
}
