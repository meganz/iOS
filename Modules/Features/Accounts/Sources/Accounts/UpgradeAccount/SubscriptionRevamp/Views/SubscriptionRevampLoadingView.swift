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
                cardPlaceholder
            }
        }
        .padding(.horizontal, TokenSpacing._5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(TokenColors.Background.page.swiftUI)
    }

    private var titlePlaceholder: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._7) {
            placeholderLine
                .frame(maxWidth: .infinity)
            placeholderLine
                .frame(width: 123)
        }
        .shimmering()
    }

    private var cardPlaceholder: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._4) {
            placeholderLine
                .frame(width: 48)
            placeholderLine
                .frame(width: 90)
            placeholderLine
                .frame(width: 230)
            placeholderLine
                .frame(width: 230)
            RoundedRectangle(cornerRadius: TokenRadius.small)
                .fill(placeholderColor)
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .shimmering()
        .padding(TokenSpacing._5)
        .background(
            RoundedRectangle(cornerRadius: TokenRadius.large)
                .fill(TokenColors.Background.page.swiftUI)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TokenRadius.large)
                .stroke(TokenColors.Border.strong.swiftUI, lineWidth: 1)
        )
    }

    private var placeholderLine: some View {
        Capsule()
            .fill(placeholderColor)
            .frame(height: 16)
    }

    private var placeholderColor: Color {
        TokenColors.Text.primary.swiftUI
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
