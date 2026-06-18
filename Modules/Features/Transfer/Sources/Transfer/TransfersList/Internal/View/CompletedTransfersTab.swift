import MEGAL10n
import Search
import SwiftUI

struct CompletedTransfersTab: View {
    @StateObject private var containerViewModel: SearchResultsContainerViewModel

    init(dependency: TransferTabDependency) {
        _containerViewModel = StateObject(wrappedValue: TransferTabContainerFactory.make(
            dependency: dependency,
            filter: .completed,
            emptyStateTitle: Strings.Localizable.Transfers.EmptyState.noCompletedTransfers
        ))
    }

    var body: some View {
        SearchResultsContainerView(viewModel: containerViewModel)
    }
}
