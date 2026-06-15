import MEGAL10n
import Search
import SwiftUI

/// The Active transfers tab. Builds and owns its `TransferTabViewModel` as a
/// `@StateObject` from the injected dependency, so the Search wiring is created and
/// torn down with the tab. Applies the pause-all environment its rows read, and
/// streams its live item count up through the `presence` binding (state down,
/// actions up).
struct ActiveTransfersTab: View {
    @StateObject private var viewModel: TransferTabViewModel
    private let isAllPaused: Bool

    init(
        dependency: TransferTabDependency,
        isAllPaused: Bool,
        presence: Binding<Int>
    ) {
        _viewModel = StateObject(wrappedValue: TransferTabViewModel(
            dependency: dependency,
            filter: .active,
            emptyStateTitle: Strings.Localizable.Transfers.EmptyState.noActiveTransfers,
            onItemCountChange: { presence.wrappedValue = $0 }
        ))
        self.isAllPaused = isAllPaused
    }

    var body: some View {
        SearchResultsContainerView(viewModel: viewModel.containerViewModel)
            .environment(\.isAllTransfersPaused, isAllPaused)
            .task {
                await viewModel.observeItemCount()
            }
    }
}
