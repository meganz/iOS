import MEGAL10n
import Search
import SwiftUI

struct ActiveTransfersTab: View {
    @StateObject private var containerViewModel: SearchResultsContainerViewModel
    private let isAllPaused: Bool

    init(dependency: TransferTabDependency, isAllPaused: Bool) {
        _containerViewModel = StateObject(wrappedValue: TransferTabContainerFactory.make(
            dependency: dependency,
            filter: .active,
            emptyStateTitle: Strings.Localizable.Transfers.EmptyState.noActiveTransfers
        ))
        self.isAllPaused = isAllPaused
    }

    var body: some View {
        SearchResultsContainerView(viewModel: containerViewModel)
            .environment(\.isAllTransfersPaused, isAllPaused)
    }
}
