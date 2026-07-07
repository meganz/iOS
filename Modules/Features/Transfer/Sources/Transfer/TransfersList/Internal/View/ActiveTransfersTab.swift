import MEGAL10n
import Search
import SwiftUI

struct ActiveTransfersTab: View {
    @StateObject private var containerViewModel: SearchResultsContainerViewModel
    private let isAllPaused: Bool
    private let isTransferOverquota: Bool

    init(dependency: TransferTabDependency, isAllPaused: Bool, isTransferOverquota: Bool) {
        _containerViewModel = StateObject(wrappedValue: TransferTabContainerFactory.make(
            dependency: dependency,
            filter: .active,
            emptyStateTitle: Strings.Localizable.Transfers.EmptyState.noActiveTransfers
        ))
        self.isAllPaused = isAllPaused
        self.isTransferOverquota = isTransferOverquota
    }

    var body: some View {
        SearchResultsContainerView(viewModel: containerViewModel)
            .environment(\.isAllTransfersPaused, isAllPaused)
            .environment(\.isTransferOverquota, isTransferOverquota)
    }
}
