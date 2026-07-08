import MEGASwiftUI
import SwiftUI

struct TransferTabListView: View {
    @StateObject private var viewModel: TransferTabListViewModel
    private let emptyStateTitle: String

    init(tab: TransfersTab, dependency: TransferTabDependency) {
        _viewModel = StateObject(wrappedValue: TransferTabListViewModel(tab: tab, dependency: dependency))
        emptyStateTitle = tab.emptyStateTitle
    }

    var body: some View {
        content
            .task { await viewModel.monitorTransferEvents() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.rows.isEmpty {
            if viewModel.isLoaded {
                RevampedContentUnavailableView(
                    viewModel: .transfersEmptyState(title: emptyStateTitle)
                )
                .pageBackground()
            } else {
                Color.clear
            }
        } else {
            listContent
        }
    }

    @ViewBuilder
    private var listContent: some View {
        let list = List {
            ForEach(viewModel.rows) { row in
                TransferResultRowView(viewModel: row)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .environment(\.defaultMinListRowHeight, 0)
        .listStyle(.plain)

        if #available(iOS 17.0, *) {
            list
                .contentMargins(.top, 0, for: .scrollContent)
        } else {
            list
        }
    }
}
