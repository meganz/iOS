import MEGADesignToken
import MEGAUIComponent
import SwiftUI

/// Shared chrome for the redesigned subscription pages.
///
/// Owns the navigation header (close / "Maybe later" dismiss button, scroll-driven
/// glass background), the scroll container with its scroll-position tracking, and
/// the stacked / side-by-side layouts. The promo and standard pages supply
/// only what differs: the header image and the scrollable content.
struct SubscriptionBaseView<RegularHeader: View, Content: View>: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var isAtTop = true
    @State private var topInset: CGFloat = 0

    private let compactContentLeadingPadding: CGFloat = 250
    private let padLandscapeContentLeadingPadding: CGFloat = 391
    private let coordinateSpaceName = "SubscriptionRevampScroll"
    private let topOffsetThreshold: CGFloat = 5

    private let leadingHeaderImage: Image
    private let dependency: RevampUpgradePlansDependency
    private let dismiss: (UpgradePlansDismissReason) -> Void
    private let regularHeader: RegularHeader
    private let content: (Bool) -> Content

    init(
        leadingHeaderImage: Image,
        dependency: RevampUpgradePlansDependency,
        dismiss: @escaping (UpgradePlansDismissReason) -> Void,
        @ViewBuilder regularHeader: () -> RegularHeader,
        @ViewBuilder content: @escaping (Bool) -> Content
    ) {
        self.leadingHeaderImage = leadingHeaderImage
        self.dependency = dependency
        self.dismiss = dismiss
        self.regularHeader = regularHeader()
        self.content = content
    }

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { proxy in
                layoutView(isPadLandscape: isPad && proxy.size.width > proxy.size.height)
            }
            .background(TokenColors.Background.page.swiftUI)
            .ignoresSafeArea()

            SubscriptionNavigationHeader(dependency: dependency, isAtTop: isAtTop, dismiss: dismiss)
        }
    }

    // MARK: - Layout

    @ViewBuilder
    private func layoutView(isPadLandscape: Bool) -> some View {
        if verticalSizeClass == .compact || isPadLandscape {
            SubscriptionSideBySideLayout(
                leadingPadding: leadingPadding(isPadLandscape: isPadLandscape),
                headerBackground: headerBackground(isPadLandscape: isPadLandscape),
                scrollContent: scrollContent(isSideBySide: true, isPadLandscape: isPadLandscape)
            )
        } else {
            scrollContent(isSideBySide: false, isPadLandscape: false)
        }
    }

    private func leadingPadding(isPadLandscape: Bool) -> CGFloat {
        isPadLandscape ? padLandscapeContentLeadingPadding : compactContentLeadingPadding
    }

    private func headerBackground(isPadLandscape: Bool) -> some View {
        leadingHeaderImage
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: leadingPadding(isPadLandscape: isPadLandscape))
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(TokenColors.Background.page.swiftUI)
            .ignoresSafeArea()
    }

    // MARK: - Scroll content

    private func scrollContent(isSideBySide: Bool, isPadLandscape: Bool) -> some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                if !isSideBySide {
                    regularHeader
                }

                VStack(alignment: .leading, spacing: 0) {
                    content(isSideBySide)
                        .if(!isPadLandscape) { $0.maxWidthForWideScreen() }
                }
                .padding(.horizontal, TokenSpacing._5)
            }
            .padding(.top, isSideBySide ? TokenSpacing._11 : 0)
            .padding(.bottom, TokenSpacing._2)

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

private struct SubscriptionSideBySideLayout<
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
