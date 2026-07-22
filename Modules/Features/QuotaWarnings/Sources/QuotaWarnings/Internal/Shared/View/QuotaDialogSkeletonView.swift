import MEGADesignToken
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

struct QuotaDialogSkeletonView: View {

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: TokenSpacing._5) {
                    titleSection
                    cardPlaceholder
                    cardPlaceholder
                }
                .padding(.horizontal, TokenSpacing._5)
                .padding(.bottom, TokenSpacing._5)
                .maxWidthForWideScreen()
                .frame(maxWidth: .infinity)
            }
        }
        .background(TokenColors.Background.page.swiftUI)
    }

    private var titleSection: some View {
        VStack(spacing: TokenSpacing._4) {
            bar(width: 120, height: 120)
            VStack(alignment: .leading, spacing: TokenSpacing._4) {
                bar(height: 16)
                bar(width: 120, height: 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var cardPlaceholder: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._4) {
            bar(width: 48, height: 16)
            bar(width: 90, height: 16)
            bar(width: 230, height: 16)
            bar(width: 230, height: 16)
            bar(height: 32)
        }
        .padding(TokenSpacing._5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: TokenRadius.large)
                .fill(TokenColors.Background.page.swiftUI)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TokenRadius.large)
                .stroke(TokenColors.Border.strong.swiftUI, lineWidth: 1)
        )
    }

    private func bar(width: CGFloat? = nil, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: TokenRadius.medium)
            .fill(TokenColors.Background.surface2.swiftUI)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

#Preview {
    QuotaDialogSkeletonView()
}
