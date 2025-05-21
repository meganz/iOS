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
            MEGAAssets.Image.splashScreenMEGALogo
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80, alignment: .center)
            Spacer()
            VStack {
                if viewModel.determinateProgress {
                    ProgressView(value: viewModel.progress, total: viewModel.totalProgress)
                        .tint(TokenColors.Button.brand.swiftUI)
                } else {
                    ProgressIndicator()
                }
                
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

struct ProgressIndicator: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: .medium)
        view.startAnimating()
        return view
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) { }
}
