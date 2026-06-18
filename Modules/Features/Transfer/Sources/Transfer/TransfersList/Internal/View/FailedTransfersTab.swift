import MEGAL10n
import Search
import SwiftUI

struct FailedTransfersTab: View {
    @StateObject private var containerViewModel: SearchResultsContainerViewModel

    init(dependency: TransferTabDependency) {
        _containerViewModel = StateObject(wrappedValue: TransferTabContainerFactory.make(
            dependency: dependency,
            filter: .failed,
            emptyStateTitle: Strings.Localizable.Transfers.EmptyState.noFailedTransfers
        ))
    }

    var body: some View {
        SearchResultsContainerView(viewModel: containerViewModel)
    }
}
