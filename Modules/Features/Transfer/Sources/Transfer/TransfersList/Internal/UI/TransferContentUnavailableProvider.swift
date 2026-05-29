import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI

struct TransferContentUnavailableProvider: ContentUnavailableViewModelProviding {
    func emptyViewModel(
        query: SearchQuery,
        appliedChips: [SearchChipEntity],
        config: SearchConfig
    ) -> ContentUnavailableViewModel {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.newTransfersEmptyState,
            title: Strings.Localizable.Transfers.EmptyState.noTransfers,
            font: .body,
            titleTextColor: TokenColors.Text.secondary.swiftUI
        )
    }
}
