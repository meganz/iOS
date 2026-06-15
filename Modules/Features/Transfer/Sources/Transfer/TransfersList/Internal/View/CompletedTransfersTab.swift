import MEGAL10n
import Search
import SwiftUI

/// The Completed transfers tab. Builds and owns its `TransferTabViewModel` as a
/// `@StateObject` from the injected dependency, so the Search wiring is created and
/// torn down with the tab, and streams its live item count up through the
/// `presence` binding (state down, actions up).
struct CompletedTransfersTab: View {
    @StateObject private var viewModel: TransferTabViewModel

    init(
        dependency: TransferTabDependency,
        presence: Binding<Int>
    ) {
        _viewModel = StateObject(wrappedValue: TransferTabViewModel(
            dependency: dependency,
            filter: .completed,
            emptyStateTitle: Strings.Localizable.Transfers.EmptyState.noCompletedTransfers,
            onItemCountChange: { presence.wrappedValue = $0 }
        ))
    }

    var body: some View {
        SearchResultsContainerView(viewModel: viewModel.containerViewModel)
            .task {
                await viewModel.observeItemCount()
            }
    }
}
