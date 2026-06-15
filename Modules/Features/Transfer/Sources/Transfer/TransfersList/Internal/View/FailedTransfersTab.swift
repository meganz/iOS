import MEGAL10n
import Search
import SwiftUI

/// The Failed transfers tab. Builds and owns its `TransferTabViewModel` as a
/// `@StateObject` from the injected dependency, so the Search wiring is created and
/// torn down with the tab, and streams its live item count up through the
/// `presence` binding (state down, actions up).
struct FailedTransfersTab: View {
    @StateObject private var viewModel: TransferTabViewModel

    init(
        dependency: TransferTabDependency,
        presence: Binding<Int>
    ) {
        _viewModel = StateObject(wrappedValue: TransferTabViewModel(
            dependency: dependency,
            filter: .failed,
            emptyStateTitle: Strings.Localizable.Transfers.EmptyState.noFailedTransfers,
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
