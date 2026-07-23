import MEGADesignToken
import MEGAUIComponent
import SwiftUI

/// Shared chrome for the redesigned subscription pages.
///
/// Owns the navigation header (close / "Maybe later" dismiss button, scroll-driven
/// glass background), the scroll container with its scroll-position tracking, and
/// the regular/compact size-class layouts. The promo and standard pages supply
/// only what differs: the header image and the scrollable content.
struct SubscriptionBaseView<RegularHeader: View, Content: View>: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var isAtTop = true
    @State private var topInset: CGFloat = 0

    private let compactContentLeadingPadding: CGFloat = 250
    private let coordinateSpaceName = "SubscriptionRevampScroll"
    private let topOffsetThreshold: CGFloat = 5

    private let compactHeaderImage: Image
    private let closeButtonType: SubscriptionNavigationHeader.CloseButtonType
    private let dismissAction: () -> Void
    private let regularHeader: RegularHeader
    private let content: Content

    init(
        compactHeaderImage: Image,
        closeButtonType: SubscriptionNavigationHeader.CloseButtonType = .close,
        dismissAction: @escaping () -> Void,
        @ViewBuilder regularHeader: () -> RegularHeader,
        @ViewBuilder content: () -> Content
    ) {
        self.compactHeaderImage = compactHeaderImage
        self.closeButtonType = closeButtonType
        self.dismissAction = dismissAction
        self.regularHeader = regularHeader()
        self.content = content()
    }

    private var isRegularHeight: Bool { verticalSizeClass != .compact }

    private var compactTopInset: CGFloat {
        isRegularHeight ? 0 : TokenSpacing._11
    }

    var body: some View {
        ZStack(alignment: .top) {
            layoutView
                .background(TokenColors.Background.page.swiftUI)
                .ignoresSafeArea()

            SubscriptionNavigationHeader(
                closeButtonType: closeButtonType,
                isAtTop: isAtTop,
                dismissAction: dismissAction
            )
        }
    }

    // MARK: - Layout

    @ViewBuilder
    private var layoutView: some View {
        if verticalSizeClass == .compact {
            SubscriptionCompactHeightLayout(
                leadingPadding: compactContentLeadingPadding,
                headerBackground: compactHeaderBackground,
                scrollContent: scrollContent
            )
        } else {
            scrollContent
        }
    }

    private var compactHeaderBackground: some View {
        compactHeaderImage
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: compactContentLeadingPadding)
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(TokenColors.Background.page.swiftUI)
            .ignoresSafeArea()
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isRegularHeight {
                    regularHeader
                }

                VStack(alignment: .leading, spacing: 0) {
                    content
                }
                .padding(.horizontal, TokenSpacing._5)
            }
            .padding(.top, compactTopInset)
            .padding(.bottom, TokenSpacing._2)
            .maxWidthForWideScreen()
            .onScrollNearTop(
                coordinateSpaceName: coordinateSpaceName,
                topInset: topInset,
                topOffsetThreshold: topOffsetThreshold
            ) { atTop in
                guard isAtTop != atTop else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    isAtTop = atTop
                }
            }
        }
        .coordinateSpace(name: coordinateSpaceName)
        .onTopInsetChange { topInset = $0 }
    }
}

// MARK: - Layout containers

private struct SubscriptionCompactHeightLayout<
    HeaderBackground: View,
    ScrollContent: View
>: View {
    let leadingPadding: CGFloat
    let headerBackground: HeaderBackground
    let scrollContent: ScrollContent

    var body: some View {
        scrollContent
            .padding(.leading, leadingPadding)
            .background(alignment: .topLeading) {
                headerBackground
            }
    }
}
