import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

/// Fixed navigation header for the redesigned subscription pages.
///
/// Shows either the leading glass close button or the trailing "Maybe later"
/// button depending on `closeButtonType`; tapping either one dismisses the page.
/// Both buttons stay in the tree and are toggled via opacity to keep the view
/// identity stable. Applies the scroll-driven glass background once the content
/// has scrolled away from the top.
struct SubscriptionNavigationHeader: View {

    /// Which dismissing control the subscription pages' navigation header shows.
    enum CloseButtonType: Equatable {
        /// A leading glass circle with a close (chevron) icon.
        case close
        /// A trailing "Maybe later" text button.
        case maybeLater
    }

    let dependency: RevampUpgradePlansDependency
    let isAtTop: Bool
    let dismiss: (UpgradePlansDismissReason) -> Void

    /// Protection mechanism to avoid the dismiss button from getting spammed in a short time
    /// which cause multiple unexpected triggers of dismiss action.
    @State private var alreadyTapped = false

    private var closeButtonType: CloseButtonType { .init(viewType: dependency.viewType) }

    var body: some View {
        HStack(spacing: 0) {
            closeButton
                .opacity(closeButtonType == .close ? 1 : 0)
                .allowsHitTesting(closeButtonType == .close)
                .accessibilityHidden(closeButtonType != .close)

            Spacer()

            maybeLaterButton
                .opacity(closeButtonType == .maybeLater ? 1 : 0)
                .allowsHitTesting(closeButtonType == .maybeLater)
                .accessibilityHidden(closeButtonType != .maybeLater)
        }
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
        .background {
            if !isAtTop {
                headerBackground
            }
        }
    }

    private var closeButton: some View {
        Button {
            dismissTapped()
        } label: {
            MEGAAssets.Image.monoChevronLeftMediumThinOutline
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .glassCircle()
        .disabled(alreadyTapped)
        .accessibilityLabel(Strings.Localizable.close)
    }

    private var maybeLaterButton: some View {
        Button {
            dismissTapped()
        } label: {
            Text(Strings.Localizable.SubscriptionPurchase.maybeLater)
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .padding(.vertical, TokenSpacing._2)
                .padding(.horizontal, TokenSpacing._4)
                .contentShape(Capsule())
        }
        .glassCapsule()
        .disabled(alreadyTapped)
    }

    private func dismissTapped() {
        guard !alreadyTapped else { return }
        alreadyTapped = true
        dismiss(.maybeLater)
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
}

extension SubscriptionNavigationHeader.CloseButtonType {
    /// Upgrading users get a back button; onboarding users get "Maybe later".
    init(viewType: RevampUpgradePlansViewType) {
        self = viewType.isOnboarding ? .maybeLater : .close
    }
}
