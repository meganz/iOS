import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct SubscriptionPurchaseView: View {
    @StateObject var viewModel: UpgradeAccountPlanViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var hideHeaderBackground = true
    private let compactContentLeadingPadding: CGFloat = 250
    let onDismiss: () -> Void

    /// How far the scroll view can move from the top before it's no longer considered "at the top".
    ///
    /// If the scroll position (after adjusting for any top inset) is less than this value,
    /// the `isAtTop` value will be set to `true`.
    ///
    /// This helps handle small scroll movements or bouncing without losing the "at top" state.
    private let topOffsetThreshold: CGFloat = 5

    var body: some View {
        contentView
            .onChange(of: viewModel.isDismiss) { newValue in
                if newValue {
                    dismiss()
                    onDismiss()
                }
            }
    }

    @ViewBuilder
    var contentView: some View {
        if verticalSizeClass == .compact {
            compactHeightView
        } else {
            regularHeightView
        }
    }

    private var regularHeightView: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                SubscriptionPurchasePageContentView(
                    topOffsetThreshold: topOffsetThreshold,
                    isAtTop: $hideHeaderBackground,
                    viewModel: viewModel,
                    isRegularHeight: true,
                    getStartedButtonTapped: { viewModel.getStartedButtonTapped() }
                )
                .disabled(viewModel.isLoading)

                SubscriptionPurchasePageHeaderView(hideHeaderBackground: $hideHeaderBackground) {
                    viewModel.mayBeLaterButtonTapped()
                }
                .transition(.opacity)
            }

            SubscriptionPurchaseBottomButtonView(viewModel: viewModel)
        }
    }

    private var compactHeightView: some View {
        ZStack(alignment: .top) {
            compactHeightBackgroundImageView
            compactHeightContentView
            compactHeightHeaderView
        }
    }

    private var compactHeightBackgroundImageView: some View {
        GeometryReader { proxy in
            let leadingInset = proxy.safeAreaInsets.leading

            HStack(spacing: 0) {
                Image(.subscriptionImageHeaderLandscape)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: compactContentLeadingPadding + leadingInset)
                    .frame(maxHeight: .infinity)
                    .clipped()

                TokenColors.Background.page.swiftUI
            }
            .ignoresSafeArea()
        }
    }

    private var compactHeightContentView: some View {
        VStack(spacing: 0) {
            SubscriptionPurchasePageContentView(
                topOffsetThreshold: topOffsetThreshold,
                isAtTop: $hideHeaderBackground,
                viewModel: viewModel,
                isRegularHeight: false,
                getStartedButtonTapped: { viewModel.getStartedButtonTapped() }
            )
            .disabled(viewModel.isLoading)
            SubscriptionPurchaseBottomButtonView(viewModel: viewModel)
        }
        .padding(.leading, compactContentLeadingPadding)
    }

    private var compactHeightHeaderView: some View {
        SubscriptionPurchasePageHeaderView(hideHeaderBackground: $hideHeaderBackground) {
            viewModel.mayBeLaterButtonTapped()
        }
        .transition(.opacity)
    }
}
