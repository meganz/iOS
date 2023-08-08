import SwiftUI

struct BackupListView: View {
    @ObservedObject var viewModel: BackupListViewModel
    
    var body: some View {
        SearchableView(
            wrappedView: BackupListContentView(viewModel: viewModel),
            searchText: $viewModel.searchText,
            isEditing: $viewModel.isSearchActive,
            isFilteredListEmpty: viewModel.isFilteredBackupsEmpty,
            searchAssets: viewModel.searchAssets,
            emptyStateAssets: viewModel.emptyStateAssets
        )
    }
}

struct BackupListContentView: View {
    @ObservedObject var viewModel: BackupListViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.displayedBackups) { backupViewModel in
                DeviceCenterItemView(viewModel: backupViewModel)
            }
        }
        .listStyle(.plain)
    }
}
