import MEGADesignToken
import SwiftUI

struct SearchResultsHeaderView<LeftView: View, RightView: View>: View {
    private enum SearchResultsHeaderViewConstants {
        static var height: CGFloat { 36 }
        static var horizontalPadding: CGFloat { 0 }
        static var spacing: CGFloat { TokenSpacing._3 }
        static var alignment: VerticalAlignment { .center }
    }

    private let height: CGFloat
    private let horizontalPadding: CGFloat
    private let spacing: CGFloat
    private let alignment: VerticalAlignment
    private let leftView: LeftView
    private let rightView: RightView

    private init(
        height: CGFloat,
        horizontalPadding: CGFloat,
        spacing: CGFloat,
        alignment: VerticalAlignment,
        @ViewBuilder _ leftView: () -> LeftView,
        @ViewBuilder _ rightView: () -> RightView
    ) {
        self.height = height
        self.horizontalPadding = horizontalPadding
        self.spacing = spacing
        self.alignment = alignment
        self.leftView = leftView()
        self.rightView = rightView()
    }

    var body: some View {
        HStack(alignment: alignment, spacing: spacing) {
            leftView
            Spacer()
            rightView
        }
        .padding(.horizontal, horizontalPadding)
        .frame(minHeight: height)
    }
}

// Full initializer
extension SearchResultsHeaderView {
    init(
        height: CGFloat = SearchResultsHeaderViewConstants.height,
        horizontalPadding: CGFloat = SearchResultsHeaderViewConstants.horizontalPadding,
        spacing: CGFloat = SearchResultsHeaderViewConstants.spacing,
        alignment: VerticalAlignment = SearchResultsHeaderViewConstants.alignment,
        @ViewBuilder leftView: () -> LeftView,
        @ViewBuilder rightView: () -> RightView
    ) {
        self.init(
            height: height,
            horizontalPadding: horizontalPadding,
            spacing: spacing,
            alignment: alignment,
            leftView,
            rightView
        )
    }
}

// Left-only convenience
extension SearchResultsHeaderView where RightView == EmptyView {
    init(
        height: CGFloat = SearchResultsHeaderViewConstants.height,
        horizontalPadding: CGFloat = SearchResultsHeaderViewConstants.horizontalPadding,
        spacing: CGFloat = SearchResultsHeaderViewConstants.spacing,
        alignment: VerticalAlignment = SearchResultsHeaderViewConstants.alignment,
        @ViewBuilder leftView: () -> LeftView
    ) {
        self.init(
            height: height,
            horizontalPadding: horizontalPadding,
            spacing: spacing,
            alignment: alignment,
            leftView,
            { EmptyView() }
        )
    }
}

// Right-only convenience
extension SearchResultsHeaderView where LeftView == EmptyView {
    init(
        height: CGFloat = SearchResultsHeaderViewConstants.height,
        horizontalPadding: CGFloat = SearchResultsHeaderViewConstants.horizontalPadding,
        spacing: CGFloat = SearchResultsHeaderViewConstants.spacing,
        alignment: VerticalAlignment = SearchResultsHeaderViewConstants.alignment,
        @ViewBuilder rightView: () -> RightView
    ) {
        self.init(
            height: height,
            horizontalPadding: horizontalPadding,
            spacing: spacing,
            alignment: alignment,
            { EmptyView() },
            rightView
        )
    }
}
