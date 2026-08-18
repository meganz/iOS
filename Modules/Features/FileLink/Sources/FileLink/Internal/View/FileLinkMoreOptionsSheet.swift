import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

/// The rows the navigation bar more button of the file link screen offers, in the order the design lists
/// them.
///
/// The design also lists a Report row. It has no flow, string or tracking in the app yet, so it is left
/// out until it gets a ticket of its own -- the same as on the revamped folder link.
package enum FileLinkMoreOption: Identifiable, Hashable, Sendable {
    case saveToMEGA
    case saveToPhotos
    case download
    case copyToOffline
    case shareLink
    case sendToChat

    package var id: Self { self }

    var title: String {
        switch self {
        case .saveToMEGA:
            Strings.Localizable.Link.Button.saveToMega
        case .saveToPhotos:
            Strings.Localizable.saveToPhotos
        case .download:
            Strings.Localizable.download
        case .copyToOffline:
            Strings.Localizable.Link.Button.copyToOffline
        case .shareLink:
            Strings.Localizable.General.MenuAction.ShareLink.title(1)
        case .sendToChat:
            Strings.Localizable.General.sendToChat
        }
    }

    /// Save to Photos lands the file in the Photos library and Download on the device itself, neither of
    /// which is the Offline section that Copy to Offline fills, so the cloud-download icon is left to
    /// that row alone.
    var icon: Image {
        switch self {
        case .saveToMEGA:
            MEGAAssets.Image.uploadToCloud
        case .saveToPhotos:
            MEGAAssets.Image.photosApp
        case .download:
            MEGAAssets.Image.downloadToDisk
        case .copyToOffline:
            MEGAAssets.Image.cloudDownload
        case .shareLink:
            MEGAAssets.Image.link01
        case .sendToChat:
            MEGAAssets.Image.messagePlus
        }
    }

    func action(shareLink: String) -> FileLinkAction? {
        switch self {
        case .saveToMEGA: .saveToMEGA
        case .saveToPhotos: .saveToPhotos
        case .download: .download
        case .copyToOffline: .copyToOffline
        case .sendToChat: .sendToChat(shareLink)
        case .shareLink: nil
        }
    }
}

/// The bottom sheet behind the navigation bar more button of the file link screen. It replaces the menu
/// that used to expand in place, so the file's actions slide up from the bottom like the ones of a row's
/// more button.
struct FileLinkMoreOptionsSheet: View {
    let title: String
    let subtitle: String
    let preview: FileLinkContentViewModel.Preview
    let link: String
    let options: [FileLinkMoreOption]
    let selectionHandler: (FileLinkMoreOption) -> Void

    @Environment(\.dismiss) private var dismiss

    /// The picked row only runs once the sheet is gone: its action presents a view controller of its
    /// own, which UIKit refuses to do while the sheet it was picked in is still up.
    @State private var pendingOption: FileLinkMoreOption?
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                Divider()
                    .overlay(TokenColors.Border.subtle.swiftUI)

                ForEach(renderedOptions) { option in
                    row(for: option)
                }
            }
            // The drag indicator is drawn by UIKit over the top of the sheet, so the content starts
            // below it rather than underneath.
            .padding(.top, Constants.dragIndicatorChrome)
            .padding(.bottom, TokenSpacing._7)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: ContentHeightPreferenceKey.self, value: proxy.size.height)
                }
            )
        }
        // Only the rows that do not fit scroll, which keeps a short sheet from bouncing.
        .scrollBounceBehavior(.basedOnSize)
        .onPreferenceChange(ContentHeightPreferenceKey.self) { contentHeight = $0 }
        // A detent tailored to the content keeps the sheet wrapped around its rows instead of letting a
        // swipe expand it. It is measured rather than computed so it follows Dynamic Type, and the
        // bottom safe area is left out: the sheet keeps the home indicator strip clear on its own.
        .presentationDetents([.height(resolvedContentHeight)])
        .background(TokenColors.Background.surface1.swiftUI.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(TokenRadius.large)
        .onDisappear {
            guard let pendingOption else { return }
            selectionHandler(pendingOption)
        }
    }

    private var header: some View {
        HStack(spacing: TokenSpacing._3) {
            headerIcon

            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, TokenSpacing._5)
        .frame(height: Constants.rowHeight)
    }

    /// The same picture the preview area above shows, cropped into the square the design draws next to
    /// the name: the loaded image for media, the file type icon for everything else.
    @ViewBuilder
    private var headerIcon: some View {
        switch preview {
        case let .media(image, _):
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: Constants.headerIconSize, height: Constants.headerIconSize)
                .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
        case let .fileTypeIcon(image):
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.headerIconSize, height: Constants.headerIconSize)
        }
    }

    /// Share link needs a URL the system share sheet can take, so a link that does not parse into one
    /// drops the row -- and drops out of the height estimate with it, which reads `renderedOptions` too.
    private var renderedOptions: [FileLinkMoreOption] {
        guard shareURL == nil else { return options }
        return options.filter { $0 != .shareLink }
    }

    private var shareURL: URL? {
        URL(string: link)
    }

    @ViewBuilder
    private func row(for option: FileLinkMoreOption) -> some View {
        switch option {
        case .shareLink:
            // Sharing stays with ShareLink: it hands the system share sheet the anchoring it needs on
            // iPad, which a UIActivityViewController presented by hand does not get for free. It also
            // presents that sheet itself, in SwiftUI, so unlike the rows below it is not blocked by this
            // sheet still being up and has no reason to dismiss it first.
            if let shareURL {
                ShareLink(item: shareURL) {
                    label(for: option)
                }
            }
        default:
            Button {
                pendingOption = option
                dismiss()
            } label: {
                label(for: option)
            }
        }
    }

    private func label(for option: FileLinkMoreOption) -> some View {
        HStack(spacing: TokenSpacing._3) {
            option.icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .frame(minWidth: Constants.iconContainerSize, minHeight: Constants.iconContainerSize)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)

            Text(option.title)
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, TokenSpacing._5)
        .frame(minHeight: Constants.rowHeight)
        .contentShape(.rect)
    }

    /// The measured height, or the height the rows take at the default text size until the first
    /// measurement lands -- a sheet that opens at zero height would animate itself into place.
    private var resolvedContentHeight: CGFloat {
        contentHeight > 0 ? contentHeight : estimatedContentHeight
    }

    private var estimatedContentHeight: CGFloat {
        Constants.dragIndicatorChrome
        + Constants.rowHeight
        + Constants.dividerHeight
        + CGFloat(renderedOptions.count) * Constants.rowHeight
        + TokenSpacing._7
    }

    private enum Constants {
        static let rowHeight: CGFloat = 58
        static let iconSize: CGFloat = 24
        static let iconContainerSize: CGFloat = 32
        static let headerIconSize: CGFloat = 32
        static let dividerHeight: CGFloat = 1
        /// Visible chrome for `.presentationDragIndicator(.visible)` -- rendered by UIKit.
        static let dragIndicatorChrome: CGFloat = 21
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview("Image") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            FileLinkMoreOptionsSheet(
                title: "elcapitan.jpeg",
                subtitle: "10 MB",
                preview: .media(image: MEGAAssets.Image.filetypeGeneric, videoDuration: nil),
                link: "https://mega.nz/file/abcdefgh",
                options: [.saveToMEGA, .saveToPhotos, .download, .copyToOffline, .shareLink, .sendToChat],
                selectionHandler: { _ in }
            )
        }
}

#Preview("Document") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            FileLinkMoreOptionsSheet(
                title: "Marketing Plan 2026.pdf",
                subtitle: "10 MB",
                preview: .fileTypeIcon(MEGAAssets.Image.image(forFileName: "Marketing Plan 2026.pdf")),
                link: "https://mega.nz/file/abcdefgh",
                options: [.saveToMEGA, .download, .copyToOffline, .shareLink, .sendToChat],
                selectionHandler: { _ in }
            )
        }
}
