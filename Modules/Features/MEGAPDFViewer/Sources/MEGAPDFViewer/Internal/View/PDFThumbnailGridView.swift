import MEGADesignToken
import PDFKit
import SwiftUI

struct PDFThumbnailGridView: View {
    let document: PDFDocument
    let currentPage: Int

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: TokenSpacing._3),
        count: 3
    )

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: TokenSpacing._3) {
                    ForEach(0..<document.pageCount, id: \.self) { pageIndex in
                        PDFViewerThumbnailCell(
                            pageIndex: pageIndex,
                            isCurrent: pageIndex == currentPage
                        )
                        .id(pageIndex)
                    }
                }
                .padding(.horizontal, TokenSpacing._3)
            }
            .onAppear {
                scrollProxy.scrollTo(currentPage, anchor: .center)
            }
        }
        .background(TokenColors.Background.page.swiftUI)
    }
}

private struct PDFViewerThumbnailCell: View {
    let pageIndex: Int
    let isCurrent: Bool

    private static let imageAspectRatio: CGFloat = 123.33 / 168

    var body: some View {
        VStack(spacing: TokenSpacing._2) {
            thumbnailContent
                .aspectRatio(Self.imageAspectRatio, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: TokenRadius.small)
                        .strokeBorder(
                            isCurrent
                                ? TokenColors.Border.strongSelected.swiftUI
                                : TokenColors.Border.subtle.swiftUI,
                            lineWidth: isCurrent ? 2 : 1
                        )
                )
            pageNumber
        }
    }

    // Thumbnail image loading will be added in an upcoming MR.
    private var thumbnailContent: some View {
        Color(
            hue: Double((pageIndex * 37) % 360) / 360,
            saturation: 0.25,
            brightness: 0.85
        )
    }

    private var pageNumber: some View {
        Text(String(pageIndex + 1))
            .font(.caption.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(
                isCurrent
                    ? TokenColors.Text.inverseAccent.swiftUI
                    : TokenColors.Text.primary.swiftUI
            )
            .padding(.horizontal, TokenSpacing._2)
            .frame(minWidth: 32, minHeight: 20)
            .background(
                Capsule().fill(
                    isCurrent ? TokenColors.Components.selectionControl.swiftUI : Color.clear
                )
            )
    }
}
