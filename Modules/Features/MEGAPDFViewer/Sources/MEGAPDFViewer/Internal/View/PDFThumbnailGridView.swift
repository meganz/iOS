import MEGADesignToken
import PDFKit
import SwiftUI

private enum PDFThumbnailMetrics {
    static let columnCount = 3
    static let aspectRatio: CGFloat = 123.33 / 168
}

struct PDFThumbnailGridView: View {
    let document: PDFDocument
    let currentPage: Int
    let thumbnailLoader: any PDFThumbnailLoading

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: TokenSpacing._3),
        count: PDFThumbnailMetrics.columnCount
    )

    init(
        document: PDFDocument,
        currentPage: Int,
        thumbnailLoader: some PDFThumbnailLoading
    ) {
        self.document = document
        self.currentPage = currentPage
        self.thumbnailLoader = thumbnailLoader
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVGrid(columns: columns, spacing: TokenSpacing._3) {
                        ForEach(0..<document.pageCount, id: \.self) { pageIndex in
                            PDFViewerThumbnailCell(
                                pageIndex: pageIndex,
                                isCurrent: pageIndex == currentPage,
                                renderSize: renderSize(forGridWidth: proxy.size.width),
                                thumbnailLoader: thumbnailLoader
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
        }
        .background(TokenColors.Background.page.swiftUI)
    }

    /// The size `LazyVGrid` gives a cell, so a page renders at its display size
    /// on every device instead of a fixed point size.
    private func renderSize(forGridWidth gridWidth: CGFloat) -> CGSize {
        let columnCount = CGFloat(PDFThumbnailMetrics.columnCount)
        let horizontalSpace = TokenSpacing._3 * (columnCount - 1)
            + TokenSpacing._3 * 2
        let width = max(0, (gridWidth - horizontalSpace) / columnCount)
        return CGSize(
            width: width,
            height: width / PDFThumbnailMetrics.aspectRatio
        )
    }
}

private struct ThumbnailTaskID: Hashable {
    let pageIndex: Int
    let pixelWidth: Int
    let pixelHeight: Int
}

private struct PDFViewerThumbnailCell: View {
    let pageIndex: Int
    let isCurrent: Bool
    let renderSize: CGSize
    let thumbnailLoader: any PDFThumbnailLoading

    @Environment(\.displayScale) private var displayScale
    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(spacing: TokenSpacing._2) {
            thumbnailContent
                .aspectRatio(PDFThumbnailMetrics.aspectRatio, contentMode: .fit)
                .background(TokenColors.Background.surface2.swiftUI)
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
        // Truncated like the cache key in `PDFThumbnailLoader`, so a sub-pixel
        // layout change does not restart the render.
        .task(id: ThumbnailTaskID(
            pageIndex: pageIndex,
            pixelWidth: Int(renderSize.width * displayScale),
            pixelHeight: Int(renderSize.height * displayScale)
        )) {
            thumbnail = nil
            let image = await thumbnailLoader.thumbnail(
                forPageAt: pageIndex,
                size: renderSize,
                displayScale: displayScale
            )
            guard !Task.isCancelled else { return }
            thumbnail = image
        }
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFit()
                .padding(TokenSpacing._2)
        } else {
            Color.clear
        }
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
