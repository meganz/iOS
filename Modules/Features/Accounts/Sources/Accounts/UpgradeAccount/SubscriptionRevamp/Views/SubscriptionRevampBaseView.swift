import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

/// Shared chrome for the redesigned subscription pages.
///
/// Owns the navigation header (fixed glass close button, scroll-driven glass
/// background), the scroll container with its scroll-position tracking, and the
/// regular/compact size-class layouts. The promo and standard pages supply only
/// what differs: the header image and the scrollable content.
struct SubscriptionRevampBaseView<RegularHeader: View, Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var isAtTop = true
    @State private var topInset: CGFloat = 0

    private let compactContentLeadingPadding: CGFloat = 250
    private let coordinateSpaceName = "SubscriptionRevampScroll"
    private let topOffsetThreshold: CGFloat = 5

    private let compactHeaderImage: Image
    private let regularHeader: RegularHeader
    private let content: Content

    init(
        compactHeaderImage: Image,
        @ViewBuilder regularHeader: () -> RegularHeader,
        @ViewBuilder content: () -> Content
    ) {
        self.compactHeaderImage = compactHeaderImage
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

            navigationHeader
        }
    }

    // MARK: - Layout

    @ViewBuilder
    private var layoutView: some View {
        if verticalSizeClass == .compact {
            SubscriptionRevampCompactHeightLayout(
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

    // MARK: - Navigation header

    private var navigationHeader: some View {
        HStack {
            headerButton

            Spacer()
        }
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
        .background {
            if !isAtTop {
                headerBackground
            }
        }
    }

    @ViewBuilder
    private var headerBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: Rectangle())
                .ignoresSafeArea(edges: [.top, .leading, .trailing])
        } else {
            VStack(spacing: 0) {
                Color.clear
                    .background(.regularMaterial)
                Divider()
            }
            .ignoresSafeArea(edges: [.top, .leading, .trailing])
        }
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

// MARK: - Layout containers

private struct SubscriptionRevampCompactHeightLayout<
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
