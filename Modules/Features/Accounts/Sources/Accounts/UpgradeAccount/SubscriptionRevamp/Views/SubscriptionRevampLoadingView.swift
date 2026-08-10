import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

/// Skeleton loading state for the redesigned subscription page: two heading
/// lines followed by three plan cards, shimmering while data loads.
public struct SubscriptionRevampLoadingView: View {
    @Environment(\.dismiss) private var dismiss
    private let cardCount = 3

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._5) {
            navigationHeader
            titlePlaceholder
            ForEach(0..<cardCount, id: \.self) { _ in
                SubscriptionPlanCardPlaceholderView()
            }
        }
        .padding(.horizontal, TokenSpacing._5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(TokenColors.Background.page.swiftUI)
    }

    private var titlePlaceholder: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._7) {
            SubscriptionPlaceholderLine()
                .frame(maxWidth: .infinity)
            SubscriptionPlaceholderLine()
                .frame(width: 123)
        }
        .shimmering()
    }

    // MARK: - Navigation header

    private var navigationHeader: some View {
        HStack {
            headerButton

            Spacer()
        }
        .padding(.horizontal, TokenSpacing._2)
        .padding(.vertical, TokenSpacing._3)
    }

    private var headerButton: some View {
        Button {
            dismiss()
        } label: {
            MEGAAssets.Image.monoChevronLeftMediumThinOutline
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .glassCircle()
        .accessibilityLabel(Strings.Localizable.close)
    }
}

#Preview {
    SubscriptionRevampLoadingView()
}
