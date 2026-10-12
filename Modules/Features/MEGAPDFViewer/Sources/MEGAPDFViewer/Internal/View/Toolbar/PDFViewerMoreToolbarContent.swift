import MEGAAssets
import MEGAL10n
import SwiftUI
import Transfer

struct PDFViewerMoreToolbarContent: ToolbarContent {
    @State private var viewModel: PDFViewerMoreButtonViewModel

    private let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory
    private let fullScreenIPadMorePopoverAnchorReadyCallbacks: PDFViewerMoreMenuDependencies.FullScreenIPadMorePopoverAnchorReadyCallbacks?
    private var isDocumentLoadFailed = false

    init(
        transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory,
        moreMenuDependencies: PDFViewerMoreMenuDependencies?
    ) {
        self.transferIndicatorToolbarFactory = transferIndicatorToolbarFactory
        _viewModel = State(
            initialValue: PDFViewerMoreButtonViewModel(onMoreTapped: moreMenuDependencies?.onMoreTapped)
        )
        fullScreenIPadMorePopoverAnchorReadyCallbacks = moreMenuDependencies?.fullScreenIPadMorePopoverAnchorReadyCallbacks
    }

    func documentLoadFailed(_ isDocumentLoadFailed: Bool) -> Self {
        var content = self
        content.isDocumentLoadFailed = isDocumentLoadFailed
        return content
    }

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        // Trailing items lay out in declaration order, so More stays at
        // the trailing edge after the indicator.
        if !viewModel.isTransferIndicatorHiddenForiPadLiquidGlassMorePopoverAnimation {
            transferIndicatorToolbarFactory.toolbarContent(trailingItemCount: 1)
        }

        if viewModel.showsMoreButton(isDocumentLoadFailed: isDocumentLoadFailed) {
            ToolbarItem(placement: .topBarTrailing) {
                if #available(iOS 26.0, *),
                   UIDevice.current.userInterfaceIdiom == .pad,
                   let fullScreenIPadMorePopoverAnchorReadyCallbacks {
                    PDFViewerMoreToolbarItemView(
                        onTap: viewModel.didTapMoreBarItem(isInFullScreenWindow:),
                        onReadyForPopoverMenuPresentation: fullScreenIPadMorePopoverAnchorReadyCallbacks
                            .onMoreBarItemReadyForMenuPresentation
                    )
                    .frame(width: 36, height: 44)
                } else {
                    Button {
                        viewModel.didTapMore()
                    } label: {
                        MEGAAssets.Image.monoMoreHorizontalMediumThinOutline
                    }
                    .background {
                        if let fullScreenIPadMorePopoverAnchorReadyCallbacks {
                            PDFViewerMorePopoverAnchorView(
                                onReady: fullScreenIPadMorePopoverAnchorReadyCallbacks
                                    .onMoreAnchorReadyForMenuPresentation
                            )
                        }
                    }
                    .accessibilityLabel(Strings.Localizable.more)
                }
            }
        }
    }
}
