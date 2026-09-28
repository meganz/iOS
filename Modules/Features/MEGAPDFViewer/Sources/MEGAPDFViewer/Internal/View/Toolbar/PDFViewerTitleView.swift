import MEGADesignToken
import SwiftUI

struct PDFViewerTitleView: View {
    let fileName: String
    let pageIndicatorText: String

    var body: some View {
        if #available(iOS 26.0, *) {
            titleStack
                .padding(.horizontal, TokenSpacing._5)
                .frame(minHeight: 44)
                .glassBackground(in: Capsule())
        } else {
            titleStack
        }
    }

    private var titleStack: some View {
        VStack(spacing: 0) {
            Text(fileName)
                .font(.subheadline.bold())
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .lineLimit(1)
                .truncationMode(.middle)

            if !pageIndicatorText.isEmpty {
                Text(pageIndicatorText)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .lineLimit(1)
            }
        }
    }
}
