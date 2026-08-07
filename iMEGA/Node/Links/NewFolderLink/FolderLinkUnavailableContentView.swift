import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

/// Revamped folder link unavailable state: a Title 3/Semibold heading over Callout body copy,
/// matching the Empty state component of the link revamp design.
struct FolderLinkUnavailableContentView: View {
    private enum Constants {
        static let imageWidth: CGFloat = 200
        static let imageHeight: CGFloat = 120
        static let contentMaxWidth: CGFloat = 414
    }

    let reason: LinkUnavailableReason

    var body: some View {
        VStack(spacing: TokenSpacing._7) {
            Image(uiImage: MEGAAssets.UIImage.invalidLink)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.imageWidth, height: Constants.imageHeight)

            VStack(spacing: TokenSpacing._5) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                description
                    .font(.callout)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
        }
        .padding(.horizontal, TokenSpacing._9)
        .frame(maxWidth: Constants.contentMaxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TokenColors.Background.page.swiftUI)
    }

    private var title: String {
        switch reason {
        case .generic:
            Strings.Localizable.CloudDrive.FolderLink.notAvailable
        case .expired:
            Strings.Localizable.CloudDrive.FolderLink.noLongerAvailable
        case .downETD, .userETDSuspension, .copyrightSuspension:
            Strings.Localizable.folderLinkUnavailable
        }
    }

    @ViewBuilder
    private var description: some View {
        switch reason {
        case .generic:
            genericReasons
        case .expired:
            centeredParagraph(Text(Strings.Localizable.CloudDrive.FolderLink.hasExpired))
        case .downETD:
            centeredParagraph(Text(Strings.Localizable.takenDownDueToSevereViolationOfOurTermsOfService))
        case .userETDSuspension:
            termsParagraph(Strings.Localizable.thisLinkIsUnavailableAsTheUserSAccountHasBeenClosedForGrossViolationOfMEGASATermsOfServiceA)
        case .copyrightSuspension:
            termsParagraph(Strings.Localizable.theAccountThatCreatedThisLinkHasBeenTerminatedDueToMultipleViolationsOfOurATermsOfServiceA)
        }
    }

    private var genericReasons: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Strings.Localizable.folderLinkUnavailableText1)
                .fontWeight(.bold)
            Text(bullet(Strings.Localizable.CloudDrive.FolderLink.unavailableReason1))
            Text(bullet(Strings.Localizable.CloudDrive.FolderLink.unavailableReason2))
            Text(bullet(Strings.Localizable.CloudDrive.FolderLink.unavailableReason3))
            Text(bullet(Strings.Localizable.CloudDrive.FolderLink.unavailableReason4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func centeredParagraph(_ text: Text) -> some View {
        text
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    /// Renders the webclient `[A]…[/A]` marker as a tappable Terms of Service link.
    private func termsParagraph(_ text: String) -> some View {
        // `Button.brand` matches the legacy `UIColor.mnz_red()` this screen has always used.
        TaggableText(text, underline: false, tappable: true, linkColor: TokenColors.Button.brand)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            // Needed for the tappable link to work, as in NewChatEmptyCenterView.
            .textSelection(.enabled)
            // SwiftUI paints runs carrying a `.link` attribute with the tint, not with the run's
            // own foreground colour, so the tint has to match `linkColor` above.
            .tint(TokenColors.Button.brand.swiftUI)
            .environment(\.openURL, OpenURLAction { _ in
                guard let termsURL else { return .discarded }
                return .systemAction(termsURL)
            })
    }

    private var termsURL: URL? {
        URL(string: "https://\(DIContainer.domainName)/terms")
    }

    private func bullet(_ reason: String) -> String {
        "• \(reason)"
    }
}

#Preview("Generic") {
    FolderLinkUnavailableContentView(reason: .generic)
}

#Preview("Copyright suspension") {
    FolderLinkUnavailableContentView(reason: .copyrightSuspension)
}
