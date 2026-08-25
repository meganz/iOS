import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI
import Transfer

/// Nested in the view until it took a generic parameter, which stored type properties cannot live in.
private enum Constants {
    static let nameLineLimit = 3
    /// What the design leaves between the ad and the actions anchored below it.
    static let adsBottomSpacing = TokenSpacing._7
    /// The padding the design draws around `Open`, which does not sit on the spacing token scale.
    static let openButtonHorizontalPadding: CGFloat = 14
    static let openButtonVerticalPadding: CGFloat = 7
    /// The more button is the only item of the trailing side, which is what keeps the transfer
    /// indicator on that side rather than sending it over to the close button.
    static let trailingItemCount = 1
}

/// The file link screen once the link has resolved: the preview area above the file's name and
/// details, either of which opens the file, and below those the place the design gives the ad.
struct FileLinkContentView<Ads>: View where Ads: View {
    @StateObject private var viewModel: FileLinkContentViewModel
    @ViewBuilder let adsContent: () -> Ads

    private let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory

    @State private var isShowingMoreOptions = false
    /// Followed by `FileLinkView`, which is where the screen learns about the connection.
    @Environment(\.networkConnected) private var networkConnected

    init(
        node: NodeEntity,
        previewLoader: some ThumbnailLoaderProtocol,
        fileNodeOpener: some FileLinkNodeOpenerProtocol,
        actionHandler: some FileLinkActionHandlerProtocol,
        shareLink: String,
        transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory,
        @ViewBuilder adsContent: @escaping () -> Ads
    ) {
        self.transferIndicatorToolbarFactory = transferIndicatorToolbarFactory
        self.adsContent = adsContent
        _viewModel = StateObject(
            wrappedValue: FileLinkContentViewModel(
                node: node,
                thumbnailLoader: previewLoader,
                fileNodeOpener: fileNodeOpener,
                actionHandler: actionHandler,
                shareLink: shareLink
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            previewButton

            // Pinned to the height its text needs, so that when the screen is too short for both --
            // landscape, or large accessibility text -- the preview area above gives up the space
            // instead of the name being truncated.
            details
                .fixedSize(horizontal: false, vertical: true)

            // The design hands the slack between the file's details and the ad, which sits at the
            // bottom of the screen rather than under the details.
            Spacer(minLength: 0)

            // The ad takes no room until one has loaded, so the screen looks the same as it did
            // before it arrives, and the same as it does for accounts that see no ads at all.
            adsContent()
                .padding(.bottom, Constants.adsBottomSpacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(TokenColors.Background.page.swiftUI)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            anchoredButtons
        }
        // Contributed from here rather than alongside the close button, so that the actions only appear
        // once there is a file to act on: the screen is presented before the link has resolved. The
        // transfer indicator comes with them, since this screen is where a transfer is started from.
        .toolbar {
            // Trailing items lay out in the order they are declared, which keeps the more button at the
            // edge the design puts it on and the indicator, when there is one, to the left of it.
            transferIndicatorToolbarFactory.toolbarContent(trailingItemCount: Constants.trailingItemCount)

            ToolbarItem(placement: .topBarTrailing) {
                moreOptionsButton
            }
        }
        .sheet(isPresented: $isShowingMoreOptions) {
            moreOptionsSheet
        }
        .task {
            await viewModel.loadPreview()
        }
    }

    /// The whole preview area opens the file, the play button drawn on a video included: nothing plays
    /// in place. `Open` below does the same thing and is the one VoiceOver reads, so this is kept out
    /// of its way rather than offering the same action twice.
    private var previewButton: some View {
        Button(action: openFile) {
            FileLinkPreviewView(preview: viewModel.preview)
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
    }

    private var details: some View {
        HStack(spacing: TokenSpacing._4) {
            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                Text(viewModel.name)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .lineLimit(Constants.nameLineLimit)

                Text(viewModel.details)
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            openButton
        }
        .padding(.leading, TokenSpacing._4)
        .padding(.trailing, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
    }

    private var openButton: some View {
        Button(action: openFile) {
            Text(Strings.Localizable.openButton)
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .padding(.horizontal, Constants.openButtonHorizontalPadding)
                .padding(.vertical, Constants.openButtonVerticalPadding)
                .background(TokenColors.Button.secondary.swiftUI)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var moreOptionsButton: some View {
        Button {
            isShowingMoreOptions = true
        } label: {
            moreOptionsIcon
        }
        .accessibilityLabel(Strings.Localizable.more)
    }

    /// From iOS 26 the toolbar puts the icon in a glass capsule of its own, so the padding that gives it a
    /// tappable area on earlier versions would double up. Same treatment as the close button.
    @ViewBuilder
    private var moreOptionsIcon: some View {
        let icon = MEGAAssets.Image.moreHorizontal
            .frame(width: TokenSpacing._7, height: TokenSpacing._7)
            .foregroundStyle(TokenColors.Icon.primary.swiftUI)

        if #available(iOS 26.0, *) {
            icon
        } else {
            icon.padding(10)
        }
    }

    private var moreOptionsSheet: some View {
        FileLinkMoreOptionsSheet(
            title: viewModel.name,
            subtitle: viewModel.details,
            preview: viewModel.preview,
            link: viewModel.shareLink,
            options: viewModel.moreOptions,
            selectionHandler: perform
        )
    }

    /// Both buttons need the network, so losing it disables them outright rather than letting the tap
    /// through to the no connection HUD. Same treatment as the folder link.
    private var anchoredButtons: some View {
        FileLinkAnchoredButtons(
            isDisabled: !networkConnected,
            onDownload: { perform(.download) },
            onSaveToMEGA: { perform(.saveToMEGA) }
        )
    }

    /// The task belongs to the view rather than to the view model, which only exposes the async work.
    private func openFile() {
        Task {
            await viewModel.openFile()
        }
    }

    private func perform(_ option: FileLinkMoreOption) {
        Task {
            await viewModel.handle(moreOption: option)
        }
    }
}
