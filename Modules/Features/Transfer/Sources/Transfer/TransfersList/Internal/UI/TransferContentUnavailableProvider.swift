import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI

struct TransferContentUnavailableProvider: ContentUnavailableViewModelProviding {
    /// Tab-specific empty-state title (e.g. "No active transfers"). Each tab's
    /// container owns its own provider, so the empty message matches the tab rather
    /// than a generic "No transfers".
    let title: String

    func emptyViewModel(
        query: SearchQuery,
        appliedChips: [SearchChipEntity],
        config: SearchConfig
    ) -> ContentUnavailableViewModel {
        .transfersEmptyState(title: title)
    }
}

extension ContentUnavailableViewModel {
    /// Shared empty-state model for the Transfers screen. Used by each tab's
    /// content-unavailable provider and by the tabs-hidden "No transfers" overlay, so
    /// every empty state renders through the same `RevampedContentUnavailableView`.
    static func transfersEmptyState(title: String) -> ContentUnavailableViewModel {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.newTransfersEmptyState,
            title: title,
            font: .body,
            titleTextColor: TokenColors.Text.secondary.swiftUI
        )
    }
}
