import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct AppLoadingView: View {
    @StateObject private var viewModel: AppLoadingViewModel
    
    public init(viewModel: @autoclosure @escaping () -> AppLoadingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    var body: some View {
        VStack {
            Spacer()
            MEGAAssetsImageProvider.image(named: .splashScreenMEGALogo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80, alignment: .center)
            Spacer()
            VStack {
                ProgressView(value: viewModel.progress, total: viewModel.totalProgress)
                    .tint(TokenColors.Button.brand.swiftUI)
                    .scaleEffect(x: 1, y: (viewModel.progress != nil) ? 1.6 : 1)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text(viewModel.statusText)
                    .padding([.top], TokenSpacing._4)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .padding(EdgeInsets(top: 0, leading: TokenSpacing._17, bottom: TokenSpacing._16, trailing: TokenSpacing._17))
        }
        .background()
        .task {
            await viewModel.onViewAppear()
        }
    }
}
