import MEGAConnectivity
import SwiftUI

/// The shared no-internet / back-online banner on its own, so a UIKit screen can host it (IOS-12411).
struct NoInternetBannerView: View {
    var body: some View {
        Color.clear
            .frame(height: 0)
            .noInternetViewModifier(
                viewModel: MEGAConnectivity.DependencyInjection.networkPathNoInternetViewModel
            )
    }
}

/// Hosts `NoInternetBannerView` for the UIKit screens adopting the new offline mode.
///
/// Sized by its intrinsic content size, which follows the banner appearing and disappearing.
@MainActor
final class NoInternetBannerHostingController: UIHostingController<NoInternetBannerView> {
    init() {
        super.init(rootView: NoInternetBannerView())
        sizingOptions = .intrinsicContentSize
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
