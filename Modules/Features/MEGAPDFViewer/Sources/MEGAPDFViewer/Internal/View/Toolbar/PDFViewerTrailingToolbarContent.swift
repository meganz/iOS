import MEGAAssets
import MEGAL10n
import SwiftUI
import Transfer

struct PDFViewerTrailingToolbarContent: ToolbarContent {
    @State private var viewModel: PopoverPresentingToolbarViewModel
    private let action: PDFViewerTrailingAction
    private let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory
    private let moreAnchorReadyCallbacks: PDFViewerTrailingPopoverDependencies.AnchorReadyCallbacks?
    private let downloadAnchorReadyCallbacks: PDFViewerTrailingPopoverDependencies.AnchorReadyCallbacks?

    init(
        action: PDFViewerTrailingAction,
        transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory,
        moreMenuDependencies: PDFViewerTrailingPopoverDependencies?,
        downloadDependencies: PDFViewerTrailingPopoverDependencies?
    ) {
        self.action = action
        self.transferIndicatorToolbarFactory = transferIndicatorToolbarFactory
        moreAnchorReadyCallbacks = moreMenuDependencies?.anchorReadyCallbacks
        downloadAnchorReadyCallbacks = downloadDependencies?.anchorReadyCallbacks
        let onTapped: PDFViewerTrailingPopoverDependencies.OnTapped?
        switch action {
        case .more: onTapped = moreMenuDependencies?.onTapped
        case .download: onTapped = downloadDependencies?.onTapped
        case .none: onTapped = nil
        }
        _viewModel = State(initialValue: PopoverPresentingToolbarViewModel(onTapped: onTapped))
    }

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        if !viewModel.shouldHideLeadingSideItems {
            transferIndicatorToolbarFactory.toolbarContent(trailingItemCount: action == .none ? 0 : 1)
        }
        if action == .more {
            moreToolbar()
        } else if action == .download {
            downloadToolbar()
        }
    }

    private func moreToolbar() -> some ToolbarContent {
        PopoverPresentingToolbarContent(
            icon: MEGAAssets.UIImage.monoMoreHorizontalMediumThinOutline,
            accessibilityLabel: Strings.Localizable.more,
            onTap: { viewModel.didTap(isPopoverMorphExpected: $0) },
            anchorReadyCallbacks: moreAnchorReadyCallbacks,
            presentationPolicy: .moreMenu
        )
    }

    private func downloadToolbar() -> some ToolbarContent {
        PopoverPresentingToolbarContent(
            icon: MEGAAssets.UIImage.downloadToDisk,
            accessibilityLabel: Strings.Localizable.download,
            onTap: { viewModel.didTap(isPopoverMorphExpected: $0) },
            anchorReadyCallbacks: downloadAnchorReadyCallbacks,
            presentationPolicy: .activity
        )
    }
}
