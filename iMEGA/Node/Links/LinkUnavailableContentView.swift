import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

/// Revamped unavailable state shared by the file link, the folder link and the album link: a
/// Title 3/Semibold heading over Callout body copy, matching the Empty state component of the link
/// revamp design.
///
/// Only the wording that names the kind of link differs between them, so each hands its own `Copy`
/// to this single layout.
struct LinkUnavailableContentView: View {
    /// The copy that names the kind of link. The reasons that are worded the same for every link --
    /// a taken down link, a suspended or a terminated owner -- are not part of this.
    struct Copy {
        let notAvailableTitle: String
        let noLongerAvailableTitle: String
        let unavailableTitle: String
        let hasExpiredDescription: String
        let genericDescriptionHeader: String
        let genericReasons: [String]
    }

    private enum Constants {
        static let imageWidth: CGFloat = 200
        static let imageHeight: CGFloat = 120
        static let contentMaxWidth: CGFloat = 414
    }

    let reason: LinkUnavailableReason
    let copy: Copy

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
            copy.notAvailableTitle
        case .expired:
            copy.noLongerAvailableTitle
        case .downETD, .userETDSuspension, .copyrightSuspension:
            copy.unavailableTitle
        }
    }

    @ViewBuilder
    private var description: some View {
        switch reason {
        case .generic:
            genericReasons
        case .expired:
            centeredParagraph(Text(copy.hasExpiredDescription))
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
            Text(copy.genericDescriptionHeader)
                .fontWeight(.bold)

            ForEach(copy.genericReasons, id: \.self) { reason in
                Text(bullet(reason))
            }
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

// MARK: - Copy per kind of link

extension LinkUnavailableContentView.Copy {
    static var fileLink: Self {
        .init(
            notAvailableTitle: Strings.Localizable.CloudDrive.FileLink.notAvailable,
            noLongerAvailableTitle: Strings.Localizable.CloudDrive.FileLink.noLongerAvailable,
            unavailableTitle: Strings.Localizable.fileLinkUnavailable,
            hasExpiredDescription: Strings.Localizable.CloudDrive.FileLink.hasExpired,
            genericDescriptionHeader: Strings.Localizable.fileLinkUnavailableText1,
            genericReasons: [
                Strings.Localizable.CloudDrive.FileLink.unavailableReason1,
                Strings.Localizable.CloudDrive.FileLink.unavailableReason2,
                Strings.Localizable.CloudDrive.FileLink.unavailableReason3,
                Strings.Localizable.CloudDrive.FileLink.unavailableReason4
            ]
        )
    }

    static var folderLink: Self {
        .init(
            notAvailableTitle: Strings.Localizable.CloudDrive.FolderLink.notAvailable,
            noLongerAvailableTitle: Strings.Localizable.CloudDrive.FolderLink.noLongerAvailable,
            unavailableTitle: Strings.Localizable.folderLinkUnavailable,
            hasExpiredDescription: Strings.Localizable.CloudDrive.FolderLink.hasExpired,
            genericDescriptionHeader: Strings.Localizable.folderLinkUnavailableText1,
            genericReasons: [
                Strings.Localizable.CloudDrive.FolderLink.unavailableReason1,
                Strings.Localizable.CloudDrive.FolderLink.unavailableReason2,
                Strings.Localizable.CloudDrive.FolderLink.unavailableReason3,
                Strings.Localizable.CloudDrive.FolderLink.unavailableReason4
            ]
        )
    }
}

extension LinkUnavailableContentView.Copy {
    static var albumLink: Self {
        let title = Strings.Localizable.AlbumLink.cannotBeAccessed
        return .init(
            notAvailableTitle: title,
            noLongerAvailableTitle: title,
            unavailableTitle: title,
            hasExpiredDescription: Strings.Localizable.AlbumLink.InvalidAlbum.Alert.message,
            genericDescriptionHeader: Strings.Localizable.fileLinkUnavailableText1,
            genericReasons: [
                Strings.Localizable.AlbumLink.unavailableReason1,
                Strings.Localizable.AlbumLink.unavailableReason2,
                Strings.Localizable.AlbumLink.unavailableReason3
            ]
        )
    }
}

#Preview("File link - generic") {
    LinkUnavailableContentView(reason: .generic, copy: .fileLink)
}

#Preview("Folder link - copyright suspension") {
    LinkUnavailableContentView(reason: .copyrightSuspension, copy: .folderLink)
}

#Preview("Album link") {
    LinkUnavailableContentView(reason: .generic, copy: .albumLink)
}
